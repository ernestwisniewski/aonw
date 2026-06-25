import 'dart:math' as math;

import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter/material.dart';

enum MapIntentGlyph {
  city,
  growth,
  improve,
  attack,
  move,
  unavailable,
  workedHex,
  inspect,
}

abstract final class MapIntentMarker {
  static const double compactBadgeSize = 16.0;
  static const double defaultBadgeSize = 18.0;
  static const double touchBadgeSize = 24.0;
  static const double eventBadgeSize = 26.0;
  static const Color _cream = HudPalette.goldLight;
  static const Color _creamBright = HudPalette.textBright;

  static final Paint _badgeBg = HudPaint.fill(
    Color.alphaBlend(
      HudPaint.color(_cream, alpha: MapAlpha.whisper),
      HudPalette.surface,
    ),
  );
  static final Paint _badgeHighlight = HudPaint.stroke(
    _creamBright,
    alpha: MapAlpha.faint,
    strokeWidth: MapStroke.hairline,
  );

  static RRect badgeRectFor(
    Offset center, {
    double size = defaultBadgeSize,
    double? radius,
  }) {
    return RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size, height: size),
      Radius.circular(radius ?? size * 0.38),
    );
  }

  static void paintBadge(
    Canvas canvas,
    Offset center, {
    required Color color,
    Color? glow,
    Color? backgroundColor,
    Color? borderColor,
    double size = defaultBadgeSize,
    double? radius,
    MapIntentGlyph? glyph,
    double glyphScale = 1.0,
  }) {
    final rect = badgeRectFor(center, size: size, radius: radius);
    final glowColor = Color.lerp(glow ?? color, _cream, 0.68)!;
    final badgeBg = backgroundColor == null
        ? _badgeBg
        : HudPaint.fill(
            Color.alphaBlend(
              HudPaint.color(backgroundColor, alpha: MapAlpha.regular),
              HudPalette.surface,
            ),
            alpha: MapAlpha.solid,
          );
    final badgeBorder = borderColor ?? _cream;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          rect.outerRect.inflate(3.0),
          Radius.circular(size * 0.5),
        ),
        HudPaint.fill(glowColor, alpha: MapAlpha.whisper)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      )
      ..drawRRect(rect.shift(const Offset(0, 1.5)), HudPaint.shadow())
      ..drawRRect(rect, badgeBg)
      ..drawRRect(
        rect,
        HudPaint.stroke(
          badgeBorder,
          alpha: MapAlpha.opaque,
          strokeWidth: MapStroke.thin,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      )
      ..drawRRect(rect.deflate(1.4), _badgeHighlight);

    if (glyph == null) return;
    paintGlyph(
      canvas,
      rect.outerRect.center,
      glyph,
      scale: (size / defaultBadgeSize) * glyphScale,
    );
  }

  static void paintMoveBadge(
    Canvas canvas,
    Offset center, {
    double size = touchBadgeSize,
  }) {
    final rect = badgeRectFor(center, size: size, radius: size * 0.46);
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [HudPalette.goldLight, HudPalette.gold, HudPalette.goldDark],
        stops: [0.0, 0.48, 1.0],
      ).createShader(rect.outerRect);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          rect.outerRect.inflate(4.0),
          Radius.circular(size * 0.56),
        ),
        HudPaint.fill(HudPalette.gold, alpha: MapAlpha.soft)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      )
      ..drawRRect(rect.shift(const Offset(0, 1.4)), HudPaint.shadow())
      ..drawRRect(rect, fill)
      ..drawRRect(
        rect,
        HudPaint.stroke(
          HudPalette.gold,
          alpha: MapAlpha.full,
          strokeWidth: MapStroke.thin,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      )
      ..drawRRect(
        rect.deflate(1.5),
        HudPaint.stroke(
          HudPalette.goldLight,
          alpha: MapAlpha.strong,
          strokeWidth: MapStroke.hairline,
        ),
      );

    paintGlyph(
      canvas,
      rect.outerRect.center,
      MapIntentGlyph.move,
      color: HudPalette.goldLight,
      scale: size / defaultBadgeSize,
    );
  }

  static void paintGlyph(
    Canvas canvas,
    Offset center,
    MapIntentGlyph glyph, {
    double scale = 1.0,
    Color color = _cream,
  }) {
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(scale);
    _paintGlyphAtOrigin(canvas, glyph, color);
    canvas.restore();
  }

  static void _paintGlyphAtOrigin(
    Canvas canvas,
    MapIntentGlyph glyph,
    Color color,
  ) {
    final stroke = _glyphStroke(color: color);
    final fill = _glyphFill(color: color);
    const c = Offset.zero;
    switch (glyph) {
      case MapIntentGlyph.city:
        final roof = Path()
          ..moveTo(c.dx - 5.0, c.dy - 0.8)
          ..lineTo(c.dx, c.dy - 5.4)
          ..lineTo(c.dx + 5.0, c.dy - 0.8);
        final base = RRect.fromRectAndRadius(
          Rect.fromLTWH(c.dx - 3.9, c.dy - 0.7, 7.8, 5.5),
          const Radius.circular(1.2),
        );
        canvas
          ..drawPath(roof, stroke)
          ..drawRRect(base, stroke)
          ..drawLine(
            Offset(c.dx - 5.0, c.dy + 5.2),
            Offset(c.dx + 5.0, c.dy + 5.2),
            stroke,
          );
      case MapIntentGlyph.growth:
        canvas.drawCircle(c, 2.2, stroke);
        _drawExpansionArrow(
          canvas,
          c.translate(-1.7, -1.7),
          c.translate(-5.3, -5.3),
          stroke,
        );
        _drawExpansionArrow(
          canvas,
          c.translate(1.7, -1.7),
          c.translate(5.3, -5.3),
          stroke,
        );
        _drawExpansionArrow(
          canvas,
          c.translate(-1.7, 1.7),
          c.translate(-5.3, 5.3),
          stroke,
        );
        _drawExpansionArrow(
          canvas,
          c.translate(1.7, 1.7),
          c.translate(5.3, 5.3),
          stroke,
        );
      case MapIntentGlyph.improve:
        canvas
          ..drawLine(
            Offset(c.dx - 3.5, c.dy + 2.5),
            Offset(c.dx + 3.5, c.dy - 2.5),
            stroke,
          )
          ..drawLine(
            Offset(c.dx - 1.5, c.dy + 3.0),
            Offset(c.dx + 3.8, c.dy + 3.0),
            stroke,
          );
      case MapIntentGlyph.attack:
        canvas
          ..drawLine(Offset(c.dx - 4.2, c.dy), Offset(c.dx + 4.2, c.dy), stroke)
          ..drawLine(Offset(c.dx, c.dy - 4.2), Offset(c.dx, c.dy + 4.2), stroke)
          ..drawCircle(c, 2.7, stroke);
      case MapIntentGlyph.move:
        canvas
          ..drawCircle(c, 2.4, fill)
          ..drawCircle(c, 5.1, stroke);
      case MapIntentGlyph.unavailable:
        canvas
          ..drawLine(
            Offset(c.dx - 4.2, c.dy - 4.2),
            Offset(c.dx + 4.2, c.dy + 4.2),
            stroke,
          )
          ..drawLine(
            Offset(c.dx + 4.2, c.dy - 4.2),
            Offset(c.dx - 4.2, c.dy + 4.2),
            stroke,
          );
      case MapIntentGlyph.workedHex:
        final leaf = _glyphStroke(color: color, strokeWidth: MapStroke.thin);
        canvas
          ..drawLine(Offset(c.dx, c.dy + 5.2), Offset(c.dx, c.dy - 5.7), stroke)
          ..drawLine(
            Offset(c.dx, c.dy - 1.2),
            Offset(c.dx - 4.8, c.dy - 4.1),
            leaf,
          )
          ..drawLine(
            Offset(c.dx, c.dy + 0.9),
            Offset(c.dx + 5.0, c.dy - 2.0),
            leaf,
          )
          ..drawLine(
            Offset(c.dx, c.dy + 3.0),
            Offset(c.dx - 4.4, c.dy + 0.6),
            leaf,
          );
      case MapIntentGlyph.inspect:
        canvas
          ..drawCircle(c.translate(-1.2, -1.2), 3.8, stroke)
          ..drawLine(c.translate(2.0, 2.0), c.translate(5.1, 5.1), stroke);
    }
  }

  static void _drawExpansionArrow(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint,
  ) {
    canvas.drawLine(from, to, paint);
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length <= 0) return;
    final ux = dx / length;
    final uy = dy / length;
    final px = -uy;
    final py = ux;
    const arrowLength = 2.4;
    const arrowSpread = 1.8;
    canvas
      ..drawLine(
        to,
        Offset(
          to.dx - ux * arrowLength + px * arrowSpread,
          to.dy - uy * arrowLength + py * arrowSpread,
        ),
        paint,
      )
      ..drawLine(
        to,
        Offset(
          to.dx - ux * arrowLength - px * arrowSpread,
          to.dy - uy * arrowLength - py * arrowSpread,
        ),
        paint,
      );
  }

  static Paint _glyphStroke({required Color color, double strokeWidth = 1.8}) {
    return HudPaint.stroke(
      color,
      alpha: MapAlpha.opaque,
      strokeWidth: strokeWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
  }

  static Paint _glyphFill({required Color color}) {
    return HudPaint.fill(color, alpha: MapAlpha.opaque);
  }
}
