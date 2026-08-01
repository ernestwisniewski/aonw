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
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
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
    final nextView = simulateTurnEconomy
        ? _simulateNextTurnView(state)
        : state.view;
    return _completePlanning(state, nextView);
  }

  GameView _simulateNextTurnView(SimulatedState state) {
    final view = state.view;
    final mapData = view.mapData;
    final ruleset = view.ruleset;
    final opponentInput = (turn: view.turn, mapData: mapData, ruleset: ruleset);
    final initial = (
      state: MctsSimulationProjection.persistentStateFromView(
        view,
        units: view.movementBlockingUnits,
        cities: [...state.ownCities, ...state.rememberedEnemyCities],
        research: state.researchState,
      ),
      snapshot:
          view.engineSnapshot ??
          (throw StateError(
            'MCTS turn simulation requires a canonical engine snapshot.',
          )),
    );
    final afterOpponentPlans = simulateOpponentPlans
        ? _applyOpponentPlans(
            current: initial,
            forPlayerId: view.forPlayerId,
            input: opponentInput,
          )
        : initial;
    final playerIds = [
      for (final participant in afterOpponentPlans.snapshot.domain.participants)
        if (!afterOpponentPlans.snapshot.session.isKicked(participant.id))
          participant.id,
    ];
    final advanced = const SimulationGameEngineAdapter()
        .finalizeSimultaneousTurn(
          snapshot: afterOpponentPlans.snapshot,
          state: afterOpponentPlans.state,
          playerIds: playerIds,
          commandTick: 1,
          mapView: mapData,
          ruleset: ruleset,
        );
    if (!advanced.accepted) {
      throw StateError(
        'GameEngine rejected MCTS turn finalization: '
        '${advanced.reason ?? 'command_rejected'}',
      );
    }
    final nextTurn = advanced.snapshot.domain.turn;
    final nextView = _nextMctsView(
      state: advanced.state,
      previous: view,
      snapshot: advanced.snapshot,
      turn: nextTurn,
    );
    return nextView;
  }

  _MctsSimulationEnvelope _applyOpponentPlans({
    required _MctsSimulationEnvelope current,
    required String forPlayerId,
    required _OpponentPlanningInput input,
  }) {
    final (:turn, :mapData, :ruleset) = input;
    var envelope = current;
    var viewIndex = MctsOpponentViewIndex.fromState(envelope.state);
    final opponentPlayerIds = viewIndex.opponentPlayerIds(forPlayerId);
    for (var i = 0; i < opponentPlayerIds.length; i += 1) {
      final opponentId = opponentPlayerIds[i];
      final opponentView = viewIndex.viewFor(
        state: envelope.state,
        opponentId: opponentId,
        turn: turn,
        mapData: mapData,
        ruleset: ruleset,
        engineSnapshot: envelope.snapshot,
      );
      if (opponentView.ownUnits.isEmpty && opponentView.ownCities.isEmpty) {
        continue;
      }
      const civRegistry = CivilizationProfileRegistry();
      final civProfile = civRegistry.profileFor(
        envelope.state.countryForPlayer(opponentId),
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
        envelope = _applyOpponentCommand(
          current: envelope,
          command: command,
          actorPlayerId: opponentId,
          tick: tick,
          input: input,
        );
        tick += 1;
      }
      if (appliedNonTerminalCommand && i < opponentPlayerIds.length - 1) {
        viewIndex = MctsOpponentViewIndex.fromState(envelope.state);
      }
    }
    return envelope;
  }

  _MctsSimulationEnvelope _applyOpponentCommand({
    required _MctsSimulationEnvelope current,
    required DomainCommand command,
    required String actorPlayerId,
    required int tick,
    required _OpponentPlanningInput input,
  }) {
    final mapData = input.mapData;
    final ruleset = input.ruleset;
    final family = GameEngine.commandFamily(command);
    if (family != null) {
      return _applySimulationEngineCommand(
        current: current,
        command: command,
        actorPlayerId: actorPlayerId,
        tick: tick,
        mapData: mapData,
        ruleset: ruleset,
      );
    }
    return current;
  }

  bool _isTerminal(DomainCommand command) {
    return command is EndTurnCommand || command is SubmitTurnCommand;
  }
}

typedef _OpponentPlanningInput = ({
  int turn,
  MapReadView mapData,
  GameRuleset ruleset,
});

typedef _MctsSimulationEnvelope = ({
  PersistentGameState state,
  CanonicalGameSnapshot snapshot,
});

SimulatedState _completePlanning(SimulatedState state, GameView view) {
  return SimulatedState(
    view: view,
    plannedActions: state.plannedActions,
    usedCommands: state.usedCommands,
    maxPlanningDepth: state.maxPlanningDepth,
    planningEnded: true,
  );
}

GameView _nextMctsView({
  required PersistentGameState state,
  required GameView previous,
  required CanonicalGameSnapshot snapshot,
  required int turn,
}) {
  return GameView.fromPersistentState(
    state,
    forPlayerId: previous.forPlayerId,
    turn: turn,
    mapData: previous.mapData,
    ruleset: previous.ruleset,
    engineSnapshot: snapshot,
    activeHostilePlayerIds: previous.activeHostilePlayerIds,
    recentHostilePlayerIds: previous.recentHostilePlayerIds,
    pressureTargetPlayerIds: previous.pressureTargetPlayerIds,
    defaultNeutralPlayerIds: previous.defaultNeutralPlayerIds,
    pendingCityAttackThreats: previous.pendingCityAttackThreats,
    ignoreFogOfWar: !previous.visibility.isEnabled,
  );
}

_MctsSimulationEnvelope _applySimulationEngineCommand({
  required _MctsSimulationEnvelope current,
  required DomainCommand command,
  required String actorPlayerId,
  required int tick,
  required MapReadView mapData,
  required GameRuleset ruleset,
}) {
  final result = const SimulationGameEngineAdapter().apply(
    snapshot: current.snapshot,
    state: current.state,
    command: command,
    actorPlayerId: actorPlayerId,
    commandTick: tick,
    mapView: mapData,
    ruleset: ruleset,
    movementVisibilityMode: MovementCommandVisibilityMode.unrestricted,
    combatVisibilityMode: CombatCommandVisibilityMode.unrestricted,
  );
  return (state: result.state, snapshot: result.snapshot);
}
