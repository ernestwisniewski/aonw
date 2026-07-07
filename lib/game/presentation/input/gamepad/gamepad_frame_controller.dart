import 'dart:math' as math;

import 'package:aonw/game/presentation/input/gamepad/gamepad_control_frame.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input_snapshot.dart';

final class GamepadFrameController {
  GamepadFrameController({
    this.deadzone = 0.24,
    this.cameraSensitivity = 1,
    this.initialRepeatDelay = 0.28,
    this.repeatInterval = 0.11,
  });

  final double deadzone;
  final double cameraSensitivity;
  final double initialRepeatDelay;
  final double repeatInterval;

  GamepadInputSnapshot _previous = GamepadInputSnapshot.empty;
  GamepadMapDirection? _heldCursorDirection;
  double _cursorRepeatRemaining = 0;

  bool get isIdle =>
      _previous.isIdle &&
      _heldCursorDirection == null &&
      _cursorRepeatRemaining == 0;

  void prime(GamepadInputSnapshot input) {
    _previous = input;
    _heldCursorDirection = _cursorDirection(input);
    _cursorRepeatRemaining = _heldCursorDirection == null
        ? 0
        : initialRepeatDelay;
  }

  GamepadControlFrame advance({
    required GamepadInputSnapshot input,
    required double dt,
  }) {
    if (input.isIdle && isIdle) return GamepadControlFrame.idle;

    final frame = GamepadControlFrame(
      cursorStep: _advanceCursorRepeat(_cursorDirection(input), dt),
      cameraX: _deadzone(input.cameraX) * cameraSensitivity,
      cameraY: _deadzone(input.cameraY) * cameraSensitivity,
      zoom: _deadzone(input.zoom),
      confirmPressed: _pressed(input.confirm, _previous.confirm),
      cancelPressed: _pressed(input.cancel, _previous.cancel),
      inspectPressed: _pressed(input.inspect, _previous.inspect),
      moveModePressed: _pressed(input.moveMode, _previous.moveMode),
      hudFocusPreviousPressed: _pressed(
        input.hudFocusPrevious,
        _previous.hudFocusPrevious,
      ),
      hudFocusNextPressed: _pressed(input.hudFocusNext, _previous.hudFocusNext),
      focusPreviousPressed: _pressed(
        input.focusPrevious,
        _previous.focusPrevious,
      ),
      focusNextPressed: _pressed(input.focusNext, _previous.focusNext),
      primaryActionPressed: _pressed(
        input.primaryAction,
        _previous.primaryAction,
      ),
    );
    _previous = input;
    return frame;
  }

  GamepadMapDirection? _advanceCursorRepeat(
    GamepadMapDirection? direction,
    double dt,
  ) {
    if (direction == null) {
      _heldCursorDirection = null;
      _cursorRepeatRemaining = 0;
      return null;
    }
    if (direction != _heldCursorDirection) {
      _heldCursorDirection = direction;
      _cursorRepeatRemaining = initialRepeatDelay;
      return direction;
    }

    _cursorRepeatRemaining -= dt;
    if (_cursorRepeatRemaining > 0) return null;
    _cursorRepeatRemaining += repeatInterval;
    return direction;
  }

  GamepadMapDirection? _cursorDirection(GamepadInputSnapshot input) {
    final dpadX = (input.dpadRight ? 1 : 0) - (input.dpadLeft ? 1 : 0);
    final dpadY = (input.dpadUp ? 1 : 0) - (input.dpadDown ? 1 : 0);
    final x = dpadX == 0 ? _deadzone(input.cursorX) : dpadX.toDouble();
    final y = dpadY == 0 ? _deadzone(input.cursorY) : dpadY.toDouble();
    if (x == 0 && y == 0) return null;
    if (x.abs() > y.abs()) {
      return x > 0 ? GamepadMapDirection.right : GamepadMapDirection.left;
    }
    return y > 0 ? GamepadMapDirection.up : GamepadMapDirection.down;
  }

  double _deadzone(double value) {
    final magnitude = value.abs();
    if (magnitude <= deadzone) return 0;
    final normalized = (magnitude - deadzone) / (1 - deadzone);
    return value.sign * math.min(1, normalized);
  }

  bool _pressed(bool current, bool previous) => current && !previous;
}
