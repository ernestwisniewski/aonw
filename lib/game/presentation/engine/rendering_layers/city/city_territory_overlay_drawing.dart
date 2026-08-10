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
            : territory.selected
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
          selected: territory.selected,
        );
      }
    }
  }

  void _drawTerritoryBorders(Canvas canvas, Rect clipBounds) {
    for (final territory in territories) {
      if (_isOffscreen(territory, clipBounds)) continue;
      final boundaryPath = _cachedBoundaryPath(territory);
      final style = _renderStyleFor(territory.color);
      if (!strategicView) {
        _drawTerritoryEdgeBand(
          canvas,
          boundaryPath,
          style,
          selected: territory.selected,
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
    canvas
      ..drawPath(
        boundaryPath,
        style.selectedBorderGlowPaint(
          _emphasizedAlpha(
            _selectedBorderGlowAlpha,
            _selectedBorderGlowAlphaZoomedOut,
          ),
        ),
      )
      ..drawPath(boundaryPath, style.outerBorderPaint)
      ..drawPath(boundaryPath, style.solidBorderPaint)
      ..drawPath(boundaryPath, style.atlasInkBorderPaint)
      ..drawPath(
        boundaryPath,
        style.selectedBorderHighlightPaint(
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

  void _drawMapDimming(Canvas canvas, CityTerritory selectedTerritory) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(
        const Rect.fromLTRB(
          -_mapDimmingExtent,
          -_mapDimmingExtent,
          _mapDimmingExtent,
          _mapDimmingExtent,
        ),
      )
      ..addPath(_cachedBoundaryPath(selectedTerritory), Offset.zero);
    canvas.drawPath(path, _mapDimmingPaint);
  }

  int _emphasizedAlpha(int baseAlpha, int zoomedOutAlpha) {
    return lerpDouble(
      baseAlpha.toDouble(),
      zoomedOutAlpha.toDouble(),
      _zoomEmphasis,
    )!.round();
  }
}
