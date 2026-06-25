import 'dart:ui' as ui;

import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/chip_tone.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

/// Paint equivalents of the shared HUD surface tokens.
abstract final class HudPaint {
  static Paint surface(
    SurfaceElevation elevation, {
    Color? background,
    int? alpha,
  }) {
    return Paint()
      ..style = PaintingStyle.fill
      ..color = elevation.fill(background: background, alpha: alpha);
  }

  static Paint border(
    BorderEmphasis emphasis, {
    Color color = HudPalette.gold,
    int? alpha,
    double strokeWidth = 1,
  }) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color.withAlpha(alpha ?? emphasis.alpha);
  }

  static Paint accent(ChipTone tone, {int alpha = 96}) {
    return fill(tone.spec.foreground, alpha: alpha);
  }

  static Paint fill(Color color, {int? alpha}) {
    return Paint()
      ..style = PaintingStyle.fill
      ..color = alpha == null ? color : color.withAlpha(alpha);
  }

  static Paint opacityFill(
    Color color, {
    required double opacity,
    ui.MaskFilter? maskFilter,
  }) {
    return Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: _clampedOpacity(opacity))
      ..maskFilter = maskFilter;
  }

  static Paint opacityStroke(
    Color color, {
    required double opacity,
    double strokeWidth = 1,
  }) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color.withValues(alpha: _clampedOpacity(opacity));
  }

  static Color color(Color color, {int? alpha}) {
    return alpha == null ? color : color.withAlpha(alpha);
  }

  static Paint colorFilter(
    Color color, {
    BlendMode blendMode = BlendMode.modulate,
    int? alpha,
  }) {
    return Paint()
      ..colorFilter = ColorFilter.mode(
        HudPaint.color(color, alpha: alpha),
        blendMode,
      );
  }

  static Paint matrixColorFilter(List<double> matrix) {
    return Paint()..colorFilter = ColorFilter.matrix(matrix);
  }

  static Paint stroke(
    Color color, {
    int alpha = 255,
    double strokeWidth = 1,
    StrokeCap strokeCap = StrokeCap.butt,
    StrokeJoin strokeJoin = StrokeJoin.miter,
  }) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = strokeCap
      ..strokeJoin = strokeJoin
      ..color = color.withAlpha(alpha);
  }

  static Paint shadow({int alpha = 92}) {
    return fill(Colors.black, alpha: alpha);
  }

  static double _clampedOpacity(double opacity) {
    return opacity.clamp(0, 1).toDouble();
  }
}
