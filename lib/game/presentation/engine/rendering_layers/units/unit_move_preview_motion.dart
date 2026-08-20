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

    final route = _routePathFrom(startIndex);
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

    final sprite = _unitSpriteController?.sprite;

    if (sprite == null || !sprite.isReady) {
      _drawTravellingFallback(canvas, sample.position);
      return;
    }

    _drawUnitGhost(canvas, sprite: sprite, center: sample.position);
  }

  void _drawDestinationMarker(Canvas canvas) {
    final center = points.last.toOffset();
    if (_destinationIsReachableThisTurn) {
      _drawRouteBoundaryDot(canvas, center, emphasized: true);
      return;
    }
    canvas
      ..drawCircle(
        center,
        7.0,
        HudPaint.fill(HudPalette.roadMarking, alpha: MapAlpha.whisper)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
      )
      ..drawCircle(
        center,
        3.2,
        HudPaint.fill(HudPalette.roadMarking, alpha: MapAlpha.full),
      );
  }

  bool get _destinationIsReachableThisTurn {
    final destinationIndex = points.length - 1;
    return destinationIndex > _clampedTravelledIndex &&
        _isReachablePoint(destinationIndex);
  }

  void _drawTravellingFallback(Canvas canvas, Offset center) {
    canvas
      ..drawCircle(
        center,
        9.0,
        HudPaint.fill(HudPalette.roadMarking, alpha: MapAlpha.soft)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
      )
      ..drawCircle(
        center,
        5.0,
        HudPaint.fill(HudPalette.roadMarking, alpha: MapAlpha.full),
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
