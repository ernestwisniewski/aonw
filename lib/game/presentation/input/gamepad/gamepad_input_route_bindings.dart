part of 'gamepad_input_router.dart';

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

class GamepadInputRouteBinding extends StatefulWidget {
  const GamepadInputRouteBinding({
    required this.router,
    required this.route,
    required this.child,
    super.key,
  });

  final GamepadInputRouter? router;
  final GamepadInputRoute route;
  final Widget child;

  @override
  State<GamepadInputRouteBinding> createState() =>
      _GamepadInputRouteBindingState();
}

class _GamepadInputRouteBindingState extends State<GamepadInputRouteBinding> {
  GamepadInputRouter? _router;
  GamepadInputRouteHandle? _handle;

  @override
  void initState() {
    super.initState();
    _syncRoute();
  }

  @override
  void didUpdateWidget(covariant GamepadInputRouteBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRoute();
  }

  @override
  void dispose() {
    _handle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _syncRoute() {
    final router = widget.router;
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
