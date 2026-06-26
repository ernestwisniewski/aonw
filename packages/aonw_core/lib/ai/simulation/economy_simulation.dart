import 'package:aonw_core/ai.dart';
import 'package:aonw_core/ai/simulation/economy_simulation_command_staleness.dart';
import 'package:aonw_core/ai/simulation/economy_simulation_command_stats.dart';
import 'package:aonw_core/ai/simulation/economy_simulation_models.dart';
import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/telemetry.dart';
import 'package:aonw_core/game/domain/turn.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

export 'package:aonw_core/ai/simulation/economy_simulation_models.dart';

part 'economy_simulation_command_applier.dart';
part 'economy_simulation_hostility_memory.dart';
part 'economy_simulation_setup.dart';
part 'economy_simulation_strategy_selector.dart';
part 'economy_simulation_telemetry.dart';
part 'economy_simulation_turn_row_factory.dart';

const _militaryAssessment = AiMilitaryAssessment();

abstract final class EconomySimulation {
  static const adaptiveLateGameTurnThreshold = 55;
  static const adaptiveLateGameUnitThreshold = 36;
  static const adaptiveLateGameCityThreshold = 8;

  static EconomySimulationResult run({
    EconomySimulationConfig config = const EconomySimulationConfig(),
  }) {
    final player = config.player;
    final players = [player, ...config.opponents];
    final playerIds = [for (final player in players) player.id];
    final mapData = config.mapData ?? _EconomySimulationSetup.simulationMap();
    final mapDefinition = _EconomySimulationSetup.mapDefinitionFrom(mapData);
    var state = _EconomySimulationSetup.initialState(
      player: player,
      opponents: config.opponents,
      mapData: mapData,
    );
    const commandApplier = _EconomySimulationCommandApplier();
    const rowFactory = _EconomySimulationTurnRowFactory();
    final hostilityMemory = _EconomySimulationHostilityMemory();
    final rows = <EconomySimulationTurnRow>[];
    final rowsByPlayerId = {
      for (final simulationPlayer in players)
        simulationPlayer.id: <EconomySimulationTurnRow>[],
    };
    final appliedCommands = <GameCommand>[];
    final appliedCommandRecords = <EconomySimulationAppliedCommand>[];
    final rejectedCommands = <GameCommand>[];
    final rejectedCommandRecords = <EconomySimulationRejectedCommand>[];
    final aiTurnRuntimes = <EconomySimulationAiTurnRuntime>[];
    final strategicPlansByPlayerId = <String, StrategicPlan>{};
    final telemetrySamples = <BalanceTelemetryTurnSample>[
      BalanceTelemetryTurnSample(turn: 0, state: state),
    ];

    for (var turn = 1; turn <= config.turns; turn++) {
      state = PersistentTurnMovementProcessor.resetForPlayers(
        state: state,
        playerIds: playerIds,
        mapData: mapData,
      ).state;

      final commandStatsByPlayerId = {
        for (final player in players)
          player.id: EconomySimulationCommandStats(),
      };
      final turnEvents = <GameEvent>[];
      var commandTick = 0;

      for (final actingPlayer in players) {
        state = state.copyWith(
          fogOfWar: const FogOfWarService().recompute(
            current: state.fogOfWar,
            mapData: mapData,
            playerIds: playerIds,
            units: state.units,
            cities: state.cities,
          ),
        );
        final commandStats = commandStatsByPlayerId[actingPlayer.id]!;
        final view = GameView.fromPersistentState(
          state,
          forPlayerId: actingPlayer.id,
          turn: turn,
          mapData: mapData,
          ruleset: config.ruleset,
          recentHostilePlayerIds: hostilityMemory.recentFor(
            playerId: actingPlayer.id,
            turn: turn,
          ),
          ignoreFogOfWar: true,
        );
        final ai =
            actingPlayer.ai ??
            const AiPlayer(strategyId: AiStrategyId.basic, seed: 1001);
        const civRegistry = CivilizationProfileRegistry();
        final civProfile = civRegistry.profileFor(actingPlayer.country);
        var context = AiContext(
          ruleset: config.ruleset,
          mapData: mapData,
          turn: turn,
          rng: AiRng.fromTurn(
            turn: turn,
            playerId: actingPlayer.id,
            baseSeed: ai.seed,
          ),
          persona: ai.personaForProfile(civProfile),
          difficulty: ai.difficulty,
          civProfile: civProfile,
        );
        final strategicPlan = const StrategicPlanner().build(
          view: view,
          context: context,
          previousPlan: strategicPlansByPlayerId[actingPlayer.id],
        );
        strategicPlansByPlayerId[actingPlayer.id] = strategicPlan;
        context = context.copyWith(strategicPlan: strategicPlan);
        final strategyChoice = _EconomySimulationStrategySelector.forPlayer(
          player: ai,
          config: config,
          turn: turn,
          state: state,
          players: players,
        );
        final planningStopwatch = Stopwatch()..start();
        final plan = strategyChoice.strategy.plan(view, context);
        planningStopwatch.stop();
        aiTurnRuntimes.add(
          EconomySimulationAiTurnRuntime(
            turn: turn,
            playerId: actingPlayer.id,
            strategyId: ai.strategyId,
            profileMode: config.mctsProfileMode,
            runtimeProfile: strategyChoice.runtimeProfile,
            adaptiveLateGame: strategyChoice.adaptiveLateGame,
            planningDuration: planningStopwatch.elapsed,
            plannedCommands: plan.commands.length,
            totalUnitCount: state.units.length,
            totalCityCount: state.cities.length,
            debugNotes: List.unmodifiable(plan.debug?.notes ?? const []),
            debugMetrics: Map.unmodifiable(plan.debug?.metrics ?? const {}),
          ),
        );

        for (final command in plan.commands) {
          if (isStaleEconomySimulationCommand(
            command: command,
            state: state,
            actorPlayerId: actingPlayer.id,
            ruleset: config.ruleset,
            mapDefinition: mapDefinition,
          )) {
            commandTick += 1;
            continue;
          }
          final applied = commandApplier.apply(
            turn: turn,
            tick: commandTick,
            state: state,
            command: command,
            actorPlayerId: actingPlayer.id,
            mapDefinition: mapDefinition,
            ruleset: config.ruleset,
          );
          commandTick += 1;
          if (applied.accepted) {
            state = applied.state;
            turnEvents.addAll(applied.events);
            hostilityMemory.record(events: applied.events, turn: turn);
            appliedCommands.add(command);
            appliedCommandRecords.add(
              EconomySimulationAppliedCommand(
                turn: turn,
                tick: commandTick - 1,
                playerId: actingPlayer.id,
                command: command,
              ),
            );
            commandStats.addApplied(command);
          } else {
            rejectedCommands.add(command);
            rejectedCommandRecords.add(
              EconomySimulationRejectedCommand(
                turn: turn,
                tick: commandTick - 1,
                playerId: actingPlayer.id,
                command: command,
                reason: applied.reason,
              ),
            );
            commandStats.rejected += 1;
          }
        }
      }

      final economy = PersistentTurnEconomyProcessor.advanceForPlayers(
        state: state,
        playerIds: playerIds,
        mapData: mapData,
        ruleset: config.ruleset,
        mapObjectives: mapData.objectives,
      );
      state = economy.state;
      turnEvents.addAll(economy.events);
      final dominationHoldTurns = const DominationProgressCalculator()
          .advanceHoldTurns(
            playerIds: playerIds,
            state: state,
            mapData: mapData,
            victoryRules: config.matchRules.victory,
            previousHoldTurnsByPlayerId:
                state.runtimeState.dominationHoldTurnsByPlayerId,
          );
      state = state.copyWith(
        runtimeState: state.runtimeState.copyWith(
          dominationHoldTurnsByPlayerId: dominationHoldTurns,
        ),
      );
      final dominationProgress = const DominationProgressCalculator().snapshot(
        playerIds: playerIds,
        state: state,
        mapData: mapData,
        victoryRules: config.matchRules.victory,
      );
      final objectiveActionByPlayerId =
          _EconomySimulationTelemetry.objectiveActions(
            turn: turn,
            state: state,
            playerIds: playerIds,
            matchRules: config.matchRules,
            ruleset: config.ruleset,
          );
      final rowByPlayerId = <String, EconomySimulationTurnRow>{};
      for (final simulationPlayer in players) {
        final playerId = simulationPlayer.id;
        final row = rowFactory.rowFor(
          turn: turn,
          state: state,
          playerId: playerId,
          mapData: mapData,
          ruleset: config.ruleset,
          commandStats: commandStatsByPlayerId[playerId]!,
          domination: dominationProgress.entryFor(playerId),
          objectiveAction: objectiveActionByPlayerId[playerId],
        );
        rowByPlayerId[playerId] = row;
        rowsByPlayerId[playerId]!.add(row);
      }
      final row = rowByPlayerId[player.id]!;
      rows.add(row);
      telemetrySamples.add(
        BalanceTelemetryTurnSample(
          turn: turn,
          state: state,
          events: List.unmodifiable(turnEvents),
          meaningfulCommandsByPlayerId: {
            for (final entry in commandStatsByPlayerId.entries)
              entry.key: entry.value.meaningful,
          },
          dominationByPlayerId:
              _EconomySimulationTelemetry.dominationByPlayerId(
                dominationProgress,
              ),
          objectiveActionByPlayerId: objectiveActionByPlayerId,
          endPaceByPlayerId: {
            for (final entry in rowByPlayerId.entries)
              entry.key: entry.value.toEndPaceSample(),
          },
          outcome: const GameOutcomeDetector().evaluate(
            playerIds: playerIds,
            state: state,
            matchRules: config.matchRules,
            mapData: mapData,
            turn: turn,
          ),
        ),
      );
    }

    return EconomySimulationResult(
      state: state,
      rows: List.unmodifiable(rows),
      rowsByPlayerId: Map.unmodifiable(<String, List<EconomySimulationTurnRow>>{
        for (final entry in rowsByPlayerId.entries)
          entry.key: List<EconomySimulationTurnRow>.unmodifiable(entry.value),
      }),
      appliedCommands: List.unmodifiable(appliedCommands),
      appliedCommandRecords: List.unmodifiable(appliedCommandRecords),
      rejectedCommands: List.unmodifiable(rejectedCommands),
      rejectedCommandRecords: List.unmodifiable(rejectedCommandRecords),
      aiTurnRuntimes: List.unmodifiable(aiTurnRuntimes),
      telemetry: BalanceTelemetryAnalyzer(
        targets: config.telemetryTargets,
      ).analyze(playerIds: playerIds, samples: telemetrySamples),
    );
  }
}
