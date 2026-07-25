import 'package:aonw_core/game/domain/movement.dart';

final class LiveSnapshotPresentationDecision {
  const LiveSnapshotPresentationDecision({
    required this.canPresentLiveTransition,
    required this.movementExecutions,
  });

  final bool canPresentLiveTransition;
  final List<MovementCommandExecution>? movementExecutions;

  bool get inferDirectMoves =>
      canPresentLiveTransition && movementExecutions == null;
}

abstract final class LiveSnapshotPresentationPolicy {
  static const _suppressed = LiveSnapshotPresentationDecision(
    canPresentLiveTransition: false,
    movementExecutions: <MovementCommandExecution>[],
  );

  static LiveSnapshotPresentationDecision decide({
    required int previousOffset,
    required int? eventOffset,
    required int snapshotOffset,
    required bool snapshotAttached,
    required List<MovementCommandExecution>? movementExecutions,
  }) {
    final isNextEvent = eventOffset == previousOffset + 1;
    final snapshotMatchesEvent =
        snapshotAttached &&
        (snapshotOffset == eventOffset || snapshotOffset == 0);
    if (!isNextEvent || !snapshotMatchesEvent) return _suppressed;
    return LiveSnapshotPresentationDecision(
      canPresentLiveTransition: true,
      movementExecutions: movementExecutions,
    );
  }
}
