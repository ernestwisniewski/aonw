import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/chip_tone.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

/// Canvas helpers for the repeated HUD surface shapes used by Flame layers.
abstract final class HudCanvasShapes {
  static void roundedSurface(
    Canvas canvas,
    Rect rect, {
    required SurfaceElevation elevation,
    BorderEmphasis border = BorderEmphasis.regular,
    Color accent = HudPalette.gold,
    Color? background,
    int? backgroundAlpha,
    int? borderAlpha,
    double radius = 10,
    double borderWidth = 1,
  }) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas
      ..drawRRect(
        rrect,
        HudPaint.surface(
          elevation,
          background: background,
          alpha: backgroundAlpha,
        ),
      )
      ..drawRRect(
        rrect,
        HudPaint.border(
          border,
          color: accent,
          alpha: borderAlpha,
          strokeWidth: borderWidth,
        ),
      );
  }

  static void pill(
    Canvas canvas,
    Rect rect, {
    required ChipTone tone,
    double strokeWidth = 1,
  }) {
    final spec = tone.spec;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2),
    );
    canvas
      ..drawRRect(rrect, HudPaint.fill(spec.background))
      ..drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = spec.border,
      );
  }
}
