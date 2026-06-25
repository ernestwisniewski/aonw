import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_renderer_effect_sequence_builder.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameRendererEffectSequenceBuilder', () {
    test('preserves command effects before event-derived effects', () {
      final effects = GameRendererEffectSequenceBuilder.build(
        commandEffects: const [
          ShowFloatingTextEffect(
            text: 'queued',
            col: 2,
            row: 3,
            colorValue: 0xFFFFFFFF,
          ),
        ],
        events: const [
          UnitMovedEvent(
            unitId: 'warrior_1',
            fromCol: 2,
            fromRow: 3,
            toCol: 3,
            toRow: 3,
          ),
        ],
        state: const GameState(),
      );

      expect(effects, hasLength(2));
      expect(effects.first, isA<ShowFloatingTextEffect>());
      expect(effects.last, isA<AnimateUnitMoveEffect>());
    });

    test(
      'skips duplicate event movement when command already animates unit',
      () {
        const commandMove = AnimateUnitMoveEffect(
          unitId: 'warrior_1',
          fromCol: 2,
          fromRow: 3,
          steps: [
            UnitMovementStep(col: 3, row: 3, enterCost: 1, cumulativeCost: 1),
          ],
        );

        final effects = GameRendererEffectSequenceBuilder.build(
          commandEffects: const [commandMove],
          events: const [
            UnitMovedEvent(
              unitId: 'warrior_1',
              fromCol: 2,
              fromRow: 3,
              toCol: 3,
              toRow: 3,
            ),
          ],
          state: const GameState(),
        );

        expect(effects, const [commandMove]);
      },
    );

    test('keeps event movement for units not already animated by command', () {
      const commandMove = AnimateUnitMoveEffect(
        unitId: 'warrior_1',
        fromCol: 2,
        fromRow: 3,
        steps: [
          UnitMovementStep(col: 3, row: 3, enterCost: 1, cumulativeCost: 1),
        ],
      );

      final effects = GameRendererEffectSequenceBuilder.build(
        commandEffects: const [commandMove],
        events: const [
          UnitMovedEvent(
            unitId: 'scout_1',
            fromCol: 4,
            fromRow: 3,
            toCol: 5,
            toRow: 3,
          ),
        ],
        state: const GameState(),
      );

      expect(effects, hasLength(2));
      expect((effects.last as AnimateUnitMoveEffect).unitId, 'scout_1');
    });
  });
}
