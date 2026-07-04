import 'package:aonw/game/presentation/input/gamepad/gamepad_input_snapshot.dart';
import 'package:gamepads/gamepads.dart';

final class GamepadEventMapper {
  const GamepadEventMapper();

  GamepadInputSnapshot apply(
    GamepadInputSnapshot snapshot,
    NormalizedGamepadEvent event,
  ) {
    final axis = event.axis;
    if (axis != null) return _applyAxis(snapshot, axis, event.value);

    final button = event.button;
    if (button != null) return _applyButton(snapshot, button, event.value != 0);
    return snapshot;
  }

  GamepadInputSnapshot _applyAxis(
    GamepadInputSnapshot snapshot,
    GamepadAxis axis,
    double value,
  ) {
    return switch (axis) {
      GamepadAxis.leftStickX => snapshot.copyWith(cursorX: value),
      GamepadAxis.leftStickY => snapshot.copyWith(cursorY: value),
      GamepadAxis.rightStickX => snapshot.copyWith(cameraX: value),
      GamepadAxis.rightStickY => snapshot.copyWith(cameraY: value),
      GamepadAxis.rightTrigger => snapshot.copyWith(zoomIn: value),
      GamepadAxis.leftTrigger => snapshot.copyWith(zoomOut: value),
    };
  }

  GamepadInputSnapshot _applyButton(
    GamepadInputSnapshot snapshot,
    GamepadButton button,
    bool pressed,
  ) {
    return switch (button) {
      GamepadButton.a => snapshot.copyWith(confirm: pressed),
      GamepadButton.b ||
      GamepadButton.back => snapshot.copyWith(cancel: pressed),
      GamepadButton.x => snapshot.copyWith(moveMode: pressed),
      GamepadButton.y => snapshot.copyWith(inspect: pressed),
      GamepadButton.leftBumper => snapshot.copyWith(focusPrevious: pressed),
      GamepadButton.rightBumper => snapshot.copyWith(focusNext: pressed),
      GamepadButton.start => snapshot.copyWith(primaryAction: pressed),
      GamepadButton.dpadUp => snapshot.copyWith(dpadUp: pressed),
      GamepadButton.dpadDown => snapshot.copyWith(dpadDown: pressed),
      GamepadButton.dpadLeft => snapshot.copyWith(dpadLeft: pressed),
      GamepadButton.dpadRight => snapshot.copyWith(dpadRight: pressed),
      GamepadButton.rightTrigger => snapshot.copyWith(zoomIn: pressed ? 1 : 0),
      GamepadButton.leftTrigger => snapshot.copyWith(zoomOut: pressed ? 1 : 0),
      GamepadButton.home ||
      GamepadButton.leftStick ||
      GamepadButton.rightStick ||
      GamepadButton.touchpad => snapshot,
    };
  }
}
