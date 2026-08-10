part of 'unit_move_preview.dart';

extension _UnitMovePreviewMotion on UnitMovePreview {
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

  void _drawFallbackRouteCircle(
    Canvas canvas, {
    required Offset center,
    required Color color,
    required Color glow,
    double radius = 10.5,
    int alpha = MapAlpha.strong,
  }) {
    final pulse =
        0.5 +
        0.5 * math.sin(_flowPhase / UnitMovePreview._pulsePeriod * 2 * math.pi);
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
        HudPaint.fill(color, alpha: MapAlpha.strong),
      )
      ..drawCircle(
        center,
        radius + 1.5,
        HudPaint.stroke(
          color,
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
}
