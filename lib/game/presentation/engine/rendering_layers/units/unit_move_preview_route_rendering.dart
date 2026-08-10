part of 'unit_move_preview.dart';

extension _UnitMovePreviewRouteRendering on UnitMovePreview {
  Paint? get _emphasisLayerPaint {
    if (dimmed) {
      return HudPaint.colorFilter(HudPalette.textBright, alpha: MapAlpha.faint);
    }
    if (subdued) {
      return HudPaint.colorFilter(
        HudPalette.textBright,
        alpha: MapAlpha.strong,
      );
    }
    return null;
  }

  void _drawDashedSegment(Canvas canvas, Vector2 from, Vector2 to, int index) {
    final path = _linePath(from, to);
    final phase =
        _flowPhase %
        (UnitMovePreview._travelledDashLength +
            UnitMovePreview._travelledGapLength);
    _drawDashedPath(
      canvas,
      path,
      _routePaintForPoint(
        _isTradeRoute
            ? _style.tradeRouteMutedGlowPaint
            : _style.travelledShadowPaint,
        index,
      ),
      dashLength: UnitMovePreview._travelledDashLength,
      gapLength: UnitMovePreview._travelledGapLength,
      phase: phase,
    );
    _drawDashedPath(
      canvas,
      path,
      _routePaintForPoint(
        _isTradeRoute
            ? _style.tradeRouteMutedLinePaint
            : _style.travelledLinePaint,
        index,
      ),
      dashLength: UnitMovePreview._travelledDashLength,
      gapLength: UnitMovePreview._travelledGapLength,
      phase: phase,
    );
  }

  void _drawLitSegment(Canvas canvas, Vector2 from, Vector2 to, int index) {
    final path = _linePath(from, to);
    final phase =
        (_flowPhase + index * 3.5) % UnitMovePreview._routeDashPattern;
    _drawDashedPath(
      canvas,
      path,
      _routePaintForPoint(_edgePaintForPoint(index), index),
      dashLength: UnitMovePreview._routeDashLength,
      gapLength: UnitMovePreview._routeGapLength,
      phase: phase,
    );
    _drawDashedPath(
      canvas,
      path,
      _routePaintForPoint(_linePaintForPoint(index), index),
      dashLength: UnitMovePreview._routeDashLength,
      gapLength: UnitMovePreview._routeGapLength,
      phase: phase,
    );
  }

  Path _linePath(Vector2 from, Vector2 to) {
    return Path()
      ..moveTo(from.x, from.y)
      ..lineTo(to.x, to.y);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashLength,
    required double gapLength,
    required double phase,
  }) {
    for (final metric in path.computeMetrics()) {
      for (final distance in _dashStartDistances(
        pathLength: metric.length,
        dashLength: dashLength,
        gapLength: gapLength,
        phase: phase,
      )) {
        final start = math.max(0.0, distance);
        final end = math.min(metric.length, distance + dashLength);
        if (end > start) {
          canvas.drawPath(metric.extractPath(start, end), paint);
        }
      }
    }
  }

  Iterable<double> _dashStartDistances({
    required double pathLength,
    required double dashLength,
    required double gapLength,
    required double phase,
  }) sync* {
    final patternLength = dashLength + gapLength;
    var distance = (phase % patternLength) - patternLength;
    while (distance < pathLength) {
      yield distance;
      distance += patternLength;
    }
  }

  Paint _edgePaintForPoint(int index) {
    if (_isTradeRoute) {
      return _isMutedPoint(index)
          ? _style.tradeRouteMutedGlowPaint
          : _style.tradeRouteFocusGlowPaint;
    }
    if (_isMutedPoint(index)) {
      return _isReachablePoint(index)
          ? _style.reachableRouteMutedGlowPaint
          : _style.unreachableRouteMutedGlowPaint;
    }
    return _isReachablePoint(index)
        ? _style.reachableRouteGlowPaint
        : _style.unreachableRouteGlowPaint;
  }

  Paint _linePaintForPoint(int index) {
    if (_isTradeRoute) {
      return _isMutedPoint(index)
          ? _style.tradeRouteMutedLinePaint
          : _style.tradeRouteFocusLinePaint;
    }
    if (_isMutedPoint(index)) {
      return _isReachablePoint(index)
          ? _style.reachableRouteMutedLinePaint
          : _style.unreachableRouteMutedLinePaint;
    }
    return _isReachablePoint(index)
        ? _style.reachableRouteLinePaint
        : _style.unreachableRouteLinePaint;
  }

  Paint _nodePaintForPoint(int index) {
    if (_isTradeRoute) {
      return _isMutedPoint(index)
          ? _style.tradeRouteMutedNodePaint
          : _style.tradeRouteFocusNodePaint;
    }
    if (_isMutedPoint(index)) {
      return _isReachablePoint(index)
          ? _style.reachableMutedNodePaint
          : _style.unreachableMutedNodePaint;
    }
    return _isReachablePoint(index)
        ? _style.reachableNodePaint
        : _style.unreachableNodePaint;
  }

  Color _glowColorForPoint(int index) {
    if (_isTradeRoute) return _style.tradeRouteGlow;
    return _isReachablePoint(index) ? reachableGlow : unreachableGlow;
  }

  Color _colorForPoint(int index) {
    if (_isTradeRoute) return _style.tradeRouteColor;
    return _isReachablePoint(index) ? reachableColor : unreachableColor;
  }

  bool get _isTradeRoute => routeKind == UnitMovePreviewRouteKind.trade;

  int get _routeFocusEndIndex => math.min(
    points.length - 1,
    _clampedTravelledIndex + UnitMovePreview._focusedForwardHexes,
  );

  bool _isMutedPoint(int index) => index > _routeFocusEndIndex;

  Paint _routePaintForPoint(Paint paint, int index) {
    return _scaledStrokePaint(paint, _routeStrokeScaleForPoint(index));
  }

  Paint _scaledStrokePaint(Paint source, double scale) {
    return Paint()
      ..style = source.style
      ..color = source.color
      ..strokeWidth = math.max(MapStroke.hairline, source.strokeWidth * scale)
      ..strokeCap = source.strokeCap
      ..strokeJoin = source.strokeJoin
      ..maskFilter = source.maskFilter;
  }

  double _routeStrokeScaleForPoint(int index) {
    final delta = index - _clampedTravelledIndex;
    if (delta > 0) {
      if (delta <= UnitMovePreview._focusedForwardHexes) return 1.0;
      return math.max(
        UnitMovePreview._minRouteStrokeScale,
        1.0 -
            (delta - UnitMovePreview._focusedForwardHexes) *
                UnitMovePreview._frontRouteStrokeFalloff,
      );
    }

    return math.max(
      UnitMovePreview._minRouteStrokeScale,
      UnitMovePreview._nearBackRouteStrokeScale +
          delta * UnitMovePreview._backRouteStrokeFalloff,
    );
  }

  bool _isReachablePoint(int index) {
    return index >= 0 &&
        index < reachablePoints.length &&
        reachablePoints[index];
  }
}
