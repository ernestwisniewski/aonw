import 'dart:math' as math;

import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_sprite_controller.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_move_preview_style.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum UnitMovePreviewRouteKind { movement, trade }

class UnitMovePreview extends Component {
  static const double _routeDashLength = 13.0;
  static const double _routeGapLength = 8.0;
  static const double _routeDashPattern = _routeDashLength + _routeGapLength;
  static const double _travelledDashLength = 7.5;
  static const double _travelledGapLength = 5.5;
  static const double _flowSpeed = 24.0;
  static const double _pulsePeriod = 42.0;
  static const int _focusedForwardHexes = 2;
  static const double _minRouteStrokeScale = 0.74;
  static const double _nearBackRouteStrokeScale = 0.90;
  static const double _backRouteStrokeFalloff = 0.055;
  static const double _frontRouteStrokeFalloff = 0.06;

  final List<Vector2> points;
  final List<int> cumulativeCosts;
  final int totalCost;
  final int availableMovementPoints;
  final bool canMoveNow;
  final GameUnitType? unitType;
  final UnitMovePreviewRouteKind routeKind;
  bool dimmed;
  bool subdued;
  bool showTargetPulse;
  bool showTargetArrow;
  bool showConfirmedTarget;

  /// Points at index <= travelledUpToIndex are rendered as dashed (already travelled).
  final int travelledUpToIndex;
  final UnitMovePreviewStyle _style = UnitMovePreviewStyle();
  late final UnitMarkerSpriteController? _unitSpriteController =
      unitType == null ? null : UnitMarkerSpriteController(unitType!);
  double _flowPhase = 0;

  UnitMovePreview({
    required List<Vector2> points,
    required List<int> cumulativeCosts,
    required this.totalCost,
    required this.availableMovementPoints,
    required this.canMoveNow,
    this.unitType,
    this.routeKind = UnitMovePreviewRouteKind.movement,
    this.dimmed = false,
    this.subdued = false,
    this.showTargetPulse = false,
    this.showTargetArrow = false,
    this.showConfirmedTarget = false,
    this.travelledUpToIndex = 0,
  }) : points = [for (final point in points) point.clone()],
       cumulativeCosts = List.unmodifiable(cumulativeCosts);

  Color get reachableColor => _style.reachableColor;

  Color get reachableGlow => _style.reachableGlow;

  Color get reachableCore => _style.reachableCore;

  Color get unreachableColor => _style.unreachableColor;

  Color get unreachableGlow => _style.unreachableGlow;

  Color get unreachableCore => _style.unreachableCore;

  GameUnitType? get unitTypeForTesting => unitType;

  bool get usesUnitGhostForTesting => _unitSpriteController != null;

  bool get dimmedForTesting => dimmed;

  bool get subduedForTesting => subdued;

  bool get showTargetPulseForTesting => showTargetPulse;

  bool get showTargetArrowForTesting => showTargetArrow;

  bool get showConfirmedTargetForTesting => showConfirmedTarget;

  bool get showStartMarkerForTesting => points.length >= 2;

  @visibleForTesting
  bool routePointMutedForTesting(int index) => _isMutedPoint(index);

  @visibleForTesting
  double routeStrokeScaleForTesting(int index) =>
      _routeStrokeScaleForPoint(index);

  @visibleForTesting
  List<double> dashStartsForTesting({
    required double pathLength,
    required double phase,
    double dashLength = _routeDashLength,
    double gapLength = _routeGapLength,
  }) {
    return _dashStartDistances(
      pathLength: pathLength,
      dashLength: dashLength,
      gapLength: gapLength,
      phase: phase,
    ).toList(growable: false);
  }

  @visibleForTesting
  Offset? travellingMarkerPositionForTesting({double? phase, int? startIndex}) {
    return _routeSample(
      startIndex ?? _clampedTravelledIndex,
      phase: phase,
    )?.position;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _unitSpriteController?.loadIfNeeded();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _flowPhase = (_flowPhase + dt * _flowSpeed) % 10000.0;
    _syncUnitGhostAnimation();
    _unitSpriteController?.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (points.length < 2) return;
    final emphasisPaint = _emphasisLayerPaint;
    if (emphasisPaint != null) {
      canvas.saveLayer(null, emphasisPaint);
    }

    if (showTargetPulse || showConfirmedTarget) {
      _drawTargetHexOutline(canvas);
    }

    final travelledIndex = travelledUpToIndex < 0
        ? 0
        : math.min(travelledUpToIndex, points.length - 1);

    for (var i = 1; i < points.length; i++) {
      if (i <= travelledIndex) {
        _drawDashedSegment(canvas, points[i - 1], points[i], i);
      } else {
        _drawLitSegment(canvas, points[i - 1], points[i], i);
      }
    }

    _drawStartRing(canvas);

    for (var i = 1; i < points.length - 1; i++) {
      if (i > travelledIndex) {
        _drawWaypointNode(canvas, i);
      }
    }

    _drawTravellingMarker(canvas, travelledIndex);
    _drawTargetRing(canvas);
    _drawDestinationMarker(canvas);
    if (showTargetArrow) {
      _drawTargetArrow(canvas);
    }
    if (emphasisPaint != null) {
      canvas.restore();
    }
  }

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
    final phase = _flowPhase % (_travelledDashLength + _travelledGapLength);
    _drawDashedPath(
      canvas,
      path,
      _routePaintForPoint(
        _isTradeRoute
            ? _style.tradeRouteMutedGlowPaint
            : _style.travelledShadowPaint,
        index,
      ),
      dashLength: _travelledDashLength,
      gapLength: _travelledGapLength,
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
      dashLength: _travelledDashLength,
      gapLength: _travelledGapLength,
      phase: phase,
    );
  }

  void _drawLitSegment(Canvas canvas, Vector2 from, Vector2 to, int index) {
    final path = _linePath(from, to);
    final phase = (_flowPhase + index * 3.5) % _routeDashPattern;
    _drawDashedPath(
      canvas,
      path,
      _routePaintForPoint(_edgePaintForPoint(index), index),
      dashLength: _routeDashLength,
      gapLength: _routeGapLength,
      phase: phase,
    );
    _drawDashedPath(
      canvas,
      path,
      _routePaintForPoint(_linePaintForPoint(index), index),
      dashLength: _routeDashLength,
      gapLength: _routeGapLength,
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

  void _syncUnitGhostAnimation() {
    final spriteController = _unitSpriteController;
    if (spriteController == null) return;
    final sample = _routeSample(_clampedTravelledIndex);
    if (sample == null) {
      spriteController.playIdle();
      return;
    }
    final direction = Vector2(math.cos(sample.angle), math.sin(sample.angle));
    spriteController.playWalkToward(from: Vector2.zero(), to: direction);
  }

  int get _clampedTravelledIndex => travelledUpToIndex < 0
      ? 0
      : math.min(travelledUpToIndex, points.length - 1);

  ({Offset position, double angle})? _routeSample(
    int startIndex, {
    double? phase,
  }) {
    if (startIndex >= points.length - 1) return null;

    final route = Path()..moveTo(points[startIndex].x, points[startIndex].y);
    for (var i = startIndex + 1; i < points.length; i++) {
      route.lineTo(points[i].x, points[i].y);
    }

    final metrics = route.computeMetrics().toList(growable: false);
    final length = metrics.fold<double>(
      0,
      (total, metric) => total + metric.length,
    );
    if (length < 8) return null;

    final markerDistance = ((phase ?? _flowPhase) * 0.82) % length;
    var consumed = 0.0;
    for (final metric in metrics) {
      if (markerDistance > consumed + metric.length) {
        consumed += metric.length;
        continue;
      }

      final tangent = metric.getTangentForOffset(markerDistance - consumed);
      if (tangent == null) return null;
      return (position: tangent.position, angle: tangent.angle);
    }
    return null;
  }

  void _drawTravellingMarker(Canvas canvas, int startIndex) {
    final sample = _routeSample(startIndex);
    if (sample == null) return;

    final glow = _glowColorForPoint(points.length - 1);
    final sprite = _unitSpriteController?.sprite;

    if (sprite == null || !sprite.isReady) {
      _drawFallbackRouteCircle(
        canvas,
        center: sample.position,
        color: _colorForPoint(points.length - 1),
        glow: glow,
      );
      return;
    }

    _drawUnitGhost(canvas, sprite: sprite, center: sample.position);
  }

  void _drawDestinationMarker(Canvas canvas) {
    final end = points.last;
    final center = end.toOffset();
    _drawFallbackRouteCircle(
      canvas,
      center: center,
      color: _colorForPoint(points.length - 1),
      glow: _glowColorForPoint(points.length - 1),
      radius: 9.0,
      alpha: MapAlpha.solid,
    );
  }

  void _drawTargetHexOutline(Canvas canvas) {
    final path = _targetHexPath();
    final pulse = 0.5 + 0.5 * math.sin(_flowPhase / _pulsePeriod * 2 * math.pi);
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
    final phase = _flowPhase / _pulsePeriod * 2 * math.pi;
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

  void _drawFallbackRouteCircle(
    Canvas canvas, {
    required Offset center,
    required Color color,
    required Color glow,
    double radius = 10.5,
    int alpha = MapAlpha.strong,
  }) {
    final pulse = 0.5 + 0.5 * math.sin(_flowPhase / _pulsePeriod * 2 * math.pi);
    canvas
      ..drawCircle(
        center,
        radius + 4.0 + pulse * 1.0,
        HudPaint.fill(glow, alpha: MapAlpha.soft)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawCircle(center, radius, HudPaint.fill(color, alpha: alpha))
      ..drawCircle(
        center,
        radius - 3.5,
        HudPaint.fill(HudPalette.gold, alpha: MapAlpha.strong),
      )
      ..drawCircle(
        center,
        radius + 1.5,
        HudPaint.stroke(
          HudPalette.gold,
          alpha: MapAlpha.solid,
          strokeWidth: MapStroke.thin,
        ),
      );
  }

  void _drawUnitGhost(
    Canvas canvas, {
    required UnitSpriteComponent sprite,
    required Offset center,
  }) {
    final size = sprite.sizeFor(onCity: true);
    final width = size.width;
    final height = size.height;
    const scale = 0.78;

    final destination = Rect.fromCenter(
      center: Offset(center.dx, center.dy - height * scale * 0.30),
      width: width * scale,
      height: height * scale,
    );
    sprite
      ..size.setValues(destination.width, destination.height)
      ..paint = (HudPaint.fill(HudPalette.textBright, alpha: MapAlpha.solid)
        ..filterQuality = FilterQuality.medium);

    canvas.save();
    if (sprite.isMirrored) {
      canvas
        ..translate(destination.right, destination.top)
        ..scale(-1, 1);
    } else {
      canvas.translate(destination.left, destination.top);
    }
    sprite.render(canvas);
    canvas.restore();
  }

  void _drawWaypointNode(Canvas canvas, int index) {
    final center = points[index].toOffset();
    final pulse =
        0.5 + 0.5 * math.sin(_flowPhase / _pulsePeriod * 2 * math.pi + index);
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
    final pulse = 0.5 + 0.5 * math.sin(_flowPhase / _pulsePeriod * 2 * math.pi);

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
        0.5 + 0.5 * math.sin(_flowPhase / _pulsePeriod * 2 * math.pi + 1.4);

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
    _clampedTravelledIndex + _focusedForwardHexes,
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
      if (delta <= _focusedForwardHexes) return 1.0;
      return math.max(
        _minRouteStrokeScale,
        1.0 - (delta - _focusedForwardHexes) * _frontRouteStrokeFalloff,
      );
    }

    return math.max(
      _minRouteStrokeScale,
      _nearBackRouteStrokeScale + delta * _backRouteStrokeFalloff,
    );
  }

  bool _isReachablePoint(int index) {
    final cumulativeCost = index < cumulativeCosts.length
        ? cumulativeCosts[index]
        : totalCost;
    return cumulativeCost <= availableMovementPoints;
  }
}
