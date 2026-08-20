part of 'game_renderer.dart';

extension GameRendererTileInteractions on GameRenderer {
  Future<void> _handleTileTapped(WorldTile tileData) async {
    if (_shouldSuppressTapAfterLongPress()) return;
    final selectedId = _renderState.selectedUnitId;
    if (selectedId != null &&
        _unitAnimationController.isUnitAnimating(selectedId)) {
      _mapTapCycle.clear();
      return;
    }
    final pending = _renderState.pendingAction;
    if (pending is PendingCityExpansionSelection) {
      _mapTapCycle.clear();
      await onCommand(TileTappedCommand(tileData.col, tileData.row));
      return;
    }
    if (_handleCityOrImprovementTerrainCycle(tileData)) return;
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
    _mapTapCycle.clear();
    await onCommand(TileTappedCommand(tileData.col, tileData.row));
  }

  bool _selectionMatchesTile(WorldTile tileData) {
    return _selectionMatchesTileCoordinates(tileData.col, tileData.row);
  }

  bool _selectionMatchesTileCoordinates(int col, int row) {
    final selectedTile = _renderState.selection?.tile;
    return selectedTile != null &&
        selectedTile.col == col &&
        selectedTile.row == row;
  }

  void _handleTileInspected(WorldTile tileData, {Offset? anchor}) {
    onTileInspected?.call(
      _visibleTileForActivePlayer(tileData),
      anchor ?? inspectionAnchorForTile(tileData),
    );
  }

  void _handleTileInspectionPreviewed(WorldTile tileData, {Offset? anchor}) {
    final onPreview = onTileInspectionPreviewed;
    if (onPreview != null) {
      onPreview(
        _visibleTileForActivePlayer(tileData),
        anchor ?? inspectionAnchorForTile(tileData),
      );
      return;
    }
    _handleTileInspected(tileData, anchor: anchor);
  }

  WorldTile _visibleTileForActivePlayer(WorldTile tileData) {
    return ResourceVisibilityRules.visibleTile(
      tile: tileData,
      playerId: _renderState.activePlayerId,
      research: _renderState.research,
    );
  }

  void _handleUnitMarkerTapped(String unitId) =>
      _handleRendererUnitMarkerTapped(this, unitId);

  void _handleArtifactMarkerTapped(WorldArtifact artifact) =>
      _handleRendererArtifactMarkerTapped(this, artifact);

  void _handleMapObjectiveMarkerTapped(MapObjectiveProgress progress) =>
      _handleRendererMapObjectiveMarkerTapped(this, progress);

  bool _shouldSuppressTapAfterLongPress() =>
      inputHandler.suppressTapsUntilNextPointerDown;

  void _handlePreviewWorkerImprovement(String unitId, String optionId) {
    final type = _fieldImprovementTypeById(optionId);
    if (type == null) return;
    unawaited(onCommand(ChooseWorkerImprovementIntent(unitId, type)));
  }

  void _handleConfirmWorkerImprovement(String unitId) {
    unawaited(onCommand(ConfirmWorkerImprovementIntent(unitId)));
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
