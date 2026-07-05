import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/game/presentation/input/gamepad/gamepad_input_snapshot.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_panel_input_listener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GamepadScrollable extends StatefulWidget {
  const GamepadScrollable({
    required this.child,
    this.input,
    this.enabled = true,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.step = 92,
    this.onCancel,
    super.key,
  });

  final Widget child;
  final ValueListenable<GamepadInputSnapshot>? input;
  final bool enabled;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final double step;
  final VoidCallback? onCancel;

  @override
  State<GamepadScrollable> createState() => _GamepadScrollableState();
}

class _GamepadScrollableState extends State<GamepadScrollable> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GamepadPanelInputListener(
      input: widget.input,
      enabled: widget.enabled,
      onNavigate: _scroll,
      onCancel: widget.onCancel,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: widget.scrollDirection,
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }

  void _scroll(GamepadMapDirection direction) {
    if (!_controller.hasClients) return;
    final delta = _deltaFor(direction);
    if (delta == 0) return;
    final position = _controller.position;
    final next = math.max(
      position.minScrollExtent,
      math.min(position.maxScrollExtent, position.pixels + delta),
    );
    if (next == position.pixels) return;
    unawaited(
      _controller.animateTo(
        next,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  double _deltaFor(GamepadMapDirection direction) {
    return switch ((widget.scrollDirection, direction)) {
      (Axis.vertical, GamepadMapDirection.up) => -widget.step,
      (Axis.vertical, GamepadMapDirection.down) => widget.step,
      (Axis.horizontal, GamepadMapDirection.left) => -widget.step,
      (Axis.horizontal, GamepadMapDirection.right) => widget.step,
      _ => 0,
    };
  }
}
