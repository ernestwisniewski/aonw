import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef GamepadRendererInputBuilder =
    Widget Function(
      BuildContext context,
      ValueListenable<GamepadInputSnapshot> gamepadInput,
    );

class GamepadRendererInputBinding extends StatefulWidget {
  const GamepadRendererInputBinding({
    required this.renderer,
    required this.builder,
    this.rendererInputEnabled = true,
    super.key,
  });

  final GameRenderer renderer;
  final bool rendererInputEnabled;
  final GamepadRendererInputBuilder builder;

  @override
  State<GamepadRendererInputBinding> createState() =>
      _GamepadRendererInputBindingState();
}

class _GamepadRendererInputBindingState
    extends State<GamepadRendererInputBinding> {
  late final GamepadInputAdapter _adapter;

  @override
  void initState() {
    super.initState();
    _adapter = GamepadInputAdapter()..start();
  }

  @override
  void didUpdateWidget(GamepadRendererInputBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.renderer != widget.renderer) {
      oldWidget.renderer.gamepadInput = GamepadInputSnapshot.empty;
    }
  }

  @override
  void dispose() {
    widget.renderer.gamepadInput = GamepadInputSnapshot.empty;
    _adapter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GamepadInputRouterScope(
      input: _adapter.snapshot,
      child: Builder(
        builder: (context) {
          return GamepadInputRouteListener(
            route: GamepadInputRoute(
              enabled: widget.rendererInputEnabled,
              priority: GamepadInputRoutePriority.renderer,
              onFrame: widget.renderer.applyGamepadControlFrame,
            ),
            child: widget.builder(context, _adapter.snapshot),
          );
        },
      ),
    );
  }
}
