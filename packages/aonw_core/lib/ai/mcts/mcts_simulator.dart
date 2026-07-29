import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_rng.dart';
import 'package:aonw_core/ai/ai_strategy.dart';
import 'package:aonw_core/ai/civilization/civilization_profile_registry.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_action.dart';
import 'package:aonw_core/ai/mcts/mcts_opponent_view_index.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/ai/mcts/mcts_simulation_projection.dart';
import 'package:aonw_core/ai/simulation/simulation_game_engine_adapter.dart';
import 'package:aonw_core/ai/strategies/basic_strategy.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/turn.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract interface class MctsSimulator {
  SimulatedState applyAction(SimulatedState state, MctsAction action);

  SimulatedState advanceTurn(SimulatedState state);
}

class TracingMctsSimulator implements MctsSimulator {
  final AiStrategy opponentStrategy;
  final bool simulateOpponentPlans;
  final bool simulateTurnEconomy;

  const TracingMctsSimulator({
    this.opponentStrategy = const BasicStrategy(),
    this.simulateOpponentPlans = true,
    this.simulateTurnEconomy = true,
  });

  @override
  SimulatedState applyAction(SimulatedState state, MctsAction action) {
    return state.apply(action);
  }

  @override
  SimulatedState advanceTurn(SimulatedState state) {
    if (!simulateTurnEconomy) {
      return SimulatedState(
        view: state.view,
        ownUnits: state.ownUnits,
        visibleEnemyUnits: state.visibleEnemyUnits,
        ownCities: state.ownCities,
        rememberedEnemyCities: state.rememberedEnemyCities,
        ownResearch: state.ownResearch,
        plannedActions: state.plannedActions,
        usedCommands: state.usedCommands,
        maxPlanningDepth: state.maxPlanningDepth,
        planningEnded: true,
      );
    }

    final view = state.view;
    final mapData = view.mapData;
    final ruleset = view.ruleset;
    final opponentInput = (
      turn: view.turn,
      mapData: mapData,
      ruleset: ruleset,
      engineSnapshot: view.engineSnapshot,
    );
    final persistent = MctsSimulationProjection.persistentStateFromView(
      view,
      units: view.movementBlockingUnits,
      cities: [...state.ownCities, ...state.rememberedEnemyCities],
      research: state.researchState,
    );
    final afterOpponentPlans = simulateOpponentPlans
        ? _applyOpponentPlans(
            state: persistent,
            forPlayerId: view.forPlayerId,
            input: opponentInput,
          )
        : persistent;
    final advanced = PersistentTurnEconomyProcessor.advanceForPlayers(
      state: afterOpponentPlans,
      playerIds: MctsOpponentViewIndex.fromState(
        afterOpponentPlans,
      ).knownPlayerIds(view.forPlayerId),
      mapData: mapData,
      ruleset: ruleset,
      mapObjectives: mapData.objectives,
    );
    final nextView = _nextMctsView(advanced.state, view);
    return SimulatedState(
      view: nextView,
      plannedActions: state.plannedActions,
      usedCommands: state.usedCommands,
      maxPlanningDepth: state.maxPlanningDepth,
      planningEnded: true,
    );
  }

  PersistentGameState _applyOpponentPlans({
    required PersistentGameState state,
    required String forPlayerId,
    required _OpponentPlanningInput input,
  }) {
    final (:turn, :mapData, :ruleset, :engineSnapshot) = input;
    var current = state;
    var viewIndex = MctsOpponentViewIndex.fromState(current);
    final opponentPlayerIds = viewIndex.opponentPlayerIds(forPlayerId);
    for (var i = 0; i < opponentPlayerIds.length; i += 1) {
      final opponentId = opponentPlayerIds[i];
      final opponentView = viewIndex.viewFor(
        state: current,
        opponentId: opponentId,
        turn: turn,
        mapData: mapData,
        ruleset: ruleset,
        engineSnapshot: engineSnapshot,
      );
      if (opponentView.ownUnits.isEmpty && opponentView.ownCities.isEmpty) {
        continue;
      }
      const civRegistry = CivilizationProfileRegistry();
      final civProfile = civRegistry.profileFor(
        current.countryForPlayer(opponentId),
      );
      final plan = opponentStrategy.plan(
        opponentView,
        AiContext(
          ruleset: ruleset,
          mapData: mapData,
          turn: turn,
          rng: AiRng.fromTurn(turn: turn, playerId: opponentId, baseSeed: 0),
          civProfile: civProfile,
          persona: civProfile.defaultPersona,
        ),
      );
      var tick = 1;
      var appliedNonTerminalCommand = false;
      for (final command in plan.commands) {
        if (_isTerminal(command)) continue;
        appliedNonTerminalCommand = true;
        current = _applyOpponentCommand(
          state: current,
          command: command,
          actorPlayerId: opponentId,
          tick: tick,
          input: input,
        );
        tick += 1;
      }
      if (appliedNonTerminalCommand && i < opponentPlayerIds.length - 1) {
        viewIndex = MctsOpponentViewIndex.fromState(current);
      }
    }
    return current;
  }

  PersistentGameState _applyOpponentCommand({
    required PersistentGameState state,
    required GameCommand command,
    required String actorPlayerId,
    required int tick,
    required _OpponentPlanningInput input,
  }) {
    final (:turn, :mapData, :ruleset, :engineSnapshot) = input;
    return switch (command) {
      MoveUnitCommand() => _applyOpponentMove(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        mapData: mapData,
      ),
      AttackHexCommand() => _applyOpponentAttack(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        turn: turn,
        tick: tick,
        mapTiles: mapData,
        ruleset: ruleset,
      ),
      SkipUnitTurnCommand() ||
      FortifyUnitCommand() => _applySimulationEngineUnitAction(
        state: state,
        command: command as DomainCommand,
        actorPlayerId: actorPlayerId,
        tick: tick,
        mapData: mapData,
        ruleset: ruleset,
        engineSnapshot: engineSnapshot,
      ),
      CancelUnitActionCommand() =>
        const PersistentUnitActionResolver()
            .cancelUnitAction(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
            )
            .state,
      AutoExploreUnitCommand() => _applyOpponentAutoExplore(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        mapData: mapData,
      ),
      FoundCityCommand() =>
        const PersistentCityFoundingResolver()
            .foundCity(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapTiles: mapData,
            )
            .state,
      SelectTechnologyCommand() =>
        const PersistentResearchCommandResolver()
            .selectTechnology(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapTiles: mapData,
              ruleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            )
            .state,
      StartBuildingCommand() =>
        const PersistentCityProductionResolver()
            .startBuilding(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapTiles: mapData,
              cityRuleset: ruleset.city,
              technologyRuleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            )
            .state,
      StartUnitProductionCommand() =>
        const PersistentCityProductionResolver()
            .startUnitProduction(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapView: mapData,
              cityRuleset: ruleset.city,
              technologyRuleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            )
            .state,
      StartCityProjectCommand() =>
        const PersistentCityProductionResolver()
            .startCityProject(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              cityRuleset: ruleset.city,
              paceBalance: ruleset.paceBalance,
            )
            .state,
      SetCitySpecializationCommand() =>
        const PersistentCityProductionResolver()
            .setCitySpecialization(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
            )
            .state,
      SelectWorkerImprovementCommand() =>
        const PersistentWorkerCommandResolver()
            .selectWorkerImprovement(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapTiles: mapData,
              cityRuleset: ruleset.city,
              technologyRuleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            )
            .state,
      ConfirmWorkerImprovementCommand() =>
        const PersistentWorkerCommandResolver()
            .confirmWorkerImprovement(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapTiles: mapData,
              cityRuleset: ruleset.city,
              technologyRuleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            )
            .state,
      AssignWorkerToHexCommand() =>
        const PersistentWorkerCommandResolver()
            .assignWorkerToHex(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapTiles: mapData,
            )
            .state,
      _ => state,
    };
  }

  PersistentGameState _applyOpponentAttack({
    required PersistentGameState state,
    required AttackHexCommand command,
    required String actorPlayerId,
    required int turn,
    required int tick,
    required MapTileLookup mapTiles,
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
            cityConquestAction: command.cityConquestAction,
          ),
        ],
      ),
    );
    final result = PersistentTurnCombatResolver.resolve(
      turn: turn,
      state: withIntent,
      mapTiles: mapTiles,
      ruleset: ruleset,
    );
    return result.state.copyWith(
      runtimeState: result.state.runtimeState.copyWith(
        intendedAttacks: const [],
      ),
    );
  }

  bool _isTerminal(GameCommand command) {
    return command is EndTurnCommand || command is SubmitTurnCommand;
  }
}

typedef _OpponentPlanningInput = ({
  int turn,
  MapReadView mapData,
  GameRuleset ruleset,
  CanonicalGameSnapshot? engineSnapshot,
});

GameView _nextMctsView(PersistentGameState state, GameView previous) {
  return GameView.fromPersistentState(
    state,
    forPlayerId: previous.forPlayerId,
    turn: previous.turn + 1,
    mapData: previous.mapData,
    ruleset: previous.ruleset,
    engineSnapshot: previous.engineSnapshot,
    activeHostilePlayerIds: previous.activeHostilePlayerIds,
    recentHostilePlayerIds: previous.recentHostilePlayerIds,
    pressureTargetPlayerIds: previous.pressureTargetPlayerIds,
    defaultNeutralPlayerIds: previous.defaultNeutralPlayerIds,
    pendingCityAttackThreats: previous.pendingCityAttackThreats,
    ignoreFogOfWar: !previous.visibility.isEnabled,
  );
}

PersistentGameState _applySimulationEngineUnitAction({
  required PersistentGameState state,
  required DomainCommand command,
  required String actorPlayerId,
  required int tick,
  required MapReadView mapData,
  required GameRuleset ruleset,
  required CanonicalGameSnapshot? engineSnapshot,
}) {
  final snapshot =
      engineSnapshot ??
      (throw StateError(
        'MCTS unit actions require a canonical engine snapshot.',
      ));
  return const SimulationGameEngineAdapter()
      .apply(
        snapshot: snapshot,
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        commandTick: tick,
        mapView: mapData,
        ruleset: ruleset,
      )
      .state;
}

PersistentGameState _applyOpponentMove({
  required PersistentGameState state,
  required MoveUnitCommand command,
  required String actorPlayerId,
  required MapTraversalView mapData,
}) {
  return const PersistentMoveUnitResolver()
      .resolve(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        mapData: mapData,
        visibilityMode: MovementCommandVisibilityMode.unrestricted,
      )
      .state;
}

PersistentGameState _applyOpponentAutoExplore({
  required PersistentGameState state,
  required AutoExploreUnitCommand command,
  required String actorPlayerId,
  required MapTraversalView mapData,
}) {
  return const PersistentAutoExploreCommandResolver()
      .resolve(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        mapData: mapData,
        phase: AutoExploreCommandPhase.direct,
      )
      .state;
}
