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
    required this.gamepadSettings,
    required this.builder,
    this.rendererInputEnabled = true,
    super.key,
  });

  final GameRenderer renderer;
  final GamepadControlSettings gamepadSettings;
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
    _adapter = GamepadInputAdapter(mapper: _mapper())..start();
  }

  @override
  void didUpdateWidget(GamepadRendererInputBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gamepadSettings != widget.gamepadSettings) {
      _adapter.updateMapper(_mapper());
    }
  }

  @override
  void dispose() {
    _adapter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GamepadInputRouterScope(
      input: _adapter.snapshot,
      deadzone: widget.gamepadSettings.deadzone,
      cameraSensitivity: widget.gamepadSettings.cameraSensitivity,
      child: Builder(
        builder: (context) {
          return GamepadInputRouteListener(
            route: GamepadInputRoute(
              enabled: widget.rendererInputEnabled,
              priority: GamepadInputRoutePriority.renderer,
              onFrame: widget.renderer.applyGamepadAnalogFrame,
              onNavigate: widget.renderer.moveGamepadCursor,
              onConfirm: widget.renderer.confirmGamepadCursor,
              onCancel: widget.renderer.cancelGamepadAction,
              onDetails: widget.renderer.inspectGamepadCursor,
              onMode: widget.renderer.toggleGamepadMoveMode,
              onFocusPrevious: widget.renderer.focusPreviousGamepadAction,
              onFocusNext: widget.renderer.focusNextGamepadAction,
            ),
            child: widget.builder(context, _adapter.snapshot),
          );
        },
      ),
    );
  }

  GamepadEventMapper _mapper() {
    return GamepadEventMapper(settings: widget.gamepadSettings);
  }
}
