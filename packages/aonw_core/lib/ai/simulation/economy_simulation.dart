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

const int _recentHostilityMemoryTurns = 4;
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
    final mapData = config.mapData ?? _simulationMap();
    final mapDefinition = _mapDefinitionFrom(mapData);
    var state = _initialState(
      player: player,
      opponents: config.opponents,
      mapData: mapData,
    );
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
    final recentHostilityByPlayerId = <String, Map<String, int>>{};
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
          recentHostilePlayerIds: _recentHostilePlayerIds(
            playerId: actingPlayer.id,
            turn: turn,
            memory: recentHostilityByPlayerId,
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
        final strategyChoice = _strategyFor(
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
          final applied = _applyCommand(
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
            _recordRecentHostility(
              memory: recentHostilityByPlayerId,
              events: applied.events,
              turn: turn,
            );
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
      final objectiveActionByPlayerId = _objectiveActionByPlayerId(
        turn: turn,
        state: state,
        playerIds: playerIds,
        matchRules: config.matchRules,
        ruleset: config.ruleset,
      );
      final rowByPlayerId = <String, EconomySimulationTurnRow>{};
      for (final simulationPlayer in players) {
        final playerId = simulationPlayer.id;
        final row = _rowFor(
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
          dominationByPlayerId: _dominationByPlayerId(dominationProgress),
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

  static Map<String, BalanceTelemetryDominationSample> _dominationByPlayerId(
    DominationProgressSnapshot snapshot,
  ) {
    return {
      for (final entry in snapshot.entries)
        entry.playerId: BalanceTelemetryDominationSample(
          controlPercent: entry.controlPercent,
          requiredControlPercent: entry.requiredControlPercent,
          holdTurns: entry.holdTurns,
          requiredHoldTurns: entry.requiredHoldTurns,
        ),
    };
  }

  static Map<String, BalanceTelemetryObjectiveActionSample>
  _objectiveActionByPlayerId({
    required int turn,
    required PersistentGameState state,
    required Iterable<String> playerIds,
    required MatchRules matchRules,
    required GameRuleset ruleset,
  }) {
    final victory = matchRules.victory;
    final turnLimit = victory.turnLimit;
    if (!victory.scoreFallbackEnabled || turnLimit == null) return const {};

    const scorePressureWindow = 5;
    final remainingTurns = turnLimit - turn;
    if (remainingTurns < 0 || remainingTurns > scorePressureWindow) {
      return const {};
    }

    return BalanceTelemetryObjectiveActionDiagnostics.scorePressureSamplesFor(
      state: state,
      playerIds: playerIds,
      technologyRuleset: ruleset.technology,
    );
  }

  static _StrategyChoice _strategyFor({
    required AiPlayer player,
    required EconomySimulationConfig config,
    required int turn,
    required PersistentGameState state,
    required List<Player> players,
  }) {
    return switch (player.strategyId) {
      AiStrategyId.random => const _StrategyChoice(strategy: RandomStrategy()),
      AiStrategyId.basic ||
      AiStrategyId.scripted ||
      AiStrategyId.utility => const _StrategyChoice(strategy: BasicStrategy()),
      AiStrategyId.mcts => _mctsStrategyFor(
        player: player,
        config: config,
        turn: turn,
        state: state,
        players: players,
      ),
    };
  }

  static _StrategyChoice _mctsStrategyFor({
    required AiPlayer player,
    required EconomySimulationConfig config,
    required int turn,
    required PersistentGameState state,
    required List<Player> players,
  }) {
    final mctsConfig = config.mctsConfig;
    if (mctsConfig != null) {
      return _StrategyChoice(strategy: MctsStrategy(config: mctsConfig));
    }

    final runtimeChoice = _mctsRuntimeChoiceFor(
      mode: config.mctsProfileMode,
      turn: turn,
      state: state,
      players: players,
    );
    final profile = runtimeChoice.profile;
    if (profile != null) {
      return _StrategyChoice(
        strategy: MctsStrategy(runtimeProfile: profile),
        runtimeProfile: profile,
        adaptiveLateGame: runtimeChoice.adaptiveLateGame,
      );
    }

    return _StrategyChoice(
      strategy: MctsStrategy(
        config: _mctsConfigForSimulation(player.difficulty),
      ),
    );
  }

  static _MctsRuntimeChoice _mctsRuntimeChoiceFor({
    required EconomySimulationMctsProfileMode mode,
    required int turn,
    required PersistentGameState state,
    required List<Player> players,
  }) {
    return switch (mode) {
      EconomySimulationMctsProfileMode.simulation => const _MctsRuntimeChoice(),
      EconomySimulationMctsProfileMode.standard => const _MctsRuntimeChoice(
        profile: MctsRuntimeProfile.standard,
      ),
      EconomySimulationMctsProfileMode.interactive => const _MctsRuntimeChoice(
        profile: MctsRuntimeProfile.interactive,
      ),
      EconomySimulationMctsProfileMode.batterySaver => const _MctsRuntimeChoice(
        profile: MctsRuntimeProfile.batterySaver,
      ),
      EconomySimulationMctsProfileMode.adaptiveLocalSinglePlayer =>
        _adaptiveLocalSinglePlayerMctsProfile(
          turn: turn,
          state: state,
          players: players,
        ),
    };
  }

  static _MctsRuntimeChoice _adaptiveLocalSinglePlayerMctsProfile({
    required int turn,
    required PersistentGameState state,
    required List<Player> players,
  }) {
    final localSinglePlayer = _isLocalSinglePlayer(players);
    final adaptiveLateGame =
        localSinglePlayer &&
        (turn >= adaptiveLateGameTurnThreshold ||
            state.units.length >= adaptiveLateGameUnitThreshold ||
            state.cities.length >= adaptiveLateGameCityThreshold);
    return _MctsRuntimeChoice(
      profile: adaptiveLateGame
          ? MctsRuntimeProfile.batterySaver
          : MctsRuntimeProfile.interactive,
      adaptiveLateGame: adaptiveLateGame,
    );
  }

  static bool _isLocalSinglePlayer(List<Player> players) {
    var humanCount = 0;
    var aiCount = 0;
    for (final player in players) {
      switch (player.kind) {
        case PlayerKind.human:
          humanCount += 1;
        case PlayerKind.ai:
          if (player.ai != null) aiCount += 1;
      }
    }
    return humanCount == 1 && aiCount > 0;
  }

  static Set<String> _recentHostilePlayerIds({
    required String playerId,
    required int turn,
    required Map<String, Map<String, int>> memory,
  }) {
    final hostiles = memory[playerId];
    if (hostiles == null || hostiles.isEmpty) return const {};

    final active = <String>{};
    final stale = <String>[];
    for (final entry in hostiles.entries) {
      if (turn - entry.value <= _recentHostilityMemoryTurns) {
        active.add(entry.key);
      } else {
        stale.add(entry.key);
      }
    }
    for (final hostilePlayerId in stale) {
      hostiles.remove(hostilePlayerId);
    }
    return active;
  }

  static void _recordRecentHostility({
    required Map<String, Map<String, int>> memory,
    required Iterable<GameEvent> events,
    required int turn,
  }) {
    for (final event in events) {
      switch (event) {
        case UnitAttackedEvent(
          :final attackerOwnerPlayerId,
          :final defenderOwnerPlayerId,
        ):
          _markRecentHostile(
            memory: memory,
            victimPlayerId: defenderOwnerPlayerId,
            hostilePlayerId: attackerOwnerPlayerId,
            turn: turn,
          );
        case CityCapturedEvent(
          :final previousOwnerPlayerId,
          :final newOwnerPlayerId,
        ):
          _markRecentHostile(
            memory: memory,
            victimPlayerId: previousOwnerPlayerId,
            hostilePlayerId: newOwnerPlayerId,
            turn: turn,
          );
        case CityDestroyedEvent(
          :final previousOwnerPlayerId,
          :final attackerOwnerPlayerId,
        ):
          _markRecentHostile(
            memory: memory,
            victimPlayerId: previousOwnerPlayerId,
            hostilePlayerId: attackerOwnerPlayerId,
            turn: turn,
          );
        case DiplomaticRelationChangedEvent(
          :final playerAId,
          :final playerBId,
          :final newStatus,
        ):
          if (newStatus == DiplomaticRelationStatus.war) {
            _markRecentHostile(
              memory: memory,
              victimPlayerId: playerAId,
              hostilePlayerId: playerBId,
              turn: turn,
            );
            _markRecentHostile(
              memory: memory,
              victimPlayerId: playerBId,
              hostilePlayerId: playerAId,
              turn: turn,
            );
          }
        default:
          break;
      }
    }
  }

  static void _markRecentHostile({
    required Map<String, Map<String, int>> memory,
    required String victimPlayerId,
    required String hostilePlayerId,
    required int turn,
  }) {
    if (victimPlayerId == hostilePlayerId) return;
    (memory[victimPlayerId] ??= {})[hostilePlayerId] = turn;
  }

  static MctsConfig _mctsConfigForSimulation(AiDifficulty difficulty) {
    return MctsConfig.fromDifficultyProfile(difficulty.profile.simulationMcts);
  }

  static _ApplyCommandResult _applyCommand({
    required int turn,
    required int tick,
    required PersistentGameState state,
    required GameCommand command,
    required String actorPlayerId,
    required MapDefinition mapDefinition,
    required GameRuleset ruleset,
  }) {
    switch (command) {
      case FoundCityCommand():
        final result = const PersistentCityFoundingResolver().foundCity(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
          cityRuleset: ruleset.city,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
          reason: result.reason,
        );
      case SelectTechnologyCommand():
        final result = const PersistentResearchCommandResolver()
            .selectTechnology(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
              ruleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
          reason: result.reason,
        );
      case StartBuildingCommand():
        final result = const PersistentCityProductionResolver().startBuilding(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
          cityRuleset: ruleset.city,
          technologyRuleset: ruleset.technology,
          paceBalance: ruleset.paceBalance,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case StartUnitProductionCommand():
        final result = const PersistentCityProductionResolver()
            .startUnitProduction(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
              cityRuleset: ruleset.city,
              technologyRuleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case StartCityProjectCommand():
        final result = const PersistentCityProductionResolver()
            .startCityProject(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              cityRuleset: ruleset.city,
              paceBalance: ruleset.paceBalance,
            );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case SetCitySpecializationCommand():
        final result = const PersistentCityProductionResolver()
            .setCitySpecialization(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
            );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case MoveUnitCommand():
        final result = const PersistentMoveUnitResolver().resolve(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
          reason: result.reason,
        );
      case AssignMerchantTradeRouteCommand():
        final result = const PersistentMerchantTradeRouteResolver().assignRoute(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapData: _mapDataFromDefinition(mapDefinition),
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
          reason: result.reason,
        );
      case MoveMerchantToCityCommand():
        final result = const PersistentMerchantTradeRouteResolver().moveToCity(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapData: _mapDataFromDefinition(mapDefinition),
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
          reason: result.reason,
        );
      case SelectWorkerImprovementCommand():
        final result = const PersistentWorkerCommandResolver()
            .selectWorkerImprovement(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
              cityRuleset: ruleset.city,
              technologyRuleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case AssignWorkerToHexCommand():
        final result = const PersistentWorkerCommandResolver()
            .assignWorkerToHex(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
            );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case CancelWorkerJobCommand():
        final result = const PersistentWorkerCommandResolver().cancelWorkerJob(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case CancelWorkerAssignmentCommand():
        final result = const PersistentWorkerCommandResolver()
            .cancelWorkerAssignment(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
            );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case SkipUnitTurnCommand():
        final result = const PersistentUnitActionResolver().skipUnitTurn(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case FortifyUnitCommand():
        final result = const PersistentUnitActionResolver().fortifyUnit(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case AutoExploreUnitCommand():
        final result = const PersistentUnitActionResolver().autoExploreUnit(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case CancelUnitActionCommand():
        final result = const PersistentUnitActionResolver().cancelUnitAction(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case DetachTroopCommand():
        final result = const PersistentUnitDetachmentResolver().detachTroop(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case AttackHexCommand():
        return _applyAttackCommand(
          turn: turn,
          tick: tick,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
          ruleset: ruleset,
        );
      case TileTappedCommand() ||
          CityTappedCommand() ||
          RushProductionCommand() ||
          EndTurnCommand() ||
          SubmitTurnCommand() ||
          ResetUnitMovementCommand() ||
          SetActivePlayerCommand() ||
          ToggleMoveTargetingCommand() ||
          StartCityFoundingCommand() ||
          CancelCityFoundingCommand() ||
          StartCityWorkedHexSelectionCommand() ||
          CancelCityWorkedHexSelectionCommand() ||
          ToggleWorkedHexCommand() ||
          StartCityExpansionSelectionCommand() ||
          CancelCityExpansionSelectionCommand() ||
          SelectCityExpansionHexCommand() ||
          StartWorkerActionSelectionCommand() ||
          StartMerchantTradeRouteSelectionCommand() ||
          CancelMerchantTradeRouteSelectionCommand() ||
          StartMerchantMoveToCitySelectionCommand() ||
          CancelMerchantMoveToCitySelectionCommand() ||
          ConfirmWorkerImprovementCommand() ||
          CancelWorkerActionSelectionCommand() ||
          CancelResearchSelectionCommand() ||
          SendDiplomaticProposalCommand() ||
          RespondDiplomaticProposalCommand() ||
          SendDiplomaticMessageCommand() ||
          RespondDiplomaticMessageCommand() ||
          DeclareWarCommand() ||
          StartArtifactExcavationCommand() ||
          StoreArtifactInCityCommand() ||
          TradeArtifactCommand() ||
          OpenResourceTradeCommand() ||
          OpenResourceExchangeCommand() ||
          StartAttackTargetingCommand() ||
          CancelAttackTargetingCommand() ||
          StartCommanderMergeSelectionCommand() ||
          CancelCommanderMergeSelectionCommand() ||
          SelectTileCommand() ||
          SelectUnitCommand() ||
          SelectCityCommand() ||
          FocusNextPendingActionCommand() ||
          FocusTurnStartActionCommand():
        return _ApplyCommandResult(
          accepted: false,
          state: state,
          reason: 'unsupported_command_for_simulation',
        );
    }
  }

  static _ApplyCommandResult _applyAttackCommand({
    required int turn,
    required int tick,
    required PersistentGameState state,
    required AttackHexCommand command,
    required String actorPlayerId,
    required MapDefinition mapDefinition,
    required GameRuleset ruleset,
  }) {
    final withIntent = state.copyWith(
      runtimeState: state.runtimeState.copyWith(
        intendedAttacks: [
          IntendedAttack(
            attackerUnitId: command.attackerUnitId,
            defenderCol: command.defenderCol,
            defenderRow: command.defenderRow,
            declaredAtTick: tick,
            declaringPlayerId: actorPlayerId,
          ),
        ],
      ),
    );
    final result = PersistentTurnCombatResolver.resolve(
      turn: turn,
      state: withIntent,
      mapDefinition: mapDefinition,
      ruleset: ruleset,
    );
    final nextState = result.state.copyWith(
      runtimeState: result.state.runtimeState.copyWith(
        intendedAttacks: const [],
      ),
    );
    return _ApplyCommandResult(
      accepted: result.events.isNotEmpty,
      state: nextState,
      events: result.events,
      reason: result.events.isEmpty ? 'attack_not_resolved' : null,
    );
  }

  static EconomySimulationTurnRow _rowFor({
    required int turn,
    required PersistentGameState state,
    required String playerId,
    required MapData mapData,
    required GameRuleset ruleset,
    required EconomySimulationCommandStats commandStats,
    required DominationProgressEntry? domination,
    required BalanceTelemetryObjectiveActionSample? objectiveAction,
  }) {
    final ownUnits = [
      for (final unit in state.units)
        if (unit.ownerPlayerId == playerId) unit,
    ];
    final ownCities = [
      for (final city in state.cities)
        if (city.ownerPlayerId == playerId) city,
    ];
    final research = state.research.forPlayer(playerId);
    final unitSupply = CityUnitSupplyRules.forPlayer(
      playerId: playerId,
      cities: state.cities,
      units: state.units,
      fieldImprovements: state.fieldImprovements,
      mapData: mapData,
      cityRuleset: ruleset.city,
      research: state.research,
      technologyRuleset: ruleset.technology,
    );
    final goldBreakdown = _goldBreakdownForPlayer(
      state: state,
      playerId: playerId,
      mapData: mapData,
      ruleset: ruleset,
    );
    final researchProjectScience = _researchProjectScienceForPlayer(
      state: state,
      playerId: playerId,
      mapData: mapData,
      ruleset: ruleset,
    );
    final baseScience = ScienceYieldCalculator.totalForPlayer(
      playerId: playerId,
      cities: state.cities,
      research: state.research,
      ruleset: ruleset.technology,
      cityRuleset: ruleset.city,
    ).total;
    return EconomySimulationTurnRow(
      turn: turn,
      cityCount: ownCities.length,
      unitCount: ownUnits.length,
      unitSupplyCapacity: unitSupply.capacity,
      unitSupplyUsed: unitSupply.used,
      unitSupplyAvailable: unitSupply.available,
      militaryCount: ownUnits
          .where(
            (unit) => _militaryAssessment.canServeAsMilitaryUnit(
              unit,
              ruleset.combat,
            ),
          )
          .length,
      settlerCount: _unitCount(ownUnits, GameUnitType.settler),
      workerCount: _unitCount(ownUnits, GameUnitType.worker),
      warriorCount: _unitCount(ownUnits, GameUnitType.warrior),
      archerCount: _unitCount(ownUnits, GameUnitType.archer),
      gold: state.playerGold[playerId] ?? 0,
      cityGoldIncome: goldBreakdown.cityGoldIncome,
      wealthProjectGold: goldBreakdown.wealthProjectGold,
      unitUpkeep: goldBreakdown.unitUpkeep,
      netGoldPerTurn: goldBreakdown.netGoldPerTurn,
      sciencePerTurn: baseScience + researchProjectScience,
      researchProjectScience: researchProjectScience,
      completedTechCount: research.unlockedTechnologyIds.length,
      activeTechnology: research.activeTechnologyId?.name ?? '',
      unlockedTechnologies:
          (research.unlockedTechnologyIds.toList()
                ..sort((a, b) => a.name.compareTo(b.name)))
              .map((technology) => technology.name)
              .join(';'),
      buildingQueues: ownCities.where(_hasBuildingQueue).length,
      unitQueues: ownCities.where(_hasUnitQueue).length,
      projectQueues: ownCities.where(_hasProjectQueue).length,
      wealthProjectQueues: _projectQueueCount(
        ownCities,
        CityProjectType.wealth,
      ),
      researchProjectQueues: _projectQueueCount(
        ownCities,
        CityProjectType.research,
      ),
      foundCityCommands: commandStats.foundCity,
      startUnitCommands: commandStats.startUnit,
      startBuildingCommands: commandStats.startBuilding,
      startProjectCommands: commandStats.startProject,
      workerJobCommands: commandStats.workerJob,
      moveCommands: commandStats.move,
      attackCommands: commandStats.attack,
      rejectedCommands: commandStats.rejected,
      objectiveActionAdvice: objectiveAction?.advice.name ?? '',
      objectiveActionTarget: objectiveAction?.target.name ?? '',
      dominationControlPercent: domination?.controlPercent ?? 0,
      dominationHoldTurns: domination?.holdTurns ?? 0,
      dominationRequiredControlPercent:
          domination?.requiredControlPercent ??
          MatchRules.standard.victory.dominationControlPercent,
      dominationRequiredHoldTurns:
          domination?.requiredHoldTurns ??
          MatchRules.standard.victory.dominationHoldTurns,
    );
  }

  static PersistentGameState _initialState({
    required Player player,
    required List<Player> opponents,
    required MapData mapData,
  }) {
    final players = [player, ...opponents];
    final units = StartingUnits.unitsForPlayers(players, mapData: mapData);
    final state = PersistentGameState(
      playerColors: {
        for (final simulationPlayer in players)
          simulationPlayer.id: simulationPlayer.colorValue,
      },
      playerGold: {
        for (final simulationPlayer in players) simulationPlayer.id: 0,
      },
      units: units,
    );
    final fogOfWar = const FogOfWarService().recompute(
      current: state.fogOfWar,
      mapData: mapData,
      playerIds: [for (final simulationPlayer in players) simulationPlayer.id],
      units: state.units,
      cities: state.cities,
    );
    return state.copyWith(fogOfWar: fogOfWar);
  }

  static _GoldBreakdown _goldBreakdownForPlayer({
    required PersistentGameState state,
    required String playerId,
    required MapData mapData,
    required GameRuleset ruleset,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: playerId,
      research: state.research,
      ruleset: ruleset.technology,
    );
    var cityGoldIncome = 0;
    var wealthProjectGold = 0;
    for (final city in state.cities) {
      if (city.ownerPlayerId != playerId) continue;
      final economy = _economyFor(
        city: city,
        state: state,
        mapData: mapData,
        ruleset: ruleset,
        technologyEffects: technologyEffects,
      );
      cityGoldIncome += economy.netYield.gold < 0 ? 0 : economy.netYield.gold;
      if (city.productionQueue?.target case ProjectProductionTarget(
        projectType: CityProjectType.wealth,
      )) {
        wealthProjectGold += CityProjectRules.outputFor(
          type: CityProjectType.wealth,
          productionPerTurn: CityProductionRules.productionPerTurn(
            economy.netYield.production,
          ),
        );
      }
    }
    final upkeep = UnitUpkeepRules.forPlayer(
      playerId: playerId,
      units: state.units,
      cities: state.cities,
    );
    return _GoldBreakdown(
      cityGoldIncome: cityGoldIncome,
      wealthProjectGold: wealthProjectGold,
      unitUpkeep: upkeep.total,
    );
  }

  static int _researchProjectScienceForPlayer({
    required PersistentGameState state,
    required String playerId,
    required MapData mapData,
    required GameRuleset ruleset,
  }) {
    var total = 0;
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: playerId,
      research: state.research,
      ruleset: ruleset.technology,
    );
    for (final city in state.cities) {
      if (city.ownerPlayerId != playerId) continue;
      if (city.productionQueue?.target case ProjectProductionTarget(
        projectType: CityProjectType.research,
      )) {
        final economy = _economyFor(
          city: city,
          state: state,
          mapData: mapData,
          ruleset: ruleset,
          technologyEffects: technologyEffects,
        );
        total += CityProjectRules.outputFor(
          type: CityProjectType.research,
          productionPerTurn: CityProductionRules.productionPerTurn(
            economy.netYield.production,
          ),
        );
      }
    }
    return total;
  }

  static CityEconomyBreakdown _economyFor({
    required GameCity city,
    required PersistentGameState state,
    required MapData mapData,
    required GameRuleset ruleset,
    required TechnologyEffectSummary technologyEffects,
  }) {
    final cityYield = CityYieldCalculator.totalFor(
      city,
      mapData,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      ruleset: ruleset.city,
    );
    return CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapData: mapData,
      ruleset: ruleset.city,
      paceBalance: ruleset.paceBalance,
      technologyEffects: technologyEffects,
    );
  }

  static int _unitCount(List<GameUnit> units, GameUnitType type) {
    return units.where((unit) => unit.type == type).length;
  }

  static bool _hasBuildingQueue(GameCity city) {
    return city.productionQueue?.target is BuildingProductionTarget;
  }

  static bool _hasUnitQueue(GameCity city) {
    return city.productionQueue?.target is UnitProductionTarget;
  }

  static bool _hasProjectQueue(GameCity city) {
    return city.productionQueue?.target is ProjectProductionTarget;
  }

  static int _projectQueueCount(
    Iterable<GameCity> cities,
    CityProjectType projectType,
  ) {
    return cities.where((city) => _projectTypeFor(city) == projectType).length;
  }

  static CityProjectType? _projectTypeFor(GameCity city) {
    return switch (city.productionQueue?.target) {
      ProjectProductionTarget(:final projectType) => projectType,
      _ => null,
    };
  }

  static MapData _simulationMap() {
    const size = 9;
    return MapData(
      cols: size,
      rows: size,
      mapName: 'economy_simulation',
      tiles: [
        for (var row = 0; row < size; row++)
          for (var col = 0; col < size; col++) _tile(col, row),
      ],
    );
  }

  static MapData _mapDataFromDefinition(MapDefinition mapDefinition) {
    return MapData(
      cols: mapDefinition.cols,
      rows: mapDefinition.rows,
      mapName: mapDefinition.mapName,
      defaultZoom: mapDefinition.defaultZoom,
      tiles: [
        for (final tile in mapDefinition.tiles)
          TileData(
            col: tile.col,
            row: tile.row,
            terrains: tile.terrains,
            resources: tile.resources,
            height: tile.height,
          ),
      ],
    );
  }

  static TileData _tile(int col, int row) {
    final resource = switch ((col, row)) {
      (3, 2) || (7, 7) => ResourceType.wheat,
      (2, 4) || (8, 6) => ResourceType.iron,
      (4, 3) => ResourceType.deer,
      _ => null,
    };
    final terrain = switch ((col + row) % 7) {
      0 => TerrainType.hills,
      1 => TerrainType.forest,
      2 => TerrainType.grassland,
      _ => TerrainType.plains,
    };
    return TileData(
      col: col,
      row: row,
      terrains: [terrain],
      resources: [?resource],
      height: terrain == TerrainType.hills ? 1 : 0,
    );
  }

  static MapDefinition _mapDefinitionFrom(MapData mapData) {
    return MapDefinition(
      cols: mapData.cols,
      rows: mapData.rows,
      mapName: mapData.mapName,
      defaultZoom: mapData.defaultZoom,
      tiles: [
        for (final tile in mapData.tiles)
          MapTileDefinition(
            col: tile.col,
            row: tile.row,
            terrains: tile.terrains,
            resources: tile.resources,
            height: tile.height,
          ),
      ],
    );
  }
}

class _ApplyCommandResult {
  const _ApplyCommandResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final List<GameEvent> events;
  final String? reason;
}

class _StrategyChoice {
  const _StrategyChoice({
    required this.strategy,
    this.runtimeProfile,
    this.adaptiveLateGame = false,
  });

  final AiStrategy strategy;
  final MctsRuntimeProfile? runtimeProfile;
  final bool adaptiveLateGame;
}

class _MctsRuntimeChoice {
  const _MctsRuntimeChoice({this.profile, this.adaptiveLateGame = false});

  final MctsRuntimeProfile? profile;
  final bool adaptiveLateGame;
}

class _GoldBreakdown {
  const _GoldBreakdown({
    required this.cityGoldIncome,
    required this.wealthProjectGold,
    required this.unitUpkeep,
  });

  final int cityGoldIncome;
  final int wealthProjectGold;
  final int unitUpkeep;

  int get netGoldPerTurn => cityGoldIncome + wealthProjectGold - unitUpkeep;
}
