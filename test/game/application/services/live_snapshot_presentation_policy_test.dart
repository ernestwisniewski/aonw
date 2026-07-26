import 'package:aonw/game/application/services/live_snapshot_presentation_policy.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveSnapshotPresentationPolicy', () {
    test('preserves exact attached full and empty evidence', () {
      final source = [_execution()];

      final full = LiveSnapshotPresentationPolicy.decide(
        previousOffset: 4,
        eventOffset: 5,
        snapshotOffset: 5,
        snapshotAttached: true,
        movementExecutions: source,
      );
      final explicitEmpty = LiveSnapshotPresentationPolicy.decide(
        previousOffset: 4,
        eventOffset: 5,
        snapshotOffset: 5,
        snapshotAttached: true,
        movementExecutions: const [],
      );

      expect(full.canPresentLiveTransition, isTrue);
      expect(full.movementExecutions, same(source));
      expect(explicitEmpty.canPresentLiveTransition, isTrue);
      expect(explicitEmpty.movementExecutions, isEmpty);
    });

    test('requires the attached snapshot offset to equal the event offset', () {
      final source = [_execution()];

      final mismatchedZero = LiveSnapshotPresentationPolicy.decide(
        previousOffset: 4,
        eventOffset: 5,
        snapshotOffset: 0,
        snapshotAttached: true,
        movementExecutions: source,
      );
      final equalZero = LiveSnapshotPresentationPolicy.decide(
        previousOffset: -1,
        eventOffset: 0,
        snapshotOffset: 0,
        snapshotAttached: true,
        movementExecutions: source,
      );

      _expectSuppressed(mismatchedZero);
      expect(equalZero.canPresentLiveTransition, isTrue);
      expect(equalZero.movementExecutions, same(source));
    });

    for (final unsafe in const [
      (
        name: 'snapshot-only resync',
        previousOffset: 4,
        eventOffset: null,
        snapshotOffset: 5,
        snapshotAttached: false,
      ),
      (
        name: 'event offset gap',
        previousOffset: 2,
        eventOffset: 5,
        snapshotOffset: 5,
        snapshotAttached: true,
      ),
      (
        name: 'snapshot ahead of event',
        previousOffset: 4,
        eventOffset: 5,
        snapshotOffset: 6,
        snapshotAttached: true,
      ),
      (
        name: 'snapshot behind event',
        previousOffset: 4,
        eventOffset: 5,
        snapshotOffset: 4,
        snapshotAttached: true,
      ),
      (
        name: 'reloaded snapshot',
        previousOffset: 4,
        eventOffset: 5,
        snapshotOffset: 5,
        snapshotAttached: false,
      ),
      (
        name: 'duplicate event',
        previousOffset: 5,
        eventOffset: 5,
        snapshotOffset: 6,
        snapshotAttached: true,
      ),
      (
        name: 'out-of-order event',
        previousOffset: 5,
        eventOffset: 4,
        snapshotOffset: 6,
        snapshotAttached: true,
      ),
    ]) {
      test('${unsafe.name} returns authoritative empty', () {
        final decision = LiveSnapshotPresentationPolicy.decide(
          previousOffset: unsafe.previousOffset,
          eventOffset: unsafe.eventOffset,
          snapshotOffset: unsafe.snapshotOffset,
          snapshotAttached: unsafe.snapshotAttached,
          movementExecutions: [_execution()],
        );

        _expectSuppressed(decision);
      });
    }
  });
}

void _expectSuppressed(LiveSnapshotPresentationDecision decision) {
  expect(decision.canPresentLiveTransition, isFalse);
  expect(decision.movementExecutions, isEmpty);
}

MovementCommandExecution _execution() {
  return MovementCommandExecution(
    unitId: 'unit_a',
    fromCol: 0,
    fromRow: 0,
    steps: const [
      UnitMovementStep(col: 1, row: 0, enterCost: 7, cumulativeCost: 7),
    ],
  );
}
