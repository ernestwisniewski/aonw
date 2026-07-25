import 'package:aonw/game/application/services/live_snapshot_presentation_policy.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveSnapshotPresentationPolicy', () {
    test('preserves exact attached evidence including null versus empty', () {
      final source = [_execution()];

      final exact = LiveSnapshotPresentationPolicy.decide(
        previousOffset: 4,
        eventOffset: 5,
        snapshotOffset: 5,
        snapshotAttached: true,
        movementExecutions: source,
      );
      final legacy = LiveSnapshotPresentationPolicy.decide(
        previousOffset: 4,
        eventOffset: 5,
        snapshotOffset: 5,
        snapshotAttached: true,
        movementExecutions: null,
      );
      final explicitEmpty = LiveSnapshotPresentationPolicy.decide(
        previousOffset: 4,
        eventOffset: 5,
        snapshotOffset: 5,
        snapshotAttached: true,
        movementExecutions: const [],
      );

      expect(exact.canPresentLiveTransition, isTrue);
      expect(exact.movementExecutions, same(source));
      expect(legacy.canPresentLiveTransition, isTrue);
      expect(legacy.movementExecutions, isNull);
      expect(explicitEmpty.canPresentLiveTransition, isTrue);
      expect(explicitEmpty.movementExecutions, isNotNull);
      expect(explicitEmpty.movementExecutions, isEmpty);
    });

    test('allows zero-offset compatibility only for attached snapshots', () {
      final source = [_execution()];

      final attached = LiveSnapshotPresentationPolicy.decide(
        previousOffset: 4,
        eventOffset: 5,
        snapshotOffset: 0,
        snapshotAttached: true,
        movementExecutions: source,
      );
      final reloaded = LiveSnapshotPresentationPolicy.decide(
        previousOffset: 4,
        eventOffset: 5,
        snapshotOffset: 0,
        snapshotAttached: false,
        movementExecutions: source,
      );

      expect(attached.canPresentLiveTransition, isTrue);
      expect(attached.movementExecutions, same(source));
      _expectSuppressed(reloaded);
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
  expect(decision.movementExecutions, isNotNull);
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
