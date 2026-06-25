import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_camera_effect_normalizer.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameCameraEffectNormalizer', () {
    test('smooths turn-start command camera jumps', () {
      final effects = GameCameraEffectNormalizer.forCommand(
        command: const FocusTurnStartActionCommand('player_1'),
        effects: const [JumpCameraEffect(col: 2, row: 3)],
      );

      final camera = effects.single as SmoothCameraEffect;
      expect(camera.col, 2);
      expect(camera.row, 3);
      expect(
        camera.duration,
        GameCameraEffectNormalizer.turnStartCameraTransitionDuration,
      );
    });

    test('smooths next-action command camera jumps', () {
      final effects = GameCameraEffectNormalizer.forCommand(
        command: const FocusNextPendingActionCommand('player_1'),
        effects: const [JumpCameraEffect(col: 4, row: 5)],
      );

      final camera = effects.single as SmoothCameraEffect;
      expect(camera.col, 4);
      expect(camera.row, 5);
      expect(camera.duration, 0.48);
    });

    test('keeps non-focus command effects untouched', () {
      const effect = JumpCameraEffect(col: 1, row: 1);

      final effects = GameCameraEffectNormalizer.forCommand(
        command: const SkipUnitTurnCommand('unit_1'),
        effects: const [effect],
      );

      expect(effects.single, same(effect));
    });

    test('smooths hidden turn-advance camera jumps', () {
      final effects = GameCameraEffectNormalizer.forTurnAdvance(
        effects: const [
          JumpCameraEffect(col: 7, row: 8),
          ShowFloatingTextEffect(
            text: 'turn',
            col: 7,
            row: 8,
            colorValue: 0xFFFFFFFF,
          ),
        ],
      );

      final camera = effects.first as SmoothCameraEffect;
      expect(camera.col, 7);
      expect(camera.row, 8);
      expect(
        camera.duration,
        GameCameraEffectNormalizer.turnStartCameraTransitionDuration,
      );
      expect(effects.last, isA<ShowFloatingTextEffect>());
    });
  });
}
