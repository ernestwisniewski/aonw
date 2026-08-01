import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/state/game_snapshot_metadata.dart';

export 'package:aonw_core/game/domain/state/domain_state.dart'
    show DomainActionState;

/// Neutral snapshot envelope composed of independent state boundaries.
final class CanonicalGameSnapshot {
  factory CanonicalGameSnapshot.snapshot({
    required DomainState domain,
    required GameSnapshotMetadata metadata,
    int eventLogOffset = 0,
  }) {
    if (eventLogOffset < 0) {
      throw ArgumentError.value(
        eventLogOffset,
        'eventLogOffset',
        'Must not be negative',
      );
    }
    return CanonicalGameSnapshot._owned(
      domain: domain,
      metadata: metadata,
      eventLogOffset: eventLogOffset,
    );
  }

  const CanonicalGameSnapshot._owned({
    required this.domain,
    required this.metadata,
    required this.eventLogOffset,
  });

  final DomainState domain;
  final GameSnapshotMetadata metadata;
  final int eventLogOffset;

  CanonicalGameSnapshot copyWith({
    DomainState? domain,
    DomainActionState? actions,
    GameSnapshotMetadata? metadata,
    int? eventLogOffset,
  }) {
    return CanonicalGameSnapshot.snapshot(
      domain: actions == null
          ? domain ?? this.domain
          : (domain ?? this.domain).copyWith(actions: actions),
      metadata: metadata ?? this.metadata,
      eventLogOffset: eventLogOffset ?? this.eventLogOffset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanonicalGameSnapshot &&
          other.domain == domain &&
          other.metadata == metadata &&
          other.eventLogOffset == eventLogOffset;

  @override
  int get hashCode => Object.hash(domain, metadata, eventLogOffset);
}
