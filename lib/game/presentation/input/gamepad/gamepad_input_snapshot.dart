import 'package:freezed_annotation/freezed_annotation.dart';

part 'gamepad_input_snapshot.freezed.dart';

enum GamepadMapDirection { up, down, left, right }

@freezed
abstract class GamepadInputSnapshot with _$GamepadInputSnapshot {
  const GamepadInputSnapshot._();

  static const empty = GamepadInputSnapshot();

  const factory GamepadInputSnapshot({
    @Default(0) double cursorX,
    @Default(0) double cursorY,
    @Default(0) double cameraX,
    @Default(0) double cameraY,
    @Default(0) double zoomIn,
    @Default(0) double zoomOut,
    @Default(false) bool dpadUp,
    @Default(false) bool dpadDown,
    @Default(false) bool dpadLeft,
    @Default(false) bool dpadRight,
    @Default(false) bool confirm,
    @Default(false) bool cancel,
    @Default(false) bool inspect,
    @Default(false) bool moveMode,
    @Default(false) bool hudFocusPrevious,
    @Default(false) bool hudFocusNext,
    @Default(false) bool focusPrevious,
    @Default(false) bool focusNext,
    @Default(false) bool primaryAction,
  }) = _GamepadInputSnapshot;

  bool get isIdle => this == empty;

  double get zoom => zoomIn - zoomOut;
}
