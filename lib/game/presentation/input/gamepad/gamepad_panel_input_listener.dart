import 'dart:async';

import 'package:aonw/game/presentation/input/gamepad/gamepad_control_frame.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_frame_controller.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input_snapshot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class GamepadPanelInputListener extends StatefulWidget {
  const GamepadPanelInputListener({
    required this.child,
    this.input,
    this.enabled = true,
    this.onNavigate,
    this.onConfirm,
    this.onCancel,
    this.onDetails,
    this.onMode,
    this.onHudFocus,
    this.onFocusPrevious,
    this.onFocusNext,
    this.onInputActive,
    super.key,
  });

  final ValueListenable<GamepadInputSnapshot>? input;
  final bool enabled;
  final ValueChanged<GamepadMapDirection>? onNavigate;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onDetails;
  final VoidCallback? onMode;
  final VoidCallback? onHudFocus;
  final VoidCallback? onFocusPrevious;
  final VoidCallback? onFocusNext;
  final VoidCallback? onInputActive;
  final Widget child;

  @override
  State<GamepadPanelInputListener> createState() =>
      _GamepadPanelInputListenerState();
}

class _GamepadPanelInputListenerState extends State<GamepadPanelInputListener>
    with SingleTickerProviderStateMixin {
  final GamepadFrameController _controller = GamepadFrameController();
  GamepadInputSnapshot _input = GamepadInputSnapshot.empty;
  Ticker? _ticker;
  Duration? _lastElapsed;

  @override
  void initState() {
    super.initState();
    _input = _currentInput();
    widget.input?.addListener(_handleInputChanged);
    _syncTicker();
  }

  @override
  void didUpdateWidget(GamepadPanelInputListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.input != widget.input) {
      oldWidget.input?.removeListener(_handleInputChanged);
      widget.input?.addListener(_handleInputChanged);
    }
    if (oldWidget.input != widget.input ||
        oldWidget.enabled != widget.enabled) {
      _handleInputChanged();
    }
  }

  @override
  void dispose() {
    widget.input?.removeListener(_handleInputChanged);
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  GamepadInputSnapshot _currentInput() {
    if (!widget.enabled) return GamepadInputSnapshot.empty;
    final input = widget.input?.value ?? GamepadInputSnapshot.empty;
    return GamepadInputSnapshot(
      cursorX: widget.onNavigate == null ? 0 : input.cursorX,
      cursorY: widget.onNavigate == null ? 0 : input.cursorY,
      dpadUp: widget.onNavigate != null && input.dpadUp,
      dpadDown: widget.onNavigate != null && input.dpadDown,
      dpadLeft: widget.onNavigate != null && input.dpadLeft,
      dpadRight: widget.onNavigate != null && input.dpadRight,
      confirm: widget.onConfirm != null && input.confirm,
      cancel: widget.onCancel != null && input.cancel,
      inspect: widget.onDetails != null && input.inspect,
      moveMode: widget.onMode != null && input.moveMode,
      hudFocus: widget.onHudFocus != null && input.hudFocus,
      focusPrevious: widget.onFocusPrevious != null && input.focusPrevious,
      focusNext: widget.onFocusNext != null && input.focusNext,
    );
  }

  void _handleInputChanged() {
    _input = _currentInput();
    if (!_input.isIdle) widget.onInputActive?.call();
    _syncTicker();
  }

  void _syncTicker() {
    if (_input.isIdle && _controller.isIdle) {
      _stopTicker();
      return;
    }
    _ensureTicker();
  }

  void _ensureTicker() {
    final ticker = _ticker ??= createTicker(_tick);
    if (ticker.isActive) return;
    _lastElapsed = null;
    unawaited(ticker.start());
  }

  void _stopTicker() {
    _lastElapsed = null;
    _ticker?.stop();
  }

  void _tick(Duration elapsed) {
    final previousElapsed = _lastElapsed;
    _lastElapsed = elapsed;
    final dt = previousElapsed == null
        ? 0.0
        : (elapsed - previousElapsed).inMicroseconds /
              Duration.microsecondsPerSecond;
    final frame = _controller.advance(input: _input, dt: dt);
    _dispatch(frame);
    if (_input.isIdle && _controller.isIdle) {
      _stopTicker();
    }
  }

  void _dispatch(GamepadControlFrame frame) {
    if (frame.isIdle) return;
    final direction = frame.cursorStep;
    if (direction != null) widget.onNavigate?.call(direction);
    if (frame.confirmPressed) widget.onConfirm?.call();
    if (frame.cancelPressed) widget.onCancel?.call();
    if (frame.inspectPressed) widget.onDetails?.call();
    if (frame.moveModePressed) widget.onMode?.call();
    if (frame.hudFocusPressed) widget.onHudFocus?.call();
    if (frame.focusPreviousPressed) widget.onFocusPrevious?.call();
    if (frame.focusNextPressed) widget.onFocusNext?.call();
  }
}
