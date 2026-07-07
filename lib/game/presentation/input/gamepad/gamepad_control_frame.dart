import 'package:aonw/game/presentation/input/gamepad/gamepad_input_snapshot.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'gamepad_control_frame.freezed.dart';

@freezed
abstract class GamepadControlFrame with _$GamepadControlFrame {
  const GamepadControlFrame._();

  static const idle = GamepadControlFrame();

  const factory GamepadControlFrame({
    GamepadMapDirection? cursorStep,
    @Default(0) double cameraX,
    @Default(0) double cameraY,
    @Default(0) double zoom,
    @Default(false) bool confirmPressed,
    @Default(false) bool cancelPressed,
    @Default(false) bool inspectPressed,
    @Default(false) bool moveModePressed,
    @Default(false) bool hudFocusPreviousPressed,
    @Default(false) bool hudFocusNextPressed,
    @Default(false) bool focusPreviousPressed,
    @Default(false) bool focusNextPressed,
    @Default(false) bool primaryActionPressed,
  }) = _GamepadControlFrame;

  bool get isIdle =>
      cursorStep == null &&
      cameraX == 0 &&
      cameraY == 0 &&
      zoom == 0 &&
      !confirmPressed &&
      !cancelPressed &&
      !inspectPressed &&
      !moveModePressed &&
      !hudFocusPreviousPressed &&
      !hudFocusNextPressed &&
      !focusPreviousPressed &&
      !focusNextPressed &&
      !primaryActionPressed;
}
