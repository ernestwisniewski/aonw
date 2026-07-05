import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

void main() {
  group('GamepadEventMapper', () {
    const mapper = GamepadEventMapper();

    test('maps stick button presses to directional HUD focus', () {
      final leftPressed = mapper.apply(
        GamepadInputSnapshot.empty,
        NormalizedGamepadEvent(
          gamepadId: 'pad',
          timestamp: 0,
          button: GamepadButton.leftStick,
          value: 1,
          rawEvent: _rawButtonEvent(value: 1),
        ),
      );
      final rightPressed = mapper.apply(
        GamepadInputSnapshot.empty,
        NormalizedGamepadEvent(
          gamepadId: 'pad',
          timestamp: 0,
          button: GamepadButton.rightStick,
          value: 1,
          rawEvent: _rawButtonEvent(value: 1),
        ),
      );
      final released = mapper.apply(
        leftPressed,
        NormalizedGamepadEvent(
          gamepadId: 'pad',
          timestamp: 0,
          button: GamepadButton.leftStick,
          value: 0,
          rawEvent: _rawButtonEvent(value: 0),
        ),
      );

      expect(leftPressed.hudFocusPrevious, isTrue);
      expect(leftPressed.hudFocusNext, isFalse);
      expect(rightPressed.hudFocusPrevious, isFalse);
      expect(rightPressed.hudFocusNext, isTrue);
      expect(released.hudFocusPrevious, isFalse);
    });
  });
}

GamepadEvent _rawButtonEvent({required double value}) {
  return GamepadEvent(
    gamepadId: 'pad',
    timestamp: 0,
    type: KeyType.button,
    key: 'stick',
    value: value,
  );
}
