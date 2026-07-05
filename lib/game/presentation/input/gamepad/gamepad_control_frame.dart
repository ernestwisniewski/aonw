import 'package:aonw/game/presentation/input/gamepad/gamepad_input_snapshot.dart';

final class GamepadControlFrame {
  const GamepadControlFrame({
    this.cursorStep,
    this.cameraX = 0,
    this.cameraY = 0,
    this.zoom = 0,
    this.confirmPressed = false,
    this.cancelPressed = false,
    this.inspectPressed = false,
    this.moveModePressed = false,
    this.hudFocusPressed = false,
    this.hudFocusPreviousPressed = false,
    this.hudFocusNextPressed = false,
    this.focusPreviousPressed = false,
    this.focusNextPressed = false,
    this.primaryActionPressed = false,
  });

  static const idle = GamepadControlFrame();

  final GamepadMapDirection? cursorStep;
  final double cameraX;
  final double cameraY;
  final double zoom;
  final bool confirmPressed;
  final bool cancelPressed;
  final bool inspectPressed;
  final bool moveModePressed;
  final bool hudFocusPressed;
  final bool hudFocusPreviousPressed;
  final bool hudFocusNextPressed;
  final bool focusPreviousPressed;
  final bool focusNextPressed;
  final bool primaryActionPressed;

  bool get isIdle =>
      cursorStep == null &&
      cameraX == 0 &&
      cameraY == 0 &&
      zoom == 0 &&
      !confirmPressed &&
      !cancelPressed &&
      !inspectPressed &&
      !moveModePressed &&
      !hudFocusPressed &&
      !hudFocusPreviousPressed &&
      !hudFocusNextPressed &&
      !focusPreviousPressed &&
      !focusNextPressed &&
      !primaryActionPressed;
}
