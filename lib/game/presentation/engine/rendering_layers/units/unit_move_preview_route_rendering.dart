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

  void _drawTravelledSegment(Canvas canvas, int index) {
    _drawDashedPath(
      canvas,
      _routeSegmentPath(index),
      _style.travelledLinePaint,
      phase: 0,
      patternSeed: index,
    );
  }

  void _drawPlannedSegment(Canvas canvas, int index) {
    final path = _routeSegmentPath(index);
    if (_isReachablePoint(index)) {
      _drawDashedPath(
        canvas,
        path,
        _style.currentTurnGlowPaint,
        phase: _dashPhaseForSegment(index),
        patternSeed: index,
      );
      _drawDashedPath(
        canvas,
        path,
        _style.currentTurnLinePaint,
        phase: _dashPhaseForSegment(index),
        patternSeed: index,
      );
      return;
    }

    _drawDashedPath(
      canvas,
      path,
      _style.futureTurnLinePaint,
      phase: _dashPhaseForSegment(index),
      patternSeed: index,
    );
  }

  double _dashPhaseForSegment(int index) {
    if (index <= _clampedTravelledIndex) return 0;
    return (_flowPhase + index * 3.5) % UnitMovePreview._routeDashPattern;
  }

  void _drawRouteBoundaryMarkers(Canvas canvas) {
    for (final index in _routeBoundaryPointIndices) {
      final center = points[index].toOffset();
      final currentTurnEnd = _isCurrentTurnEndBoundary(index);
      _drawRouteBoundaryDot(canvas, center, emphasized: currentTurnEnd);
    }
  }

  double _routeBoundaryRadiusForPoint(int index) =>
      _isCurrentTurnEndBoundary(index)
      ? UnitMovePreview._currentTurnBoundaryRadius
      : UnitMovePreview._routeBoundaryRadius;

  bool _isCurrentTurnEndBoundary(int index) {
    return index > 0 &&
        index < points.length - 1 &&
        _routeSegmentState(index) == _RouteSegmentState.currentTurn &&
        _routeSegmentState(index + 1) == _RouteSegmentState.futureTurn;
  }

  Iterable<int> get _routeBoundaryPointIndices {
    final indices = <int>{
      for (final index in turnBoundaryPointIndices)
        if (index > 0 && index < points.length - 1) index,
      ..._routeStateBoundaryPointIndices,
    }.toList(growable: false)..sort();
    return indices;
  }

  Iterable<int> get _routeStateBoundaryPointIndices sync* {
    for (var index = 1; index < points.length - 1; index++) {
      if (_routeSegmentState(index) != _routeSegmentState(index + 1)) {
        yield index;
      }
    }
  }

  _RouteSegmentState _routeSegmentState(int index) {
    if (index <= _clampedTravelledIndex) {
      return _RouteSegmentState.travelled;
    }
    return _isReachablePoint(index)
        ? _RouteSegmentState.currentTurn
        : _RouteSegmentState.futureTurn;
  }

  /// Builds one stable, tangent-continuous movement step.
  ///
  /// Adjacent segments share the same perturbed tangent at their common hex,
  /// so turns round naturally instead of forming a polyline corner. The
  /// perturbation also keeps a straight run of hexes from looking ruler-drawn.
  Path _routeSegmentPath(int index) {
    return _routeSegmentCache.putIfAbsent(
      index,
      () => _buildRouteSegmentPath(index),
    );
  }

  Path _buildRouteSegmentPath(int index) {
    assert(index > 0 && index < points.length);
    final from = points[index - 1];
    final to = points[index];
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final length = math.sqrt(dx * dx + dy * dy);
    final path = Path()..moveTo(from.x, from.y);
    if (length <= 0.001) return path..lineTo(to.x, to.y);
    if (roadSegmentIndices.contains(index)) {
      return path..lineTo(to.x, to.y);
    }

    final fromTangent = _routeTangentAt(index - 1);
    final toTangent = _routeTangentAt(index);
    final handleLength = length * 0.34;

    return path..cubicTo(
      from.x + fromTangent.dx * handleLength,
      from.y + fromTangent.dy * handleLength,
      to.x - toTangent.dx * handleLength,
      to.y - toTangent.dy * handleLength,
      to.x,
      to.y,
    );
  }

  Offset _routeTangentAt(int pointIndex) {
    final previous = points[math.max(0, pointIndex - 1)];
    final next = points[math.min(points.length - 1, pointIndex + 1)];
    final dx = next.x - previous.x;
    final dy = next.y - previous.y;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length <= 0.001) return const Offset(1, 0);

    final baseAngle = math.atan2(dy, dx);
    final perturbation = (_routePointNoise(pointIndex) - 0.5) * 0.42;
    final angle = baseAngle + perturbation;
    return Offset(math.cos(angle), math.sin(angle));
  }

  double _routePointNoise(int pointIndex) {
    final point = points[pointIndex];
    var value =
        (point.x * 10).round() * 73856093 ^
        (point.y * 10).round() * 19349663 ^
        pointIndex * 83492791;
    value = (value ^ (value >> 16)) * 0x45d9f3b;
    value = (value ^ (value >> 16)) * 0x45d9f3b;
    value ^= value >> 16;
    return (value & 0x7fffffff) / 0x7fffffff;
  }

  Path _routePathFrom(int startIndex) {
    final route = Path();
    for (var index = startIndex + 1; index < points.length; index++) {
      route.addPath(_routeSegmentPath(index), Offset.zero);
    }
    return route;
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double phase,
    required int patternSeed,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance =
          (phase % UnitMovePreview._routeDashPattern) -
          UnitMovePreview._routeDashPattern;
      var dashIndex = 0;
      while (distance < metric.length) {
        final dashLength = _irregularDashLength(patternSeed, dashIndex);
        final start = math.max(0.0, distance);
        final end = math.min(metric.length, distance + dashLength);
        if (end > start) {
          canvas.drawPath(metric.extractPath(start, end), paint);
        }
        distance += dashLength + _irregularGapLength(patternSeed, dashIndex);
        dashIndex += 1;
      }
    }
  }

  double _irregularDashLength(int seed, int dashIndex) {
    const adjustments = [1.0, -2.2, 2.5, -0.8];
    return UnitMovePreview._routeDashLength +
        adjustments[(seed + dashIndex) % adjustments.length];
  }

  double _irregularGapLength(int seed, int dashIndex) {
    const adjustments = [0.0, 1.8, -1.2, 0.9];
    return UnitMovePreview._routeGapLength +
        adjustments[(seed * 3 + dashIndex) % adjustments.length];
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

  bool _isReachablePoint(int index) {
    return index >= 0 &&
        index < reachablePoints.length &&
        reachablePoints[index];
  }
}

enum _RouteSegmentState { travelled, currentTurn, futureTurn }
