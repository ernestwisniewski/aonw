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
    super.key,
  });

  final GameRenderer renderer;
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
    _attach(widget.renderer);
  }

  @override
  void didUpdateWidget(GamepadRendererInputBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.renderer == widget.renderer) return;
    _detach(oldWidget.renderer);
    _attach(widget.renderer);
  }

  @override
  void dispose() {
    _detach(widget.renderer);
    _adapter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _adapter.snapshot);
  }

  void _attach(GameRenderer renderer) {
    renderer.gamepadInput = _adapter.snapshot.value;
    _adapter.snapshot.addListener(_sync);
  }

  void _detach(GameRenderer renderer) {
    _adapter.snapshot.removeListener(_sync);
    renderer.gamepadInput = GamepadInputSnapshot.empty;
  }

  void _sync() {
    widget.renderer.gamepadInput = _adapter.snapshot.value;
  }
}
