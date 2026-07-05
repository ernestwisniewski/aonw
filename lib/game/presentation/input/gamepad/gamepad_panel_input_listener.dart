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
    super.key,
  });

  final ValueListenable<GamepadInputSnapshot>? input;
  final bool enabled;
  final ValueChanged<GamepadMapDirection>? onNavigate;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onDetails;
  final VoidCallback? onMode;
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
    return widget.input?.value ?? GamepadInputSnapshot.empty;
  }

  void _handleInputChanged() {
    _input = _currentInput();
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
    ticker.start();
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
  }
}
