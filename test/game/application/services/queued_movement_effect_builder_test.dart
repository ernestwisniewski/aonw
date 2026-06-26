import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QueuedMovementEffectBuilder', () {
    test('emits an animation effect for auto-exploring scout movement', () {
      final before = GameUnit.produced(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        col: 1,
        row: 1,
      ).copyWithPosture(UnitPosture.autoExploring);
      final after = before.copyWith(col: 2, row: 1, movementPoints: 1);

      final effects = QueuedMovementEffectBuilder.fromUnitDelta(
        beforeUnits: [before],
        afterUnits: [after],
      );

      expect(
        effects.single,
        isA<AnimateUnitMoveEffect>()
            .having((effect) => effect.unitId, 'unitId', 'scout_1')
            .having((effect) => effect.fromCol, 'fromCol', 1)
            .having((effect) => effect.fromRow, 'fromRow', 1)
            .having((effect) => effect.steps.single.col, 'step col', 2)
            .having((effect) => effect.steps.single.row, 'step row', 1),
      );
    });

    test('emits an animation effect for merchant trade route movement', () {
      final before =
          GameUnit.produced(
            id: 'merchant_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.merchant,
            col: 0,
            row: 0,
          ).copyWithMerchantTradeRoute(
            MerchantTradeRoute(
              originCityId: 'city_origin',
              destinationCityId: 'city_target',
              steps: const [
                UnitMovementStep(
                  col: 0,
                  row: 0,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
                UnitMovementStep(
                  col: 2,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 2,
                ),
                UnitMovementStep(
                  col: 3,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 3,
                ),
              ],
            ),
          );
      final after = before
          .copyWith(col: 3, row: 0, movementPoints: 0)
          .copyWithMerchantTradeRoute(
            MerchantTradeRoute(
              originCityId: 'city_target',
              destinationCityId: 'city_origin',
              steps: const [
                UnitMovementStep(
                  col: 3,
                  row: 0,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
                UnitMovementStep(
                  col: 2,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 2,
                ),
                UnitMovementStep(
                  col: 0,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 3,
                ),
              ],
            ),
          );

      final effects = QueuedMovementEffectBuilder.fromUnitDelta(
        beforeUnits: [before],
        afterUnits: [after],
      );

      expect(
        effects.single,
        isA<AnimateUnitMoveEffect>()
            .having((effect) => effect.unitId, 'unitId', 'merchant_1')
            .having((effect) => effect.fromCol, 'fromCol', 0)
            .having((effect) => effect.fromRow, 'fromRow', 0)
            .having(
              (effect) => effect.steps.map((step) => step.col),
              'step cols',
              [1, 2, 3],
            ),
      );
    });

    test('emits an animation effect for merchant queued city travel', () {
      final before =
          GameUnit.produced(
            id: 'merchant_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.merchant,
            col: 1,
            row: 0,
          ).copyWithQueuedPath(
            QueuedMovePath(
              targetCol: 3,
              targetRow: 0,
              steps: const [
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
                UnitMovementStep(
                  col: 2,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
                UnitMovementStep(
                  col: 3,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 2,
                ),
              ],
            ),
          );
      final after = before
          .copyWith(col: 3, row: 0, movementPoints: 1)
          .copyWithQueuedPath(null);

      final effects = QueuedMovementEffectBuilder.fromUnitDelta(
        beforeUnits: [before],
        afterUnits: [after],
      );

      expect(
        effects.single,
        isA<AnimateUnitMoveEffect>()
            .having((effect) => effect.unitId, 'unitId', 'merchant_1')
            .having((effect) => effect.fromCol, 'fromCol', 1)
            .having(
              (effect) => effect.steps.map((step) => step.col),
              'step cols',
              [2, 3],
            ),
      );
    });

    test(
      'ignores ordinary movement deltas without queued or auto movement',
      () {
        final before = GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 1,
        );
        final after = before.copyWith(col: 2, row: 1, movementPoints: 1);

        final effects = QueuedMovementEffectBuilder.fromUnitDelta(
          beforeUnits: [before],
          afterUnits: [after],
        );

        expect(effects, isEmpty);
      },
    );
  });
}
