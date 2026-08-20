part of 'game_renderer.dart';

extension GameRendererHexSelection on GameRenderer {
  void _openHexSelectionPalette(WorldTile tile, {required Offset anchor}) {
    final targets = HexSelectionTargetResolver.resolve(
      state: _renderState,
      mapData: mapData,
      tile: tile,
      l10n: l10n,
    );
    if (targets.isEmpty) return;
    _mapTapCycle.clear();
    _mapDoubleTapTracker.clear();
    onHexSelectionPaletteOpened?.call();
    _hexSelectionPaletteLayer.open(
      parent: world,
      col: tile.col,
      row: tile.row,
      targets: targets,
      directionAngle: _paletteDirectionFor(anchor),
      screenScale: 1 / camera.viewfinder.zoom,
    );
  }

  double _paletteDirectionFor(Offset anchor) {
    final viewport = camera.viewport.size;
    final towardCenter = Offset(
      viewport.x / 2 - anchor.dx,
      viewport.y / 2 - anchor.dy,
    );
    if (towardCenter.distanceSquared < 1) return -math.pi / 2;
    return math.atan2(towardCenter.dy, towardCenter.dx);
  }

  void _handleHexSelectionTargetSelected(HexSelectionTarget target) {
    switch (target) {
      case TerrainHexSelectionTarget(:final tile):
        unawaited(_selectAndInspectTerrain(tile));
      case UnitHexSelectionTarget(:final unit):
        unawaited(onCommand(SelectUnitCommand(unit.id)));
      case CityHexSelectionTarget(:final city):
        unawaited(onCommand(SelectCityCommand(city.id)));
      case FieldImprovementHexSelectionTarget(:final improvement):
        unawaited(
          onCommand(
            SelectFieldImprovementCommand(
              improvement.hex.col,
              improvement.hex.row,
            ),
          ),
        );
      case ArtifactHexSelectionTarget(:final artifact):
        final tile = _tileForArtifactLocation(this, artifact.location);
        if (tile != null) {
          onArtifactInspected?.call(artifact, inspectionAnchorForTile(tile));
        }
      case ObjectiveHexSelectionTarget(:final progress):
        final hex = progress.definition.hex;
        final tile = mapData.tileAt(hex.col, hex.row);
        if (tile != null) {
          onObjectiveInspected?.call(progress, inspectionAnchorForTile(tile));
        }
    }
  }

  Future<void> _selectAndInspectTerrain(WorldTile tile) async {
    await onCommand(SelectTileCommand(tile.col, tile.row));
    _handleTileInspected(tile);
  }

  void _clearHexSelectionPalette() => _hexSelectionPaletteLayer.clear();
}
