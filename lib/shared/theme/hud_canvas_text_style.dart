import 'package:flutter/material.dart';

/// Text styles for HUD labels drawn directly on a Canvas.
abstract final class HudCanvasTextStyle {
  static TextStyle floatingText(Color color, {double opacity = 1}) {
    final clampedOpacity = opacity.clamp(0.0, 1.0).toDouble();
    return TextStyle(
      color: color.withValues(alpha: clampedOpacity),
      fontSize: 15,
      fontWeight: FontWeight.w900,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: clampedOpacity * 0.75),
          offset: const Offset(0, 1.5),
          blurRadius: 3,
        ),
      ],
    );
  }
}
