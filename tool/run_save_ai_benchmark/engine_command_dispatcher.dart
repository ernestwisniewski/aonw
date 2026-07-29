part of '../run_save_ai_benchmark.dart';

final class BenchmarkCommandTransition {
  const BenchmarkCommandTransition({
    required this.accepted,
    required this.state,
    required this.events,
    this.uiEffects = const [],
    this.rejectionReasons = const [],
  });

  final bool accepted;
  final GameState state;
  final List<GameEvent> events;
  final List<UiEffect> uiEffects;
  final List<String> rejectionReasons;
}

final class BenchmarkCommandDispatcher {
  BenchmarkCommandDispatcher({
    required CanonicalGameSnapshot snapshot,
    required MapReadView mapView,
    required GameRuleset ruleset,
  }) : _engineSnapshot = snapshot,
       _mapView = mapView,
       _ruleset = ruleset,
       _reducer = GameStateReducer(mapData: mapView, ruleset: ruleset);

  CanonicalGameSnapshot _engineSnapshot;
  final MapReadView _mapView;
  final GameRuleset _ruleset;
  final GameStateReducer _reducer;

  BenchmarkCommandTransition apply({
    required GameState state,
    required GameCommand command,
    required GameCommandContext context,
  }) {
    final family = command is DomainCommand
        ? GameEngine.commandFamily(command)
        : null;
    if (family != null) {
      return _applyEngineCommand(
        state: state,
        command: command as DomainCommand,
        context: context,
      );
    }
    final transition = _reducer.reduce(state, command, context: context);
    return BenchmarkCommandTransition(
      accepted: transition.state != state,
      state: transition.state,
      events: transition.events,
      uiEffects: transition.uiEffects,
      rejectionReasons: _rejectionReasons(transition),
    );
  }

  BenchmarkCommandTransition _applyEngineCommand({
    required GameState state,
    required DomainCommand command,
    required GameCommandContext context,
  }) {
    final result = const SimulationGameEngineAdapter().apply(
      snapshot: _engineSnapshot,
      state: state.toPersistentState(),
      command: command,
      actorPlayerId: context.actorPlayerId ?? state.activePlayerId,
      commandTick: context.commandTick,
      mapView: _mapView,
      ruleset: _ruleset,
      movementVisibilityMode: context.ignoreFogOfWar
          ? MovementCommandVisibilityMode.unrestricted
          : MovementCommandVisibilityMode.authoritative,
      combatVisibilityMode: context.ignoreFogOfWar
          ? CombatCommandVisibilityMode.unrestricted
          : CombatCommandVisibilityMode.authoritative,
    );
    _engineSnapshot = result.snapshot;
    final nextState = result.accepted
        ? state.copyWithPersistentState(result.state)
        : state;
    return BenchmarkCommandTransition(
      accepted: result.accepted && nextState != state,
      state: nextState,
      events: result.events,
      rejectionReasons: [?result.reason],
    );
  }
}
