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

  void _drawAttackTargetMarker(
    Canvas canvas,
    HexTileGeometrySnapshot geometry,
  ) {
    final path = geometry.topPath;
    final bounds = path.getBounds();
    final center = geometry.topCenter;
    final diagonalReach = bounds.width + bounds.height;
    canvas
      ..drawPath(path, _paintAttackTargetMarker)
      ..save()
      ..clipPath(path);
    for (
      var shift = 0.0;
      shift <= bounds.width;
      shift += HexTilePainter._attackTargetHatchSpacing
    ) {
      canvas.drawLine(
        center.translate(shift - diagonalReach, bounds.height),
        center.translate(shift + diagonalReach, -bounds.height),
        _paintAttackTargetHatch,
      );
      if (shift > 0) {
        canvas.drawLine(
          center.translate(-shift - diagonalReach, bounds.height),
          center.translate(-shift + diagonalReach, -bounds.height),
          _paintAttackTargetHatch,
        );
      }
    }
    canvas.restore();
  }

  void _drawPlanningMarkers({
    required Canvas canvas,
    required HexTileGeometrySnapshot geometry,
    required bool showCitySiteMarker,
    required bool showRecommendedCitySiteMarker,
    required bool showCityGrowthMarker,
    required bool showWorkerImprovementNowMarker,
    required bool showWorkerImprovementTechMarker,
    required bool showWorkerImprovementCandidateMarker,
    required bool showAttackTargetMarker,
  }) {
    if (showAttackTargetMarker) {
      _drawAttackTargetMarker(canvas, geometry);
      return;
    }
    final topVertexY = geometry.topCorners
        .map((corner) => corner.y)
        .reduce((a, b) => math.min(a, b));
    final rightEdgeX = geometry.topCorners
        .map((corner) => corner.x)
        .reduce((a, b) => math.max(a, b));
    const cityMarkerRadius = 6.5;
    final cityMarkerInset = HexTileOverlayGeometry.compactMarkerWallMargin;
    final citySiteAnchor = Offset(
      geometry.topCenter.dx,
      topVertexY + cityMarkerRadius + cityMarkerInset,
    );
    final cityGrowthAnchor = Offset(
      rightEdgeX - cityMarkerRadius - cityMarkerInset,
      geometry.topCenter.dy,
    );
    final cityMarkerCenters = _cityPlanningMarkerCenters(
      citySiteAnchor: citySiteAnchor,
      cityGrowthAnchor: cityGrowthAnchor,
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

  ({Offset? citySite, Offset? cityGrowth}) _cityPlanningMarkerCenters({
    required Offset citySiteAnchor,
    required Offset cityGrowthAnchor,
    required bool showCitySiteMarker,
    required bool showCityGrowthMarker,
  }) {
    if (showCitySiteMarker && showCityGrowthMarker) {
      return (
        citySite: citySiteAnchor,
        cityGrowth: cityGrowthAnchor,
      );
    }
    if (showCitySiteMarker) {
      return (citySite: citySiteAnchor, cityGrowth: null);
    }
    if (showCityGrowthMarker) {
      return (citySite: null, cityGrowth: cityGrowthAnchor);
    }
    return (citySite: null, cityGrowth: null);
  }

  void _drawCitySiteMarker(
    Canvas canvas,
    Offset center, {
    required bool recommended,
  }) {
    if (!recommended) {
      _drawCompactCityIntentMarker(
        canvas,
        center,
        fillColor: _paintCitySiteCompactFill.color,
        borderColor: _paintCitySiteCompactBorder.color,
        glyph: MapIntentGlyph.city,
        glyphScale: 0.72,
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
    _drawCompactCityIntentMarker(
      canvas,
      center,
      fillColor: _paintCitySiteCompactFill.color,
      borderColor: _paintCitySiteCompactBorder.color,
      glyph: MapIntentGlyph.growth,
      glyphScale: 0.72,
    );
  }

  void _drawCompactCityIntentMarker(
    Canvas canvas,
    Offset center, {
    required Color fillColor,
    required Color borderColor,
    required MapIntentGlyph glyph,
    double glyphScale = 0.72,
  }) {
    canvas
      ..drawCircle(center, 6.5, HudPaint.fill(fillColor))
      ..drawCircle(
        center,
        6.5,
        HudPaint.stroke(borderColor, strokeWidth: MapStroke.thin),
      );
    MapIntentMarker.paintGlyph(
      canvas,
      center,
      glyph,
      scale: glyphScale,
      color: HudPalette.goldLight,
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
