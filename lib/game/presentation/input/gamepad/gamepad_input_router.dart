import 'dart:async';

import 'package:aonw/game/presentation/input/gamepad/gamepad_control_frame.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_frame_controller.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input_snapshot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

typedef GamepadFrameCallback =
    void Function(GamepadControlFrame frame, double dt);

enum GamepadInputRoutePriority { renderer, primary, hud, panel, modal }

final class GamepadInputRoute {
  const GamepadInputRoute({
    this.enabled = true,
    this.priority = GamepadInputRoutePriority.panel,
    this.onFrame,
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
  });

  final bool enabled;
  final GamepadInputRoutePriority priority;
  final GamepadFrameCallback? onFrame;
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

  GamepadInputSnapshot filteredInput(GamepadInputSnapshot input) {
    if (!enabled) return GamepadInputSnapshot.empty;
    if (onFrame != null) return input;
    return GamepadInputSnapshot(
      cursorX: onNavigate == null ? 0 : input.cursorX,
      cursorY: onNavigate == null ? 0 : input.cursorY,
      dpadUp: onNavigate != null && input.dpadUp,
      dpadDown: onNavigate != null && input.dpadDown,
      dpadLeft: onNavigate != null && input.dpadLeft,
      dpadRight: onNavigate != null && input.dpadRight,
      confirm: onConfirm != null && input.confirm,
      cancel: onCancel != null && input.cancel,
      inspect: onDetails != null && input.inspect,
      moveMode: onMode != null && input.moveMode,
      hudFocusPrevious: onHudFocusPrevious != null && input.hudFocusPrevious,
      hudFocusNext: onHudFocusNext != null && input.hudFocusNext,
      focusPrevious: onFocusPrevious != null && input.focusPrevious,
      focusNext: onFocusNext != null && input.focusNext,
      primaryAction: onPrimaryAction != null && input.primaryAction,
    );
  }
}

abstract interface class GamepadInputRouter {
  ValueListenable<GamepadInputSnapshot> get input;

  GamepadInputRouteHandle register(GamepadInputRoute route);
}

final class GamepadInputRouteHandle {
  GamepadInputRouteHandle._(this._router, this._id);

  final _GamepadInputRouterController _router;
  final int _id;
  bool _disposed = false;

  void update(GamepadInputRoute route) {
    if (_disposed) return;
    _router.update(_id, route);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _router.unregister(_id);
  }
}

class GamepadInputRouterScope extends StatefulWidget {
  const GamepadInputRouterScope({
    required this.input,
    required this.child,
    this.deadzone = 0.24,
    this.cameraSensitivity = 1,
    super.key,
  });

  final ValueListenable<GamepadInputSnapshot> input;
  final Widget child;
  final double deadzone;
  final double cameraSensitivity;

  static GamepadInputRouter? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_GamepadInputRouterHost>()
        ?.router;
  }

  @override
  State<GamepadInputRouterScope> createState() =>
      _GamepadInputRouterScopeState();
}

class _GamepadInputRouterScopeState extends State<GamepadInputRouterScope>
    with SingleTickerProviderStateMixin {
  late final _GamepadInputRouterController _router;

  @override
  void initState() {
    super.initState();
    _router = _GamepadInputRouterController(
      input: widget.input,
      vsync: this,
      deadzone: widget.deadzone,
      cameraSensitivity: widget.cameraSensitivity,
    );
  }

  @override
  void didUpdateWidget(GamepadInputRouterScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.input != widget.input) {
      _router.replaceInput(widget.input);
    }
    if (oldWidget.deadzone != widget.deadzone ||
        oldWidget.cameraSensitivity != widget.cameraSensitivity) {
      _router.updateFrameSettings(
        deadzone: widget.deadzone,
        cameraSensitivity: widget.cameraSensitivity,
      );
    }
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GamepadInputRouterHost(router: _router, child: widget.child);
  }
}

class GamepadInputRouteListener extends StatefulWidget {
  const GamepadInputRouteListener({
    required this.route,
    required this.child,
    super.key,
  });

  final GamepadInputRoute route;
  final Widget child;

  @override
  State<GamepadInputRouteListener> createState() =>
      _GamepadInputRouteListenerState();
}

class _GamepadInputRouteListenerState extends State<GamepadInputRouteListener> {
  GamepadInputRouter? _router;
  GamepadInputRouteHandle? _handle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRoute();
  }

  @override
  void didUpdateWidget(GamepadInputRouteListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handle?.update(widget.route);
  }

  @override
  void dispose() {
    _handle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _syncRoute() {
    final router = GamepadInputRouterScope.maybeOf(context);
    if (!identical(router, _router)) {
      _handle?.dispose();
      _handle = null;
      _router = router;
      if (router != null) {
        _handle = router.register(widget.route);
      }
      return;
    }
    _handle?.update(widget.route);
  }
}

class _GamepadInputRouterHost extends InheritedWidget {
  const _GamepadInputRouterHost({required this.router, required super.child});

  final GamepadInputRouter router;

  @override
  bool updateShouldNotify(_GamepadInputRouterHost oldWidget) {
    return oldWidget.router != router;
  }
}

final class _GamepadInputRouterController implements GamepadInputRouter {
  _GamepadInputRouterController({
    required ValueListenable<GamepadInputSnapshot> input,
    required TickerProvider vsync,
    required double deadzone,
    required double cameraSensitivity,
  }) : _input = input {
    _ticker = vsync.createTicker(_tick);
    _frameController = GamepadFrameController(
      deadzone: deadzone,
      cameraSensitivity: cameraSensitivity,
    );
    _currentInput = input.value;
    _frameController.prime(_currentInput);
    _input.addListener(_handleInputChanged);
    _syncTicker();
  }

  late GamepadFrameController _frameController;
  late final Ticker _ticker;
  final Map<int, _RegisteredGamepadInputRoute> _routes = {};
  final Set<int> _pendingInputActiveNotifications = {};

  ValueListenable<GamepadInputSnapshot> _input;
  GamepadInputSnapshot _currentInput = GamepadInputSnapshot.empty;
  int _nextId = 0;
  int _nextOrder = 0;
  Duration? _lastElapsed;
  bool _disposed = false;

  @override
  ValueListenable<GamepadInputSnapshot> get input => _input;

  @override
  GamepadInputRouteHandle register(GamepadInputRoute route) {
    final id = _nextId++;
    _routes[id] = _RegisteredGamepadInputRoute(
      route: route,
      order: _nextOrder++,
    );
    _frameController.prime(_currentInput);
    _notifyRouteInputActive(id);
    _syncTicker();
    return GamepadInputRouteHandle._(this, id);
  }

  void update(int id, GamepadInputRoute route) {
    final existing = _routes[id];
    if (existing == null) return;
    _routes[id] = existing.copyWith(route: route);
    _notifyRouteInputActive(id);
    _syncTicker();
  }

  void unregister(int id) {
    _routes.remove(id);
    _syncTicker();
  }

  void replaceInput(ValueListenable<GamepadInputSnapshot> input) {
    if (identical(input, _input)) return;
    _input.removeListener(_handleInputChanged);
    _input = input;
    _currentInput = input.value;
    _frameController.prime(_currentInput);
    _input.addListener(_handleInputChanged);
    _syncTicker();
  }

  void updateFrameSettings({
    required double deadzone,
    required double cameraSensitivity,
  }) {
    if (_frameController.deadzone == deadzone &&
        _frameController.cameraSensitivity == cameraSensitivity) {
      return;
    }
    _frameController = GamepadFrameController(
      deadzone: deadzone,
      cameraSensitivity: cameraSensitivity,
    )..prime(_currentInput);
    _syncTicker();
  }

  void dispose() {
    _disposed = true;
    _pendingInputActiveNotifications.clear();
    _input.removeListener(_handleInputChanged);
    _ticker.dispose();
  }

  void _handleInputChanged() {
    _currentInput = _input.value;
    for (final id in _routes.keys) {
      _notifyRouteInputActive(id);
    }
    _syncTicker();
  }

  void _notifyRouteInputActive(int id) {
    final route = _routes[id]?.route;
    if (route == null) return;
    if (route.filteredInput(_currentInput).isIdle) return;
    if (route.onInputActive == null) return;
    if (!_pendingInputActiveNotifications.add(id)) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _pendingInputActiveNotifications.remove(id);
      if (_disposed) return;
      final route = _routes[id]?.route;
      if (route == null || route.filteredInput(_currentInput).isIdle) return;
      route.onInputActive?.call();
    });
  }

  void _syncTicker() {
    if (_routes.isEmpty || (_currentInput.isIdle && _frameController.isIdle)) {
      _stopTicker();
      return;
    }
    _ensureTicker();
  }

  void _ensureTicker() {
    if (_ticker.isActive) return;
    _lastElapsed = null;
    unawaited(_ticker.start());
  }

  void _stopTicker() {
    _lastElapsed = null;
    _ticker.stop();
  }

  void _tick(Duration elapsed) {
    final previousElapsed = _lastElapsed;
    _lastElapsed = elapsed;
    final dt = previousElapsed == null
        ? 0.0
        : (elapsed - previousElapsed).inMicroseconds /
              Duration.microsecondsPerSecond;
    final frame = _frameController.advance(input: _currentInput, dt: dt);
    _dispatch(frame, dt);
    if (_currentInput.isIdle && _frameController.isIdle) {
      _stopTicker();
    }
  }

  void _dispatch(GamepadControlFrame frame, double dt) {
    if (frame.isIdle) return;
    final routes = _orderedRoutes();
    for (final entry in routes) {
      entry.route.onFrame?.call(frame, dt);
    }

    final direction = frame.cursorStep;
    if (direction != null) {
      _dispatchFirst(
        routes,
        canDispatch: (route) => route.onNavigate != null,
        dispatch: (route) => route.onNavigate!(direction),
      );
    }
    if (frame.confirmPressed) {
      _dispatchFirst(
        routes,
        canDispatch: (route) => route.onConfirm != null,
        dispatch: (route) => route.onConfirm!(),
      );
    }
    if (frame.cancelPressed) {
      _dispatchFirst(
        routes,
        canDispatch: (route) => route.onCancel != null,
        dispatch: (route) => route.onCancel!(),
      );
    }
    if (frame.inspectPressed) {
      _dispatchFirst(
        routes,
        canDispatch: (route) => route.onDetails != null,
        dispatch: (route) => route.onDetails!(),
      );
    }
    if (frame.moveModePressed) {
      _dispatchFirst(
        routes,
        canDispatch: (route) => route.onMode != null,
        dispatch: (route) => route.onMode!(),
      );
    }
    if (frame.hudFocusPreviousPressed) {
      _dispatchFirst(
        routes,
        canDispatch: (route) => route.onHudFocusPrevious != null,
        dispatch: (route) => route.onHudFocusPrevious!(),
      );
    }
    if (frame.hudFocusNextPressed) {
      _dispatchFirst(
        routes,
        canDispatch: (route) => route.onHudFocusNext != null,
        dispatch: (route) => route.onHudFocusNext!(),
      );
    }
    if (frame.focusPreviousPressed) {
      _dispatchFirst(
        routes,
        canDispatch: (route) => route.onFocusPrevious != null,
        dispatch: (route) => route.onFocusPrevious!(),
      );
    }
    if (frame.focusNextPressed) {
      _dispatchFirst(
        routes,
        canDispatch: (route) => route.onFocusNext != null,
        dispatch: (route) => route.onFocusNext!(),
      );
    }
    if (frame.primaryActionPressed) {
      _dispatchFirst(
        routes,
        canDispatch: (route) => route.onPrimaryAction != null,
        dispatch: (route) => route.onPrimaryAction!(),
      );
    }
  }

  List<_RegisteredGamepadInputRoute> _orderedRoutes() {
    final routes =
        [
          for (final entry in _routes.values)
            if (entry.route.enabled) entry,
        ]..sort((left, right) {
          final priority = right.route.priority.index.compareTo(
            left.route.priority.index,
          );
          if (priority != 0) return priority;
          return right.order.compareTo(left.order);
        });
    return routes;
  }

  void _dispatchFirst(
    List<_RegisteredGamepadInputRoute> routes, {
    required bool Function(GamepadInputRoute route) canDispatch,
    required void Function(GamepadInputRoute route) dispatch,
  }) {
    for (final entry in routes) {
      if (!canDispatch(entry.route)) continue;
      dispatch(entry.route);
      return;
    }
  }
}

final class _RegisteredGamepadInputRoute {
  const _RegisteredGamepadInputRoute({
    required this.route,
    required this.order,
  });

  final GamepadInputRoute route;
  final int order;

  _RegisteredGamepadInputRoute copyWith({GamepadInputRoute? route}) {
    return _RegisteredGamepadInputRoute(
      route: route ?? this.route,
      order: order,
    );
  }
}
