part of 'unit_move_preview.dart';

extension _UnitMovePreviewTargetRendering on UnitMovePreview {
  void _drawTargetHexOutline(Canvas canvas) {
    final path = _targetHexPath();
    final pulse =
        0.5 +
        0.5 * math.sin(_flowPhase / UnitMovePreview._pulsePeriod * 2 * math.pi);
    final reachable = _isReachablePoint(points.length - 1);
    final color = reachable ? reachableColor : unreachableColor;
    final glow = reachable ? reachableGlow : unreachableGlow;

    if (showConfirmedTarget) {
      canvas
        ..drawPath(
          path,
          HudPaint.stroke(
              Colors.black,
              alpha: MapAlpha.strong,
              strokeWidth: MapStroke.glow,
            )
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        )
        ..drawPath(
          path,
          HudPaint.stroke(
              color,
              alpha: MapAlpha.opaque,
              strokeWidth: MapStroke.bold + 0.9,
            )
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      return;
    }

    canvas
      ..drawPath(
        path,
        HudPaint.stroke(
            glow,
            alpha: MapAlpha.soft + (pulse * 45).round(),
            strokeWidth: MapStroke.glow + pulse * 1.5,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(
        path,
        HudPaint.stroke(
            Colors.black,
            alpha: MapAlpha.regular,
            strokeWidth: MapStroke.bold + pulse * 0.5,
          )
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(
        path,
        HudPaint.stroke(
            color,
            alpha: MapAlpha.solid,
            strokeWidth: MapStroke.regular + pulse * 0.7,
          )
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
  }

  Path _targetHexPath() {
    final center = points.last.toOffset();
    final radius = MapConfig.defaultConfig.hexRadius * 0.86;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * HexGrid.perspectiveY * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  void _drawTargetArrow(Canvas canvas) {
    final target = points.last.toOffset();
    final metrics = _targetArrowMetrics(target);
    final reachable = _isReachablePoint(points.length - 1);
    final color = reachable ? reachableColor : unreachableColor;
    final glow = reachable ? reachableGlow : unreachableGlow;

    final glowPaint =
        HudPaint.stroke(glow, alpha: MapAlpha.soft, strokeWidth: MapStroke.glow)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final shadowPaint =
        HudPaint.stroke(
            Colors.black,
            alpha: MapAlpha.strong,
            strokeWidth: MapStroke.bold + 0.8,
          )
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    final arrowPaint =
        HudPaint.stroke(
            color,
            alpha: MapAlpha.opaque,
            strokeWidth: MapStroke.regular + 0.6,
          )
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    for (final paint in [glowPaint, shadowPaint, arrowPaint]) {
      canvas
        ..drawLine(metrics.tail, metrics.tip, paint)
        ..drawLine(metrics.tip, metrics.left, paint)
        ..drawLine(metrics.tip, metrics.right, paint);
    }
  }

  ({Offset tip, Offset tail, Offset left, Offset right, double lift})
  _targetArrowMetrics(Offset target) {
    final phase = _flowPhase / UnitMovePreview._pulsePeriod * 2 * math.pi;
    final bounce = math.sin(phase) * 4.0;
    final lift = 0.5 + 0.5 * math.sin(phase + 0.85);
    final tip = Offset(target.dx, target.dy - 37 + bounce);
    final tail = Offset(target.dx, target.dy - 62 + bounce);
    return (
      tip: tip,
      tail: tail,
      left: Offset(tip.dx - 9, tip.dy - 9),
      right: Offset(tip.dx + 9, tip.dy - 9),
      lift: lift,
    );
  }

  void _drawWaypointNode(Canvas canvas, int index) {
    final center = points[index].toOffset();
    final pulse =
        0.5 +
        0.5 *
            math.sin(
              _flowPhase / UnitMovePreview._pulsePeriod * 2 * math.pi + index,
            );
    final color = _nodePaintForPoint(index).color;
    final glow = _glowColorForPoint(index);
    final scale = _routeStrokeScaleForPoint(index);

    canvas
      ..drawCircle(
        center,
        (4.4 + pulse * 0.5) * scale,
        HudPaint.shadow(alpha: MapAlpha.regular)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
      )
      ..drawCircle(center, 3.2 * scale, HudPaint.shadow(alpha: MapAlpha.strong))
      ..drawCircle(
        center,
        (2.1 + pulse * 0.35) * scale,
        HudPaint.fill(color, alpha: MapAlpha.strong),
      )
      ..drawCircle(
        center,
        (3.7 + pulse * 0.25) * scale,
        HudPaint.stroke(
          glow,
          alpha: MapAlpha.soft,
          strokeWidth: math.max(MapStroke.hairline, MapStroke.hairline * scale),
        ),
      );
  }

  void _drawTargetRing(Canvas canvas) {
    final end = points.last.toOffset();
    final color = _colorForPoint(points.length - 1);
    final glow = _glowColorForPoint(points.length - 1);
    final pulse =
        0.5 +
        0.5 * math.sin(_flowPhase / UnitMovePreview._pulsePeriod * 2 * math.pi);

    canvas
      ..drawCircle(
        end,
        11.2 + pulse * 0.8,
        HudPaint.fill(glow, alpha: MapAlpha.whisper)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      )
      ..drawCircle(
        end,
        8.5 + pulse * 0.35,
        HudPaint.stroke(
          Colors.black,
          alpha: MapAlpha.strong,
          strokeWidth: MapStroke.bold,
        ),
      )
      ..drawCircle(
        end,
        8.0 + pulse * 0.35,
        HudPaint.stroke(
          color,
          alpha: MapAlpha.strong,
          strokeWidth: MapStroke.thin,
        ),
      );
  }

  void _drawStartRing(Canvas canvas) {
    if (!showStartMarkerForTesting) return;

    final start = points.first.toOffset();
    final pulse =
        0.5 +
        0.5 *
            math.sin(
              _flowPhase / UnitMovePreview._pulsePeriod * 2 * math.pi + 1.4,
            );

    canvas
      ..drawCircle(
        start,
        10.2 + pulse * 0.5,
        HudPaint.fill(
          _isTradeRoute ? _style.tradeRouteGlow : reachableGlow,
          alpha: MapAlpha.whisper,
        )..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      )
      ..drawCircle(
        start,
        8.6,
        HudPaint.stroke(
          Colors.black,
          alpha: MapAlpha.regular,
          strokeWidth: MapStroke.bold,
        ),
      )
      ..drawCircle(
        start,
        8.0,
        HudPaint.stroke(
          _isTradeRoute ? _style.tradeRouteColor : reachableColor,
          alpha: MapAlpha.strong,
          strokeWidth: MapStroke.thin,
        ),
      );
  }
}
