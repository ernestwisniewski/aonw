part of 'city_territory_overlay.dart';

extension _CityTerritoryOverlayDrawing on CityTerritoryOverlay {
  void _drawTerritoryFills(Canvas canvas, Rect clipBounds) {
    for (final territory in territories) {
      if (_isOffscreen(territory, clipBounds)) continue;
      final style = _renderStyleFor(territory.color);
      final fillPaint = HudPaint.fill(
        style.fillColor,
        alpha: strategicView
            ? _tileTerritoryFillAlpha
            : territory.empireHighlighted
            ? _emphasizedAlpha(
                _selectedTerritoryFillAlpha,
                _selectedTerritoryFillAlphaZoomedOut,
              )
            : _emphasizedAlpha(
                _territoryFillAlpha,
                _territoryFillAlphaZoomedOut,
              ),
      );
      final territoryPath = _cachedBoundaryPath(territory);
      canvas.drawPath(territoryPath, fillPaint);
      if (!strategicView) {
        _drawTerritoryInsetWash(
          canvas,
          territoryPath,
          style,
          selected: territory.empireHighlighted,
        );
      }
    }
  }

  void _drawTerritoryBorders(Canvas canvas, Rect clipBounds) {
    for (final territory in territories) {
      if (_isOffscreen(territory, clipBounds)) continue;
      final boundaryPath = _cachedBoundaryPath(territory);
      final style = _renderStyleFor(territory.color);
      if (territory.selected) continue;
      if (!strategicView) {
        _drawTerritoryEdgeBand(
          canvas,
          boundaryPath,
          style,
          selected: territory.empireHighlighted,
        );
      }
      if (strategicView) {
        canvas.drawPath(boundaryPath, style.borderGlowPaint);
      }
      canvas
        ..drawPath(boundaryPath, style.outerBorderPaint)
        ..drawPath(boundaryPath, style.solidBorderPaint)
        ..drawPath(boundaryPath, style.atlasInkBorderPaint)
        ..drawPath(
          boundaryPath,
          style.innerBorderHighlightPaint(
            strategicView
                ? _emphasizedAlpha(MapAlpha.regular, MapAlpha.strong)
                : _emphasizedAlpha(
                    _innerBorderHighlightAlpha,
                    _innerBorderHighlightAlphaZoomedOut,
                  ),
          ),
        );
    }
  }

  void _drawStrategicCityCenters(Canvas canvas, Rect clipBounds) {
    for (final territory in territories) {
      if (_isOffscreen(territory, clipBounds)) continue;
      final center = _hexCenter(territory.center);
      final style = _renderStyleFor(territory.color);
      final ring = _scaledHexPath(territory.center, scale: 0.56);
      canvas
        ..drawPath(ring, style.strategicCenterGlowPaint)
        ..drawPath(ring, _strategicCenterFillPaint)
        ..drawPath(ring, _strategicCenterBorderPaint)
        ..drawPath(ring, style.strategicCenterInnerPaint);
      MapIntentMarker.paintGlyph(
        canvas,
        center,
        MapIntentGlyph.city,
        color: HudPalette.goldLight,
        scale: 1.05,
      );
    }
  }

  void _drawSelectedTerritoryBorder(
    Canvas canvas,
    CityTerritory selectedTerritory,
  ) {
    final boundaryPath = _cachedBoundaryPath(selectedTerritory);
    final style = _renderStyleFor(selectedTerritory.color);
    _drawDashedPath(
      canvas,
      boundaryPath,
      style.selectedBorderGlowPaint(
        _emphasizedAlpha(
          _selectedBorderGlowAlpha,
          _selectedBorderGlowAlphaZoomedOut,
        ),
      ),
    );
    _drawDashedPath(canvas, boundaryPath, style.selectedBorderBackingPaint);
    _drawDashedPath(
      canvas,
      boundaryPath,
      style.selectedPlayerColorBorderPaint(
        _emphasizedAlpha(
          _selectedBorderHighlightAlpha,
          _selectedBorderHighlightAlphaZoomedOut,
        ),
      ),
    );
  }

  void _drawTerritoryInsetWash(
    Canvas canvas,
    Path boundaryPath,
    _TerritoryRenderStyle style, {
    required bool selected,
  }) {
    final washPaint = style.insetWashPaint(
      selected: selected,
      blurred: _zoomEmphasis < _edgeBlurZoomCutoff,
    );
    canvas
      ..save()
      ..clipPath(boundaryPath, doAntiAlias: true)
      ..drawPath(boundaryPath, washPaint)
      ..restore();
  }

  void _drawTerritoryEdgeBand(
    Canvas canvas,
    Path boundaryPath,
    _TerritoryRenderStyle style, {
    required bool selected,
  }) {
    final glowPaint = HudPaint.stroke(
      style.edgeBandColor,
      alpha: selected
          ? _emphasizedAlpha(
              _selectedTerritoryEdgeGlowAlpha,
              _selectedTerritoryEdgeGlowAlphaZoomedOut,
            )
          : _emphasizedAlpha(
              _territoryEdgeGlowAlpha,
              _territoryEdgeGlowAlphaZoomedOut,
            ),
      strokeWidth: selected
          ? _selectedTerritoryEdgeGlowWidth
          : _territoryEdgeGlowWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
    if (_zoomEmphasis < _edgeBlurZoomCutoff) {
      glowPaint.maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        _territoryEdgeBlur,
      );
    }
    canvas
      ..drawPath(boundaryPath, glowPaint)
      ..drawPath(
        boundaryPath,
        HudPaint.stroke(
          style.edgeBandColor,
          alpha: selected
              ? _emphasizedAlpha(
                  _selectedTerritoryEdgeBandAlpha,
                  _selectedTerritoryEdgeBandAlphaZoomedOut,
                )
              : _emphasizedAlpha(
                  _territoryEdgeBandAlpha,
                  _territoryEdgeBandAlphaZoomedOut,
                ),
          strokeWidth: selected
              ? _selectedTerritoryEdgeBandWidth
              : _territoryEdgeBandWidth,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
  }

  void _drawMapDimming(
    Canvas canvas,
    Iterable<CityTerritory> highlightedEmpire,
  ) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(
        const Rect.fromLTRB(
          -_mapDimmingExtent,
          -_mapDimmingExtent,
          _mapDimmingExtent,
          _mapDimmingExtent,
        ),
      );
    for (final territory in highlightedEmpire) {
      path.addPath(_cachedBoundaryPath(territory), Offset.zero);
    }
    canvas.drawPath(path, _mapDimmingPaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _selectedDashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + _selectedDashGapLength;
      }
    }
  }

  int _emphasizedAlpha(int baseAlpha, int zoomedOutAlpha) {
    return lerpDouble(
      baseAlpha.toDouble(),
      zoomedOutAlpha.toDouble(),
      _zoomEmphasis,
    )!.round();
  }
}
