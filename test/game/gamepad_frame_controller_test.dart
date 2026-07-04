import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GamepadFrameController', () {
    test('applies deadzone and rescales analog camera and zoom input', () {
      final controller = GamepadFrameController(deadzone: 0.25);

      final idle = controller.advance(
        input: const GamepadInputSnapshot(cameraX: 0.2, zoomIn: 0.2),
        dt: 0.016,
      );
      expect(idle.cameraX, 0);
      expect(idle.zoom, 0);

      final active = controller.advance(
        input: const GamepadInputSnapshot(cameraX: 1, zoomIn: 1),
        dt: 0.016,
      );
      expect(active.cameraX, 1);
      expect(active.zoom, 1);
    });

    test('emits cursor step immediately and then at repeat cadence', () {
      final controller = GamepadFrameController(
        initialRepeatDelay: 0.3,
        repeatInterval: 0.1,
      );
      const input = GamepadInputSnapshot(dpadRight: true);

      expect(
        controller.advance(input: input, dt: 0.016).cursorStep,
        GamepadMapDirection.right,
      );
      expect(controller.advance(input: input, dt: 0.1).cursorStep, isNull);
      expect(
        controller.advance(input: input, dt: 0.21).cursorStep,
        GamepadMapDirection.right,
      );
    });

    test('fires face button actions only on press edges', () {
      final controller = GamepadFrameController();
      const pressed = GamepadInputSnapshot(confirm: true);

      expect(
        controller.advance(input: pressed, dt: 0.016).confirmPressed,
        isTrue,
      );
      expect(
        controller.advance(input: pressed, dt: 0.016).confirmPressed,
        isFalse,
      );
      expect(
        controller
            .advance(input: GamepadInputSnapshot.empty, dt: 0.016)
            .confirmPressed,
        isFalse,
      );
      expect(
        controller.advance(input: pressed, dt: 0.016).confirmPressed,
        isTrue,
      );
    });

    test('uses D-pad before left stick and treats stick up as map up', () {
      final controller = GamepadFrameController(deadzone: 0.25);

      expect(
        controller
            .advance(
              input: const GamepadInputSnapshot(cursorX: 0.95, dpadUp: true),
              dt: 0.016,
            )
            .cursorStep,
        GamepadMapDirection.up,
      );

      final stickController = GamepadFrameController(deadzone: 0.25);
      expect(
        stickController
            .advance(
              input: const GamepadInputSnapshot(cursorY: 0.95),
              dt: 0.016,
            )
            .cursorStep,
        GamepadMapDirection.up,
      );
    });
  });
}
