part of 'game_renderer.dart';

extension GameRendererEntityTaps on GameRenderer {
  bool _handleCityOrImprovementTerrainCycle(WorldTile tileData) {
    final entityKey = _cityOrImprovementKeyAt(tileData);
    if (entityKey == null) return false;

    if (_selectedTerrainAt(tileData)) {
      _mapTapCycle.clear();
      unawaited(onCommand(TileTappedCommand(tileData.col, tileData.row)));
      return true;
    }

    final selectedPrimaryEntity = _selectedCityOrImprovementAt(tileData);
    if (selectedPrimaryEntity && _hasUnitAt(tileData)) {
      _mapTapCycle.clear();
      return false;
    }
    if (!selectedPrimaryEntity && !_selectedUnitAt(tileData)) return false;

    final targets = <MapTapTarget>[
      if (onTileInspected != null) MapTapTarget.tileInspection,
      MapTapTarget.hex,
    ];
    final target = _mapTapCycle.nextStackTarget(
      'terrain:$entityKey',
      targets: targets,
      preferredFirstTarget: onTileInspected == null
          ? MapTapTarget.hex
          : MapTapTarget.tileInspection,
    );
    if (target == MapTapTarget.tileInspection) {
      _handleTileInspected(tileData);
    } else {
      unawaited(onCommand(SelectTileCommand(tileData.col, tileData.row)));
    }
    return true;
  }

  bool _selectedTerrainAt(WorldTile tileData) {
    final selection = _renderState.selection;
    final selectedTile = selection?.tile;
    return selection?.type == GameSelectionType.tile &&
        selectedTile?.col == tileData.col &&
        selectedTile?.row == tileData.row;
  }

  bool _selectedCityOrImprovementAt(WorldTile tileData) {
    final selection = _renderState.selection;
    if (selection?.type == GameSelectionType.city) {
      return selection?.city?.occupiesCenter(tileData.col, tileData.row) ==
          true;
    }
    return selection?.type == GameSelectionType.fieldImprovement &&
        selection?.fieldImprovement?.occupies(tileData.col, tileData.row) ==
            true;
  }

  bool _selectedUnitAt(WorldTile tileData) {
    final selection = _renderState.selection;
    return selection?.type == GameSelectionType.unit &&
        selection?.unit?.col == tileData.col &&
        selection?.unit?.row == tileData.row;
  }

  bool _hasUnitAt(WorldTile tileData) {
    return _renderState.unitAt(tileData.col, tileData.row) != null;
  }

  String? _cityOrImprovementKeyAt(WorldTile tileData) {
    for (final city in _renderState.citiesKnownToActivePlayer) {
      if (city.occupiesCenter(tileData.col, tileData.row)) {
        return 'city:${city.id}';
      }
    }
    for (final improvement in _renderState.fieldImprovements) {
      if (improvement.occupies(tileData.col, tileData.row)) {
        return 'improvement:${tileData.col}:${tileData.row}';
      }
    }
    return null;
  }

  void _handleCityMarkerTapped(GameCity city) {
    if (_shouldSuppressTapAfterLongPress()) return;
    _clearHexSelectionPalette();
    final pending = _renderState.pendingAction;
    if (pending is PendingMerchantTradeRouteSelection ||
        pending is PendingMerchantMoveToCitySelection) {
      _mapTapCycle.clear();
      _mapDoubleTapTracker.clear();
      unawaited(onCommand(CityTappedCommand(city.id)));
      return;
    }
    final tile = mapData.tileAt(city.center.col, city.center.row);
    if (tile == null) return;
    if (_handleRapidSecondTap(tile.col, tile.row)) return;
    unawaited(_handleTileTapped(tile, trackDoubleTap: false));
  }
}
