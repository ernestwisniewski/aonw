import 'dart:async';

import 'package:aonw/game/presentation/input/gamepad/gamepad_control_frame.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_frame_controller.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input_router.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input_snapshot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class GamepadPanelInputListener extends StatefulWidget {
  const GamepadPanelInputListener({
    required this.child,
    this.input,
    this.enabled = true,
    this.priority = GamepadInputRoutePriority.panel,
    this.onNavigate,
    this.onConfirm,
    this.onCancel,
    this.onDetails,
    this.onMode,
    this.onHudFocusPrevious,
    this.onHudFocusNext,
    this.onFocusPrevious,
    this.onFocusNext,
    this.onPrimaryAction,
    this.onInputActive,
    super.key,
  });

  final ValueListenable<GamepadInputSnapshot>? input;
  final bool enabled;
  final GamepadInputRoutePriority priority;
  final ValueChanged<GamepadMapDirection>? onNavigate;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onDetails;
  final VoidCallback? onMode;
  final VoidCallback? onHudFocusPrevious;
  final VoidCallback? onHudFocusNext;
  final VoidCallback? onFocusPrevious;
  final VoidCallback? onFocusNext;
  final VoidCallback? onPrimaryAction;
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
  GamepadInputRouter? _router;
  GamepadInputRouteHandle? _routeHandle;
  Ticker? _ticker;
  Duration? _lastElapsed;
  bool _fallbackListening = false;
  bool _inputActiveNotificationScheduled = false;

  @override
  void initState() {
    super.initState();
    _input = _currentInput();
    _controller.prime(_input);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncInputMode();
  }

  @override
  void didUpdateWidget(GamepadPanelInputListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_fallbackListening && oldWidget.input != widget.input) {
      oldWidget.input?.removeListener(_handleInputChanged);
      widget.input?.addListener(_handleInputChanged);
    }
    _routeHandle?.update(_route());
    if (_fallbackListening &&
        (oldWidget.input != widget.input ||
            oldWidget.enabled != widget.enabled)) {
      _handleInputChanged();
    }
  }

  @override
  void dispose() {
    _routeHandle?.dispose();
    _detachFallbackInput();
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _syncInputMode() {
    final router = GamepadInputRouterScope.maybeOf(context);
    if (router == null) {
      _routeHandle?.dispose();
      _routeHandle = null;
      _router = null;
      _attachFallbackInput();
      return;
    }

    _detachFallbackInput();
    if (!identical(router, _router)) {
      _routeHandle?.dispose();
      _router = router;
      _routeHandle = router.register(_route());
      return;
    }
    _routeHandle?.update(_route());
  }

  void _attachFallbackInput() {
    if (_fallbackListening) return;
    _fallbackListening = true;
    widget.input?.addListener(_handleInputChanged);
    _handleInputChanged();
  }

  void _detachFallbackInput() {
    if (!_fallbackListening) return;
    _fallbackListening = false;
    widget.input?.removeListener(_handleInputChanged);
    _input = GamepadInputSnapshot.empty;
    _controller.prime(_input);
    _stopTicker();
  }

  GamepadInputRoute _route() {
    return GamepadInputRoute(
      enabled: widget.enabled,
      priority: widget.priority,
      onNavigate: widget.onNavigate,
      onConfirm: widget.onConfirm,
      onCancel: widget.onCancel,
      onDetails: widget.onDetails,
      onMode: widget.onMode,
      onHudFocusPrevious: widget.onHudFocusPrevious,
      onHudFocusNext: widget.onHudFocusNext,
      onFocusPrevious: widget.onFocusPrevious,
      onFocusNext: widget.onFocusNext,
      onPrimaryAction: widget.onPrimaryAction,
      onInputActive: widget.onInputActive,
    );
  }

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
      hudFocusPrevious:
          widget.onHudFocusPrevious != null && input.hudFocusPrevious,
      hudFocusNext: widget.onHudFocusNext != null && input.hudFocusNext,
      focusPrevious: widget.onFocusPrevious != null && input.focusPrevious,
      focusNext: widget.onFocusNext != null && input.focusNext,
      primaryAction: widget.onPrimaryAction != null && input.primaryAction,
    );
  }

  void _handleInputChanged() {
    _input = _currentInput();
    _notifyInputActive();
    _syncTicker();
  }

  void _notifyInputActive() {
    if (_input.isIdle || widget.onInputActive == null) return;
    if (_inputActiveNotificationScheduled) return;
    _inputActiveNotificationScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _inputActiveNotificationScheduled = false;
      if (!mounted || _input.isIdle) return;
      widget.onInputActive?.call();
    });
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
    if (frame.hudFocusPreviousPressed) widget.onHudFocusPrevious?.call();
    if (frame.hudFocusNextPressed) widget.onHudFocusNext?.call();
    if (frame.focusPreviousPressed) widget.onFocusPrevious?.call();
    if (frame.focusNextPressed) widget.onFocusNext?.call();
    if (frame.primaryActionPressed) widget.onPrimaryAction?.call();
  }
}
