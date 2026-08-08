import 'dart:math' as math;

import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:flutter/material.dart';

enum HexOutlinePattern { solid, dashed }

/// Shared visual contract for full-hex selection and focus outlines.
final class HexOutlinePainter {
  HexOutlinePainter(Color color) : _color = color {
    _rebuildPaints();
  }

  static const double dashLength = 6.0;
  static const double gapLength = 4.0;
  static const double highlightStrokeWidth = MapStroke.bold + 1.0;

  Color _color;
  late Paint _glowPaint;
  late Paint _backingPaint;
  late Paint _highlightPaint;

  Color get color => _color;
  double get strokeWidth => _highlightPaint.strokeWidth;

  void updateColor(Color color) {
    if (_color == color) return;
    _color = color;
    _rebuildPaints();
  }

  void paint(
    Canvas canvas, {
    required Path path,
    required List<Offset> corners,
    HexOutlinePattern pattern = HexOutlinePattern.solid,
  }) {
    if (pattern == HexOutlinePattern.solid) {
      canvas
        ..drawPath(path, _glowPaint)
        ..drawPath(path, _backingPaint)
        ..drawPath(path, _highlightPaint);
      return;
    }
    paintDashedPolygon(canvas, corners, _glowPaint);
    paintDashedPolygon(canvas, corners, _backingPaint);
    paintDashedPolygon(canvas, corners, _highlightPaint);
  }

  static void paintDashedPolygon(
    Canvas canvas,
    List<Offset> corners,
    Paint paint,
  ) {
    if (corners.length < 2) return;
    for (var index = 0; index < corners.length; index += 1) {
      paintDashedLine(
        canvas,
        corners[index],
        corners[(index + 1) % corners.length],
        paint,
      );
    }
  }

  static void paintDashedLine(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint,
  ) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length <= 0) return;
    final unitX = dx / length;
    final unitY = dy / length;
    var distance = 0.0;
    var drawing = true;
    while (distance < length) {
      final segmentLength = drawing ? dashLength : gapLength;
      final end = math.min(distance + segmentLength, length);
      if (drawing) {
        canvas.drawLine(
          Offset(from.dx + unitX * distance, from.dy + unitY * distance),
          Offset(from.dx + unitX * end, from.dy + unitY * end),
          paint,
        );
      }
      distance = end;
      drawing = !drawing;
    }
  }

  void _rebuildPaints() {
    _glowPaint = HudPaint.stroke(
      _color,
      alpha: MapAlpha.regular,
      strokeWidth: MapStroke.glow + 3.0,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    )..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.4);
    _backingPaint = HudPaint.stroke(
      Colors.black,
      alpha: MapAlpha.solid,
      strokeWidth: MapStroke.glow + 1.0,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
    _highlightPaint = HudPaint.stroke(
      _color,
      alpha: MapAlpha.full,
      strokeWidth: highlightStrokeWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
  }
}
