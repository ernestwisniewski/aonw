import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';

/// State-container-neutral outcome of applying one engine command.
sealed class GameEngineResult {
  const GameEngineResult();

  factory GameEngineResult.accepted({
    required CanonicalGameSnapshot snapshot,
    List<DomainEvent> events = const [],
  }) {
    return GameEngineAccepted._(
      snapshot: snapshot,
      events: events.isEmpty
          ? const []
          : List<DomainEvent>.unmodifiable(events),
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
}

/// Accepted transition with its next snapshot and ordered domain facts.
final class GameEngineAccepted extends GameEngineResult {
  const GameEngineAccepted._({required this.snapshot, required this.events});

  @override
  final CanonicalGameSnapshot snapshot;

  @override
  final List<DomainEvent> events;
}

/// Rejected transition. The snapshot is the unchanged input snapshot.
final class GameEngineRejected extends GameEngineResult {
  const GameEngineRejected._({required this.snapshot, required this.reason});

  @override
  final CanonicalGameSnapshot snapshot;

  @override
  List<DomainEvent> get events => const [];

  final String reason;
}
