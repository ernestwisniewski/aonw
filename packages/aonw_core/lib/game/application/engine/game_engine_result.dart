import 'package:aonw_core/game/application/engine/combat_animation_fact.dart';
import 'package:aonw_core/game/application/engine/movement_execution_delta.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';

/// State-container-neutral outcome of applying one engine command.
sealed class GameEngineResult {
  const GameEngineResult();

  factory GameEngineResult.accepted({
    required CanonicalGameSnapshot snapshot,
    List<DomainEvent> events = const [],
    MovementExecutionDelta movementDelta = MovementExecutionDelta.empty,
    List<CombatAnimationFact> combatAnimations = const [],
  }) {
    return GameEngineAccepted._(
      snapshot: snapshot,
      events: events.isEmpty
          ? const []
          : List<DomainEvent>.unmodifiable(events),
      movementDelta: movementDelta,
      combatAnimations: combatAnimations.isEmpty
          ? const []
          : List<CombatAnimationFact>.unmodifiable(combatAnimations),
    );
  }

  factory GameEngineResult.rejected({
    required CanonicalGameSnapshot snapshot,
    required String reason,
  }) {
    return GameEngineRejected._(snapshot: snapshot, reason: reason);
  }

  CanonicalGameSnapshot get snapshot;
  List<DomainEvent> get events;
  MovementExecutionDelta get movementDelta;
  List<CombatAnimationFact> get combatAnimations;
}

/// Accepted transition with its next snapshot and ordered domain facts.
final class GameEngineAccepted extends GameEngineResult {
  const GameEngineAccepted._({
    required this.snapshot,
    required this.events,
    required this.movementDelta,
    required this.combatAnimations,
  });

  @override
  final CanonicalGameSnapshot snapshot;

  @override
  final List<DomainEvent> events;

  @override
  final MovementExecutionDelta movementDelta;

  @override
  final List<CombatAnimationFact> combatAnimations;
}

/// Rejected transition. The snapshot is the unchanged input snapshot.
final class GameEngineRejected extends GameEngineResult {
  const GameEngineRejected._({required this.snapshot, required this.reason});

  @override
  final CanonicalGameSnapshot snapshot;

  @override
  List<DomainEvent> get events => const [];

  @override
  MovementExecutionDelta get movementDelta => MovementExecutionDelta.empty;

  @override
  List<CombatAnimationFact> get combatAnimations => const [];

  final String reason;
}
