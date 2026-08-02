import 'package:aonw/game/application/ports/live_multiplayer_events.dart';
import 'package:aonw/game/application/services/live_snapshot_presentation_policy.dart';
import 'package:aonw_core/game/domain/state.dart';

LiveSnapshotPresentationDecision resolve(
  int previousOffset,
  LiveServerEvent? liveEvent,
  CanonicalGameSnapshot snapshot,
) {
  return LiveSnapshotPresentationPolicy.decide(
    previousOffset: previousOffset,
    eventOffset: liveEvent?.wire.offset,
    snapshotOffset: snapshot.eventLogOffset,
    snapshotAttached: liveEvent?.snapshot != null,
    movementExecutions: liveEvent?.movementExecutions ?? const [],
  );
}
