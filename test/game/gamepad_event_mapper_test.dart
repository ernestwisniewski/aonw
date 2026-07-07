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

    test('uses remapped button bindings', () {
      final mapper = GamepadEventMapper(
        settings: GamepadControlSettings.defaults.copyWith(
          buttonBindings: GamepadButtonBindings.defaults.bind(
            GamepadButtonAction.confirm,
            GamepadButton.y,
          ),
        ),
      );

      final snapshot = mapper.apply(
        GamepadInputSnapshot.empty,
        NormalizedGamepadEvent(
          gamepadId: 'pad',
          timestamp: 0,
          button: GamepadButton.y,
          value: 1,
          rawEvent: _rawButtonEvent(value: 1),
        ),
      );

      expect(snapshot.confirm, isTrue);
      expect(snapshot.inspect, isFalse);
    });

    test('uses remapped and inverted axis bindings', () {
      final mapper = GamepadEventMapper(
        settings: GamepadControlSettings.defaults.copyWith(
          invertCameraY: true,
          axisBindings: GamepadAxisBindings.defaults.bind(
            GamepadAxisAction.cameraY,
            GamepadAxis.leftStickY,
          ),
        ),
      );

      final snapshot = mapper.apply(
        GamepadInputSnapshot.empty,
        NormalizedGamepadEvent(
          gamepadId: 'pad',
          timestamp: 0,
          axis: GamepadAxis.leftStickY,
          value: 0.5,
          rawEvent: _rawAxisEvent(value: 0.5),
        ),
      );

      expect(snapshot.cameraY, -0.5);
      expect(snapshot.cursorY, 0);
    });

    test('clears input while gamepad is disabled', () {
      final mapper = GamepadEventMapper(
        settings: GamepadControlSettings.defaults.copyWith(enabled: false),
      );

      final snapshot = mapper.apply(
        const GamepadInputSnapshot(confirm: true),
        NormalizedGamepadEvent(
          gamepadId: 'pad',
          timestamp: 0,
          button: GamepadButton.a,
          value: 1,
          rawEvent: _rawButtonEvent(value: 1),
        ),
      );

      expect(snapshot, GamepadInputSnapshot.empty);
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

GamepadEvent _rawAxisEvent({required double value}) {
  return GamepadEvent(
    gamepadId: 'pad',
    timestamp: 0,
    type: KeyType.analog,
    key: 'axis',
    value: value,
  );
}
