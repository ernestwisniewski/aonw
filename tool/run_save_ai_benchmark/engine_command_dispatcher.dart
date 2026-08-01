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
       _ruleset = ruleset;

  CanonicalGameSnapshot _engineSnapshot;
  final MapReadView _mapView;
  final GameRuleset _ruleset;

  CanonicalGameSnapshot get snapshot => _engineSnapshot;

  BenchmarkCommandTransition apply({
    required GameState state,
    required DomainCommand command,
    required GameCommandContext context,
  }) {
    if (GameEngine.commandFamily(command) != null) {
      return _applyEngineCommand(
        state: state,
        command: command,
        context: context,
      );
    }
    return BenchmarkCommandTransition(
      accepted: false,
      state: state,
      events: const [],
      rejectionReasons: const ['unsupported_command_for_simulation'],
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
      turnPlayerIds: [
        for (final participant in _engineSnapshot.domain.participants)
          if (!_engineSnapshot.session.isKicked(participant.id)) participant.id,
      ],
      requiredTurnSubmissionPlayerIds: [
        for (final participant in _engineSnapshot.domain.participants)
          if (!_engineSnapshot.session.isKicked(participant.id)) participant.id,
      ],
      savedAt: _engineSnapshot.metadata.savedAtUtc,
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
