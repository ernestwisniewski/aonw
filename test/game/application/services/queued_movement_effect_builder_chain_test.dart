import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QueuedMovementEffectBuilder authoritative chains', () {
    test('keeps valid A1 B1 A2 effects in global execution order', () {
      final fixture = _movementChainFixture();

      final effects = QueuedMovementEffectBuilder.fromExecutions(
        fixture.executions,
        beforeUnits: fixture.beforeUnits,
        afterUnits: fixture.afterUnits,
      );

      expect(_effectSnapshots(effects), const [
        'unit-a:0,0->1,0:1/1',
        'unit-b:0,1->1,1:1/1',
        'unit-a:1,0->2,0:1/1|3,0:1/2',
      ]);
      expect(effects[0].steps, same(fixture.executions[0].steps));
      expect(effects[2].steps, same(fixture.executions[2].steps));
    });

    test('suppresses the whole chain with a wrong first origin', () {
      final fixture = _movementChainFixture();
      final executions = [
        _execution('unit-a', fromCol: 9, fromRow: 0, steps: const [(1, 0)]),
        fixture.executions[1],
        fixture.executions[2],
      ];

      final effects = QueuedMovementEffectBuilder.fromExecutions(
        executions,
        beforeUnits: fixture.beforeUnits,
        afterUnits: fixture.afterUnits,
      );

      expect(_effectSnapshots(effects), const ['unit-b:0,1->1,1:1/1']);
    });

    test('suppresses non-adjacent A segments and retains B in place', () {
      final fixture = _movementChainFixture();
      final executions = [
        fixture.executions[0],
        fixture.executions[1],
        _execution('unit-a', fromCol: 2, fromRow: 0, steps: const [(3, 0)]),
      ];

      final effects = QueuedMovementEffectBuilder.fromExecutions(
        executions,
        beforeUnits: fixture.beforeUnits,
        afterUnits: fixture.afterUnits,
      );

      expect(_effectSnapshots(effects), const ['unit-b:0,1->1,1:1/1']);
    });

    test('suppresses a chain whose final destination misses next state', () {
      final fixture = _movementChainFixture(
        afterA: _unit('unit-a', col: 4, row: 0),
      );

      final effects = QueuedMovementEffectBuilder.fromExecutions(
        fixture.executions,
        beforeUnits: fixture.beforeUnits,
        afterUnits: fixture.afterUnits,
      );

      expect(_effectSnapshots(effects), const ['unit-b:0,1->1,1:1/1']);
    });

    test('suppresses a unit missing from either state', () {
      final fixture = _movementChainFixture();

      for (final (beforeUnits, afterUnits) in [
        ([fixture.beforeUnits[1]], fixture.afterUnits),
        (fixture.beforeUnits, [fixture.afterUnits[1]]),
      ]) {
        final effects = QueuedMovementEffectBuilder.fromExecutions(
          fixture.executions,
          beforeUnits: beforeUnits,
          afterUnits: afterUnits,
        );

        expect(_effectSnapshots(effects), const ['unit-b:0,1->1,1:1/1']);
      }
    });

    test('suppresses duplicate or ownership-transferred unit identities', () {
      final fixture = _movementChainFixture();

      for (final (beforeUnits, afterUnits) in [
        (
          [...fixture.beforeUnits, _unit('unit-a', col: 9, row: 0)],
          fixture.afterUnits,
        ),
        (
          fixture.beforeUnits,
          [
            _unit('unit-a', col: 3, row: 0, ownerPlayerId: 'player-2'),
            fixture.afterUnits[1],
          ],
        ),
      ]) {
        final effects = QueuedMovementEffectBuilder.fromExecutions(
          fixture.executions,
          beforeUnits: beforeUnits,
          afterUnits: afterUnits,
        );

        expect(_effectSnapshots(effects), const ['unit-b:0,1->1,1:1/1']);
      }
    });

    test('requires both validation snapshots or neither', () {
      final fixture = _movementChainFixture();

      expect(
        () => QueuedMovementEffectBuilder.fromExecutions(
          fixture.executions,
          beforeUnits: fixture.beforeUnits,
        ),
        throwsArgumentError,
      );
      expect(
        () => QueuedMovementEffectBuilder.fromExecutions(
          fixture.executions,
          afterUnits: fixture.afterUnits,
        ),
        throwsArgumentError,
      );
      expect(
        _effectSnapshots(
          QueuedMovementEffectBuilder.fromExecutions(fixture.executions),
        ),
        const [
          'unit-a:0,0->1,0:1/1',
          'unit-b:0,1->1,1:1/1',
          'unit-a:1,0->2,0:1/1|3,0:1/2',
        ],
      );
    });
  });

  test('legacy queued movement accepts an authoritative path prefix', () {
    final before =
        GameUnit.produced(
          id: 'queued-unit',
          ownerPlayerId: 'player-1',
          type: GameUnitType.warrior,
          col: 0,
          row: 0,
        ).copyWithQueuedPath(
          QueuedMovePath(
            targetCol: 3,
            targetRow: 0,
            steps: const [
              UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
              UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
              UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
              UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 3),
            ],
          ),
        );
    final after = before.copyWith(col: 2, row: 0, movementPoints: 0);

    final effects = QueuedMovementEffectBuilder.fromUnitDelta(
      beforeUnits: [before],
      afterUnits: [after],
    );

    expect(_effectSnapshots(effects), const [
      'queued-unit:0,0->1,0:1/1|2,0:1/2',
    ]);
  });
}

({
  List<GameUnit> beforeUnits,
  List<GameUnit> afterUnits,
  List<MovementCommandExecution> executions,
})
_movementChainFixture({GameUnit? afterA}) {
  return (
    beforeUnits: [
      _unit('unit-a', col: 0, row: 0),
      _unit('unit-b', col: 0, row: 1),
    ],
    afterUnits: [
      afterA ?? _unit('unit-a', col: 3, row: 0),
      _unit('unit-b', col: 1, row: 1),
    ],
    executions: [
      _execution('unit-a', fromCol: 0, fromRow: 0, steps: const [(1, 0)]),
      _execution('unit-b', fromCol: 0, fromRow: 1, steps: const [(1, 1)]),
      _execution(
        'unit-a',
        fromCol: 1,
        fromRow: 0,
        steps: const [(2, 0), (3, 0)],
      ),
    ],
  );
}

GameUnit _unit(
  String id, {
  required int col,
  required int row,
  String ownerPlayerId = 'player-1',
}) {
  return GameUnit.produced(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.scout,
    col: col,
    row: row,
  );
}

MovementCommandExecution _execution(
  String unitId, {
  required int fromCol,
  required int fromRow,
  required List<(int, int)> steps,
}) {
  return MovementCommandExecution(
    unitId: unitId,
    fromCol: fromCol,
    fromRow: fromRow,
    steps: [
      for (var index = 0; index < steps.length; index++)
        UnitMovementStep(
          col: steps[index].$1,
          row: steps[index].$2,
          enterCost: 1,
          cumulativeCost: index + 1,
        ),
    ],
  );
}

List<String> _effectSnapshots(Iterable<AnimateUnitMoveEffect> effects) {
  return [
    for (final effect in effects)
      '${effect.unitId}:${effect.fromCol},${effect.fromRow}->'
          '${effect.steps.map((step) => '${step.col},${step.row}:'
              '${step.enterCost}/${step.cumulativeCost}').join('|')}',
  ];
}
