import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter/material.dart';

abstract final class MapIconBadgePainter {
  static const Color cream = HudPalette.goldLight;
  static const Color creamBright = HudPalette.textBright;

  static void paintTray(Canvas canvas, RRect rect, {required Color accent}) {
    final glow = Color.lerp(accent, cream, 0.72)!;
    canvas
      ..drawRRect(rect.shift(const Offset(0, 1.3)), HudPaint.shadow())
      ..drawRRect(
        RRect.fromRectAndRadius(
          rect.outerRect.inflate(1.5),
          Radius.circular(rect.tlRadiusX + 1.5),
        ),
        HudPaint.fill(glow, alpha: MapAlpha.whisper)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawRRect(rect, HudPaint.fill(HudPalette.bg, alpha: MapAlpha.strong))
      ..drawRRect(
        rect,
        HudPaint.stroke(
          cream,
          alpha: MapAlpha.faint,
          strokeWidth: MapStroke.hairline,
        ),
      )
      ..drawRRect(
        rect.deflate(1.2),
        HudPaint.stroke(
          creamBright,
          alpha: MapAlpha.whisper,
          strokeWidth: MapStroke.hairline,
        ),
      );
  }

  static void paintBadge(
    Canvas canvas,
    RRect rect, {
    required Color accent,
    bool prominent = false,
  }) {
    final glowInflate = prominent ? 2.2 : 1.5;
    final borderAlpha = prominent ? MapAlpha.opaque : MapAlpha.strong;
    final glow = Color.lerp(accent, cream, 0.7)!;
    final fillBase = prominent ? HudPalette.surfaceDeep : HudPalette.surface;
    final fill = Color.alphaBlend(
      HudPaint.color(
        cream,
        alpha: prominent ? MapAlpha.faint : MapAlpha.whisper,
      ),
      HudPaint.color(fillBase, alpha: MapAlpha.solid),
    );
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          rect.outerRect.inflate(glowInflate),
          Radius.circular(rect.tlRadiusX + glowInflate),
        ),
        HudPaint.fill(
          glow,
          alpha: prominent ? MapAlpha.faint : MapAlpha.whisper,
        )..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawRRect(
        rect.shift(const Offset(0, 1.2)),
        HudPaint.shadow(alpha: MapAlpha.soft),
      )
      ..drawRRect(rect, HudPaint.fill(fill))
      ..drawRRect(
        rect,
        HudPaint.stroke(
          cream,
          alpha: borderAlpha,
          strokeWidth: prominent ? MapStroke.thin : MapStroke.hairline,
        ),
      )
      ..drawRRect(
        rect.deflate(1.3),
        HudPaint.stroke(
          creamBright,
          alpha: MapAlpha.faint,
          strokeWidth: MapStroke.hairline,
        ),
      );
  }

  static void paintChip(Canvas canvas, RRect rect, {required Color accent}) {
    final glow = Color.lerp(accent, cream, 0.68)!;
    canvas
      ..drawRRect(
        rect.shift(const Offset(0, 1.0)),
        HudPaint.shadow(alpha: MapAlpha.soft),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          rect.outerRect.inflate(1.3),
          Radius.circular(rect.tlRadiusX + 1.3),
        ),
        HudPaint.fill(glow, alpha: MapAlpha.whisper)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      )
      ..drawRRect(
        rect,
        HudPaint.fill(
          Color.alphaBlend(
            HudPaint.color(cream, alpha: MapAlpha.whisper),
            HudPaint.color(HudPalette.bg, alpha: MapAlpha.solid),
          ),
        ),
      )
      ..drawRRect(
        rect,
        HudPaint.stroke(
          cream,
          alpha: MapAlpha.strong,
          strokeWidth: MapStroke.hairline,
        ),
      )
      ..drawRRect(
        rect.deflate(1.1),
        HudPaint.stroke(
          creamBright,
          alpha: MapAlpha.whisper,
          strokeWidth: MapStroke.hairline,
        ),
      );
  }
}
