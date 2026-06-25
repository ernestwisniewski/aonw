import 'package:aonw/map/rendering/hex_world.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mixin that adds WASD/arrow keyboard panning to any [HexWorld] subclass.
mixin HexInputBehavior on HexWorld, KeyboardEvents {
  static const double _keyboardPanSpeed = 200.0;

  final Set<LogicalKeyboardKey> _keysPressed = {};

  static final _panKeys = {
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyD,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
  };

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _keysPressed
      ..clear()
      ..addAll(keysPressed);
    final isRelevant =
        keysPressed.any(_panKeys.contains) ||
        (event is KeyUpEvent && _panKeys.contains(event.logicalKey));
    return isRelevant ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final delta = keyboardPanDelta(dt: dt);
    if (delta.x != 0 || delta.y != 0) {
      panByScreenDelta(delta);
    }
  }

  /// Exposed for testing.
  Vector2 keyboardPanDelta({required double dt}) {
    double dx = 0;
    double dy = 0;
    final speed = _keyboardPanSpeed * dt / camera.viewfinder.zoom;

    if (_keysPressed.contains(LogicalKeyboardKey.keyW) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      dy -= speed;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyS) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      dy += speed;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyA) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      dx -= speed;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyD) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      dx += speed;
    }

    return Vector2(dx, dy);
  }
}
