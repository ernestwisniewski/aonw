part of 'city_territory_overlay.dart';

extension _CityTerritoryOverlayCache on CityTerritoryOverlay {
  void _pruneBoundaryCache(List<CityTerritory> territories) {
    if (territories.isEmpty) {
      _boundaryPathCache.clear();
      _boundaryBoundsCache.clear();
      return;
    }
    final liveSignatures = {
      for (final territory in territories) territory.hexesSignature,
    };
    _boundaryPathCache.removeWhere((key, _) => !liveSignatures.contains(key));
    _boundaryBoundsCache.removeWhere((key, _) => !liveSignatures.contains(key));
  }

  void _pruneTerritoryStyleCache(List<CityTerritory> territories) {
    if (territories.isEmpty) {
      _territoryStyleCache.clear();
      return;
    }
    final liveColors = {for (final territory in territories) territory.color};
    _territoryStyleCache.removeWhere(
      (key, _) => !liveColors.contains(key.color),
    );
  }

  Path _cachedBoundaryPath(CityTerritory territory) {
    return _boundaryPathCache.putIfAbsent(
      territory.hexesSignature,
      () => _boundaryPath(CityTerritoryBoundary.edgesFor(territory.hexes)),
    );
  }

  // Includes the widest border stroke and blur used by all draw passes.
  Rect _cachedBoundaryBounds(CityTerritory territory) {
    return _boundaryBoundsCache.putIfAbsent(
      territory.hexesSignature,
      () => _cachedBoundaryPath(territory).getBounds().inflate(_cullingMargin),
    );
  }

  bool _isOffscreen(CityTerritory territory, Rect clipBounds) {
    if (clipBounds.isEmpty) return false;
    return !_cachedBoundaryBounds(territory).overlaps(clipBounds);
  }

  _TerritoryRenderStyle _renderStyleFor(Color color) {
    final key = _TerritoryRenderStyleKey(color, strategicView);
    return _territoryStyleCache.putIfAbsent(
      key,
      () => _TerritoryRenderStyle(color, strategicView: strategicView),
    );
  }

  CityTerritory? _selectedTerritory() {
    for (final territory in territories) {
      if (territory.selected) return territory;
    }
    return null;
  }

  List<CityTerritory> _highlightedEmpireTerritories() {
    return [
      for (final territory in territories)
        if (territory.empireHighlighted) territory,
    ];
  }
}
