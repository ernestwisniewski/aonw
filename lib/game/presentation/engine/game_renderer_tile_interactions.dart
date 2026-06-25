part of 'game_renderer.dart';

extension GameRendererTileInteractions on GameRenderer {
  Future<void> _handleTileTapped(TileData tileData) async {
    if (_shouldSuppressTapAfterLongPress()) return;
    final selectedId = _renderState.selectedUnitId;
    if (selectedId != null &&
        _unitAnimationController.isUnitAnimating(selectedId)) {
      _artifactTapCycle.clear();
      return;
    }
    final pending = _renderState.pendingAction;
    if (pending is PendingCityExpansionSelection) {
      _artifactTapCycle.clear();
      await onCommand(
        SelectCityExpansionHexCommand(
          pending.cityId,
          tileData.col,
          tileData.row,
        ),
      );
      return;
    }
    if (_selectedUnitOnCityCenter(tileData) &&
        _handleStackedMapObjectTap(
          this,
          tileData.col,
          tileData.row,
          includeTileInspection: true,
          preferCityUnitTerrainCycle: true,
        )) {
      return;
    }
    if (_selectedTileIsCityCenter(tileData)) {
      _artifactTapCycle.clear();
      await onCommand(TileTappedCommand(tileData.col, tileData.row));
      return;
    }
    if (_selectionMatchesTile(tileData) &&
        _handleStackedMapObjectTap(
          this,
          tileData.col,
          tileData.row,
          includeTileInspection: true,
          preferOccupiedHexCycle: true,
        )) {
      return;
    }
    _artifactTapCycle.clear();
    await onCommand(TileTappedCommand(tileData.col, tileData.row));
  }

  bool _selectionMatchesTile(TileData tileData) {
    return _selectionMatchesTileCoordinates(tileData.col, tileData.row);
  }

  bool _selectedUnitOnCityCenter(TileData tileData) {
    final selected = _renderState.selectedUnit;
    if (selected == null ||
        selected.col != tileData.col ||
        selected.row != tileData.row) {
      return false;
    }
    return _renderState.citiesKnownToActivePlayer.any(
      (city) =>
          city.center.col == tileData.col && city.center.row == tileData.row,
    );
  }

  bool _selectedTileIsCityCenter(TileData tileData) {
    final selection = _renderState.selection;
    if (selection?.type != GameSelectionType.tile ||
        selection?.tile?.col != tileData.col ||
        selection?.tile?.row != tileData.row) {
      return false;
    }
    return _renderState.citiesKnownToActivePlayer.any(
      (city) =>
          city.center.col == tileData.col && city.center.row == tileData.row,
    );
  }

  bool _selectionMatchesTileCoordinates(int col, int row) {
    final selectedTile = _renderState.selection?.tile;
    return selectedTile != null &&
        selectedTile.col == col &&
        selectedTile.row == row;
  }

  void _handleTileInspected(TileData tileData, {Offset? anchor}) {
    onTileInspected?.call(
      _visibleTileForActivePlayer(tileData),
      anchor ?? _inspectionAnchorForTile(tileData),
    );
  }

  void _handleTileInspectionPreviewed(TileData tileData, {Offset? anchor}) {
    final onPreview = onTileInspectionPreviewed;
    if (onPreview != null) {
      onPreview(
        _visibleTileForActivePlayer(tileData),
        anchor ?? _inspectionAnchorForTile(tileData),
      );
      return;
    }
    _handleTileInspected(tileData, anchor: anchor);
  }

  TileData _visibleTileForActivePlayer(TileData tileData) {
    return ResourceVisibilityRules.visibleTile(
      tile: tileData,
      playerId: _renderState.activePlayerId,
      research: _renderState.research,
    );
  }

  void _handleCityMarkerTapped(GameCity city) {
    if (_shouldSuppressTapAfterLongPress()) return;
    if (_markerTapTargetsHex()) {
      _artifactTapCycle.clear();
      _cityTapTracker.clear();
      unawaited(onCommand(TileTappedCommand(city.center.col, city.center.row)));
      return;
    }

    final current = _renderState.selection;
    final unitOnCity = _renderState.unitAt(city.center.col, city.center.row);
    final onThisCity =
        current?.type == GameSelectionType.city && current?.city?.id == city.id;
    final onUnitHere =
        current?.type == GameSelectionType.unit &&
        current?.unit?.col == city.center.col &&
        current?.unit?.row == city.center.row;
    final onThisTile =
        current?.type == GameSelectionType.tile &&
        current?.tile?.col == city.center.col &&
        current?.tile?.row == city.center.row;
    final shouldInspectObject =
        (onThisCity && unitOnCity == null) || onUnitHere || onThisTile;
    if (onThisCity && unitOnCity != null) {
      _artifactTapCycle.clear();
      _cityTapTracker.clear();
      unawaited(onCommand(CityTappedCommand(city.id)));
      return;
    }
    if (onUnitHere &&
        _handleStackedMapObjectTap(
          this,
          city.center.col,
          city.center.row,
          includeTileInspection: true,
          preferCityUnitTerrainCycle: true,
        )) {
      _cityTapTracker.clear();
      return;
    }
    if (shouldInspectObject &&
        _handleStackedMapObjectTap(this, city.center.col, city.center.row)) {
      return;
    }

    _artifactTapCycle.clear();
    final doubleTap = _cityTapTracker.registerTap(city.id);
    if (_isReady) _focusCity(city);
    _lastFocusedSelectionKey = 'city:${city.id}';
    if (doubleTap) {
      unawaited(_selectCityAndOpenDescription(city));
    } else {
      unawaited(onCommand(CityTappedCommand(city.id)));
    }
  }

  Future<void> _selectCityAndOpenDescription(GameCity city) async {
    await onCommand(SelectCityCommand(city.id));
    if (_isDisposed) return;
    onCityDescriptionRequested?.call(city);
  }

  void _handleUnitMarkerTapped(String unitId) =>
      _handleRendererUnitMarkerTapped(this, unitId);

  void _handleArtifactMarkerTapped(WorldArtifact artifact) =>
      _handleRendererArtifactMarkerTapped(this, artifact);

  void _handleMapObjectiveMarkerTapped(MapObjectiveProgress progress) =>
      _handleRendererMapObjectiveMarkerTapped(this, progress);

  bool _shouldSuppressTapAfterLongPress() => _suppressTapsUntilNextPointerDown;

  void _handlePreviewWorkerImprovement(String unitId, String optionId) {
    final type = _fieldImprovementTypeById(optionId);
    if (type == null) return;
    unawaited(onCommand(SelectWorkerImprovementCommand(unitId, type)));
  }

  void _handleConfirmWorkerImprovement(String unitId) {
    unawaited(onCommand(ConfirmWorkerImprovementCommand(unitId)));
  }

  void _handleCancelWorkerActionSelection(String unitId) {
    unawaited(onCommand(CancelWorkerActionSelectionCommand(unitId)));
  }

  void _handleConfirmMovePreview(int col, int row) {
    unawaited(onCommand(TileTappedCommand(col, row)));
  }

  FieldImprovementType? _fieldImprovementTypeById(String optionId) {
    for (final type in FieldImprovementType.values) {
      if (type.name == optionId) return type;
    }
    return null;
  }

  bool _markerTapTargetsHex() {
    final pendingAction = _renderState.pendingAction;
    return _renderState.moveCommandActive ||
        _renderState.cityFoundingDraft != null ||
        pendingAction is PendingWorkerActionSelection;
  }
}
