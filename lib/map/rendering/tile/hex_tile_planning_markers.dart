part of 'hex_tile_painter.dart';

extension _HexTilePlanningMarkers on HexTilePainter {
  void _drawWorkerBuildBorder(
    Canvas canvas,
    HexTileGeometrySnapshot geometry, {
    required Color color,
    required Color glow,
    required MapIntentGlyph glyph,
  }) {
    final path = _innerTopPath(geometry, scale: 0.82);
    canvas
      ..drawPath(
        path,
        HudPaint.stroke(
            glow,
            alpha: MapAlpha.regular,
            strokeWidth: MapStroke.glow,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(
        path,
        HudPaint.stroke(
            Colors.black,
            alpha: MapAlpha.strong,
            strokeWidth: MapStroke.bold,
          )
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(
        path,
        HudPaint.stroke(
            color,
            alpha: MapAlpha.opaque,
            strokeWidth: MapStroke.regular + 0.5,
          )
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    _drawIntentBadge(
      canvas,
      geometry.topCenter.translate(0, 8),
      color: color,
      glow: glow,
      glyph: glyph,
    );
  }

  void _drawWorkerImprovementCandidateMarker(
    Canvas canvas,
    HexTileGeometrySnapshot geometry,
  ) {
    final path = _innerTopPath(geometry, scale: 0.68);
    canvas
      ..drawPath(path, _paintWorkerImprovementCandidateFill)
      ..drawPath(path, _paintWorkerImprovementCandidateBorder);
  }

  void _drawWorkerTechnologyCandidateMarker(
    Canvas canvas,
    HexTileGeometrySnapshot geometry,
  ) {
    final path = _innerTopPath(geometry, scale: 0.61);
    canvas
      ..drawPath(path, _paintWorkerImprovementTechFill)
      ..drawPath(path, _paintWorkerImprovementTechBorder);
  }

  Path _innerTopPath(
    HexTileGeometrySnapshot geometry, {
    required double scale,
  }) {
    final center = geometry.topCenter;
    final corners = geometry.topCorners
        .map((corner) {
          return Offset(
            center.dx + (corner.x - center.dx) * scale,
            center.dy + (corner.y - center.dy) * scale,
          );
        })
        .toList(growable: false);
    final path = Path()..moveTo(corners.first.dx, corners.first.dy);
    for (final corner in corners.skip(1)) {
      path.lineTo(corner.dx, corner.dy);
    }
    return path..close();
  }

  void _drawPlanningMarkers({
    required Canvas canvas,
    required HexTileGeometrySnapshot geometry,
    required bool avoidMapInfo,
    required bool showCitySiteMarker,
    required bool showRecommendedCitySiteMarker,
    required bool showCityGrowthMarker,
    required bool showWorkerImprovementNowMarker,
    required bool showWorkerImprovementTechMarker,
    required bool showWorkerImprovementCandidateMarker,
    required bool showAttackTargetMarker,
  }) {
    if (showAttackTargetMarker) {
      canvas.drawPath(geometry.topPath, _paintAttackTargetMarker);
      return;
    }
    final hexRadius = _hexRadiusFor(geometry);
    final cityAnchor = avoidMapInfo
        ? geometry.topCenter.translate(hexRadius * 0.16, -hexRadius * 0.55)
        : geometry.topCenter.translate(0, -6);
    final cityMarkerCenters = _cityPlanningMarkerCenters(
      topCenter: cityAnchor,
      showCitySiteMarker: showCitySiteMarker,
      showCityGrowthMarker: showCityGrowthMarker,
    );
    if (showCitySiteMarker) {
      _drawCitySiteMarker(
        canvas,
        cityMarkerCenters.citySite!,
        recommended: showRecommendedCitySiteMarker,
      );
    }
    if (showCityGrowthMarker) {
      _drawCityGrowthMarker(canvas, cityMarkerCenters.cityGrowth!);
    }
    if (showWorkerImprovementNowMarker &&
        !showWorkerImprovementCandidateMarker) {
      _drawWorkerImprovementMarker(
        canvas,
        geometry.topCenter.translate(-9, 13),
        _paintWorkerImprovementNowMarker,
      );
    }
    if (showWorkerImprovementTechMarker) {
      _drawWorkerTechnologyCandidateMarker(canvas, geometry);
    }
  }

  double _hexRadiusFor(HexTileGeometrySnapshot geometry) {
    final center = geometry.topCenter;
    final corner = geometry.topCorners.first;
    final dx = corner.x - center.dx;
    final dy = corner.y - center.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  ({Offset? citySite, Offset? cityGrowth}) _cityPlanningMarkerCenters({
    required Offset topCenter,
    required bool showCitySiteMarker,
    required bool showCityGrowthMarker,
  }) {
    if (showCitySiteMarker && showCityGrowthMarker) {
      const offset =
          (MapIntentMarker.defaultBadgeSize +
              HexTilePainter._intentMarkerPairGap) /
          2;
      return (
        citySite: topCenter.translate(-offset, 0),
        cityGrowth: topCenter.translate(offset, 0),
      );
    }
    if (showCitySiteMarker) {
      return (citySite: topCenter, cityGrowth: null);
    }
    if (showCityGrowthMarker) {
      return (citySite: null, cityGrowth: topCenter);
    }
    return (citySite: null, cityGrowth: null);
  }

  void _drawCitySiteMarker(
    Canvas canvas,
    Offset center, {
    required bool recommended,
  }) {
    if (!recommended) {
      canvas
        ..drawCircle(center, 6.5, _paintCitySiteCompactFill)
        ..drawCircle(center, 6.5, _paintCitySiteCompactBorder);
      MapIntentMarker.paintGlyph(
        canvas,
        center,
        MapIntentGlyph.city,
        scale: 0.72,
      );
      return;
    }
    _drawIntentBadge(
      canvas,
      center,
      color: HudPalette.successLight,
      glow: HudPalette.success,
      backgroundColor: HudPalette.success,
      borderColor: HudPalette.successLight,
      glyph: MapIntentGlyph.city,
    );
  }

  void _drawCityGrowthMarker(Canvas canvas, Offset center) {
    _drawIntentBadge(
      canvas,
      center,
      color: _paintCityGrowthMarker.color,
      glow: HudPalette.success,
      glyph: MapIntentGlyph.growth,
    );
  }

  void _drawWorkerImprovementMarker(
    Canvas canvas,
    Offset center,
    Paint markerPaint,
  ) {
    _drawIntentBadge(
      canvas,
      center,
      color: markerPaint.color,
      glow: markerPaint.color,
      glyph: MapIntentGlyph.improve,
      size: MapIntentMarker.compactBadgeSize,
    );
  }

  void _drawIntentBadge(
    Canvas canvas,
    Offset center, {
    required Color color,
    required Color glow,
    required MapIntentGlyph glyph,
    Color? backgroundColor,
    Color? borderColor,
    double size = MapIntentMarker.defaultBadgeSize,
  }) {
    MapIntentMarker.paintBadge(
      canvas,
      center,
      color: color,
      glow: glow,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      glyph: glyph,
      size: size,
    );
  }
}
