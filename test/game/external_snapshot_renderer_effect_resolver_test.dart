import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/providers/game/external_snapshot_renderer_effect_resolver.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExternalSnapshotRendererEffectResolver', () {
    test('preserves exact A1 B1 A2 order and suppresses event duplicates', () {
      final before = _state(aCol: 0, bCol: 0);
      final after = _state(aCol: 2, bCol: 1);

      final effects = ExternalSnapshotRendererEffectResolver.resolve(
        previousState: before,
        nextState: after,
        events: const [
          UnitMovedEvent(
            unitId: 'unit_a',
            fromCol: 0,
            fromRow: 0,
            toCol: 2,
            toRow: 0,
          ),
          UnitMovedEvent(
            unitId: 'unit_b',
            fromCol: 0,
            fromRow: 1,
            toCol: 1,
            toRow: 1,
          ),
        ],
        movementExecutions: _exactExecutions(),
      );

      expect(effects.whereType<AnimateUnitMoveEffect>().map(_snapshot), const [
        ('unit_a', 0, 0, 1, 0, 7, 7),
        ('unit_b', 0, 1, 1, 1, 11, 11),
        ('unit_a', 1, 0, 2, 0, 13, 20),
      ]);
      expect(effects.clear, throwsUnsupportedError);
    });

    test('empty evidence does not repeat UnitMovedEvent animation', () {
      final effects = ExternalSnapshotRendererEffectResolver.resolve(
        previousState: _state(aCol: 0),
        nextState: _state(aCol: 2),
        events: const [
          UnitMovedEvent(
            unitId: 'unit_a',
            fromCol: 0,
            fromRow: 0,
            toCol: 2,
            toRow: 0,
          ),
        ],
        movementExecutions: const [],
      );

      expect(effects.whereType<AnimateUnitMoveEffect>(), isEmpty);
    });

    test('empty evidence never infers movement from the state delta', () {
      final effects = ExternalSnapshotRendererEffectResolver.resolve(
        previousState: _state(aCol: 0),
        nextState: _state(aCol: 2),
        events: const [],
        movementExecutions: const [],
      );

      expect(effects.whereType<AnimateUnitMoveEffect>(), isEmpty);
    });

    for (final invalid in [
      [
        _execution('unit_a', 9, 0, 1, 0, 7, 7),
        _execution('unit_a', 1, 0, 2, 0, 13, 20),
      ],
      [
        _execution('unit_a', 0, 0, 1, 0, 7, 7),
        _execution('unit_a', 9, 0, 2, 0, 13, 20),
      ],
      [_execution('unit_a', 0, 0, 1, 0, 7, 7)],
    ]) {
      test('invalid chain cannot fall back through UnitMovedEvent', () {
        final effects = ExternalSnapshotRendererEffectResolver.resolve(
          previousState: _state(aCol: 0),
          nextState: _state(aCol: 2),
          events: const [
            UnitMovedEvent(
              unitId: 'unit_a',
              fromCol: 0,
              fromRow: 0,
              toCol: 2,
              toRow: 0,
            ),
          ],
          movementExecutions: invalid,
        );

        expect(effects.whereType<AnimateUnitMoveEffect>(), isEmpty);
      });
    }
  });
}

GameState _state({required int aCol, int? bCol}) {
  return GameState(
    units: [
      GameUnit.produced(
        id: 'unit_a',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: aCol,
        row: 0,
      ),
      if (bCol != null)
        GameUnit.produced(
          id: 'unit_b',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: bCol,
          row: 1,
        ),
    ],
    activePlayerId: 'player_1',
    activePlayerCanAct: true,
  );
}

List<MovementCommandExecution> _exactExecutions() {
  return [
    _execution('unit_a', 0, 0, 1, 0, 7, 7),
    _execution('unit_b', 0, 1, 1, 1, 11, 11),
    _execution('unit_a', 1, 0, 2, 0, 13, 20),
  ];
}

MovementCommandExecution _execution(
  String unitId,
  int fromCol,
  int fromRow,
  int toCol,
  int toRow,
  int enterCost,
  int cumulativeCost,
) {
  return MovementCommandExecution(
    unitId: unitId,
    fromCol: fromCol,
    fromRow: fromRow,
    steps: [
      UnitMovementStep(
        col: toCol,
        row: toRow,
        enterCost: enterCost,
        cumulativeCost: cumulativeCost,
      ),
    ],
  );
}

typedef _MovementSnapshot = (String, int, int, int, int, int, int);

_MovementSnapshot _snapshot(AnimateUnitMoveEffect effect) {
  final step = effect.steps.single;
  return (
    effect.unitId,
    effect.fromCol,
    effect.fromRow,
    step.col,
    step.row,
    step.enterCost,
    step.cumulativeCost,
  );
}
