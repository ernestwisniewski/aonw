import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';

final class ServerCommandApplication {
  ServerCommandApplication({
    required this.accepted,
    required this.snapshot,
    this.events = const [],
    Iterable<MovementCommandExecution> movementExecutions = const [],
    Iterable<CombatAnimationFact> combatAnimations = const [],
    this.reason,
  }) : movementExecutions = List.unmodifiable(movementExecutions),
       combatAnimations = List.unmodifiable(combatAnimations);

  final bool accepted;
  final CanonicalGameSnapshot snapshot;
  final List<GameEvent> events;
  final List<MovementCommandExecution> movementExecutions;
  final List<CombatAnimationFact> combatAnimations;
  final String? reason;

  factory ServerCommandApplication.fromEngine(
    CanonicalGameSnapshot snapshot,
    GameEngineResult result,
  ) {
    return switch (result) {
      GameEngineAccepted() => ServerCommandApplication(
        accepted: true,
        snapshot: result.snapshot,
        events: result.events,
        movementExecutions: result.movementDelta.executions,
        combatAnimations: result.combatAnimations,
      ),
      final GameEngineRejected rejected => ServerCommandApplication(
        accepted: false,
        snapshot: snapshot,
        reason: rejected.reason,
      ),
    };
  }

  ServerCommandApplication withSnapshot(CanonicalGameSnapshot nextSnapshot) {
    if (identical(nextSnapshot, snapshot)) return this;
    return ServerCommandApplication(
      accepted: accepted,
      snapshot: nextSnapshot,
      events: events,
      movementExecutions: movementExecutions,
      combatAnimations: combatAnimations,
      reason: reason,
    );
  }
}
