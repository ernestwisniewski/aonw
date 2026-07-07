import 'package:aonw/game/presentation/input/gamepad/gamepad_control_settings.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input_snapshot.dart';
import 'package:gamepads/gamepads.dart';

final class GamepadEventMapper {
  const GamepadEventMapper({this.settings = GamepadControlSettings.defaults});

  final GamepadControlSettings settings;

  GamepadInputSnapshot apply(
    GamepadInputSnapshot snapshot,
    NormalizedGamepadEvent event,
  ) {
    if (!settings.enabled) return GamepadInputSnapshot.empty;
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
    final action = settings.axisBindings.actionFor(axis);
    if (action == null) return snapshot;
    return switch (action) {
      GamepadAxisAction.cursorX => snapshot.copyWith(cursorX: value),
      GamepadAxisAction.cursorY => snapshot.copyWith(cursorY: value),
      GamepadAxisAction.cameraX => snapshot.copyWith(cameraX: value),
      GamepadAxisAction.cameraY => snapshot.copyWith(
        cameraY: settings.invertCameraY ? -value : value,
      ),
      GamepadAxisAction.zoomIn => snapshot.copyWith(zoomIn: value),
      GamepadAxisAction.zoomOut => snapshot.copyWith(zoomOut: value),
    };
  }

  GamepadInputSnapshot _applyButton(
    GamepadInputSnapshot snapshot,
    GamepadButton button,
    bool pressed,
  ) {
    var next = snapshot;
    for (final action in settings.buttonBindings.actionsFor(button)) {
      next = _applyButtonAction(next, action, pressed);
    }
    return next;
  }

  GamepadInputSnapshot _applyButtonAction(
    GamepadInputSnapshot snapshot,
    GamepadButtonAction action,
    bool pressed,
  ) {
    return switch (action) {
      GamepadButtonAction.confirm => snapshot.copyWith(confirm: pressed),
      GamepadButtonAction.cancel => snapshot.copyWith(cancel: pressed),
      GamepadButtonAction.moveMode => snapshot.copyWith(moveMode: pressed),
      GamepadButtonAction.inspect => snapshot.copyWith(inspect: pressed),
      GamepadButtonAction.hudFocusPrevious => snapshot.copyWith(
        hudFocusPrevious: pressed,
      ),
      GamepadButtonAction.hudFocusNext => snapshot.copyWith(
        hudFocusNext: pressed,
      ),
      GamepadButtonAction.focusPrevious => snapshot.copyWith(
        focusPrevious: pressed,
      ),
      GamepadButtonAction.focusNext => snapshot.copyWith(focusNext: pressed),
      GamepadButtonAction.primaryAction => snapshot.copyWith(
        primaryAction: pressed,
      ),
      GamepadButtonAction.dpadUp => snapshot.copyWith(dpadUp: pressed),
      GamepadButtonAction.dpadDown => snapshot.copyWith(dpadDown: pressed),
      GamepadButtonAction.dpadLeft => snapshot.copyWith(dpadLeft: pressed),
      GamepadButtonAction.dpadRight => snapshot.copyWith(dpadRight: pressed),
      GamepadButtonAction.zoomIn => snapshot.copyWith(zoomIn: pressed ? 1 : 0),
      GamepadButtonAction.zoomOut => snapshot.copyWith(
        zoomOut: pressed ? 1 : 0,
      ),
    };
  }
}
