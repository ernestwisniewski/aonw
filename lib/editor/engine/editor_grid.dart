import 'dart:async';

import 'package:aonw/editor/domain/editor_map_objective_factory.dart';
import 'package:aonw/editor/engine/editor_state.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/hex_grid_topology.dart';
import 'package:aonw/map/domain/map_constraints.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/hex_tile.dart';
import 'package:aonw/map/rendering/hex_tile_markers.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

class EditorGrid extends HexGrid {
  EditorState editorState;

  /// Called when a tile is tapped with its coordinates.
  /// The screen uses this to sync the toolbar to the tile's current values.
  final void Function(int col, int row)? onTileSelected;
  final VoidCallback? onObjectivesChanged;

  ({int col, int row})? _lastPainted;
  ({int col, int row})? _selectedTileCoords;

  @override
  HexTile buildTileComponent({
    required TileData tileData,
    required Vector2 position,
    required void Function() onTapped,
    required List<int?> neighborHeights,
    required List<int?> outlineNeighborHeights,
  }) {
    // Editor always shows icons and depth rendering regardless of view mode,
    // so the terrain is always clearly readable.
    return HexTile(
      hexRadius: config.hexRadius,
      terrains: tileData.terrains,
      resources: tileData.resources,
      tileHeight: tileData.height,
      neighborHeights: neighborHeights,
      outlineNeighborHeights: outlineNeighborHeights,
      outlineOnlyTopFace: viewMode.usesOutlineHexes,
      showIcon: true,
      showTerrain: displaySettings.showTerrain,
      showResources: displaySettings.showResources,
      showCitySites: displaySettings.showCitySites,
      showCityGrowth: displaySettings.showCityGrowth,
      alwaysShowHeight: true,
      showHeightBadge: displaySettings.showHeightBadge,
      showMovementBlockerOverlay: true,
      movementBlocked: _blocksWarriorMovement(tileData),
      liftOnSelect: false,
      outlineColor: displaySettings.hexBorderColor,
      selectionColor: displaySettings.selectedHexColor,
      wallTintColor: displaySettings.wallTintColor,
      markers: markersForTile(tileData),
      position: position,
      onTapped: onTapped,
    );
  }

  @override
  HexTileMarkers markersForTile(TileData tileData) {
    return HexTileMarkers(
      canFoundCity: CitySiteRules.canFoundCityOn(tileData),
      canGrowCity: CityTileYieldRules.canCityControlTile(tileData),
    );
  }

  static bool _blocksWarriorMovement(TileData tileData) {
    final cost = UnitMovementCostRules.costToEnterTile(
      tileData,
      unitType: GameUnitType.warrior,
    );
    if (cost.blocked) return true;
    return cost.value >
        UnitMovementBalance.maxMovementPointsForType(GameUnitType.warrior);
  }

  /// O(1) lookup from (col, row) to the live HexTile component.
  final Map<(int, int), HexTile> _tileComponents = {};
  final Map<(int, int), int> _tileIndices = {};
  final Map<(int, int), int> _heightMap = {};

  EditorGrid({
    required super.mapData,
    required super.config,
    required this.editorState,
    this.onTileSelected,
    this.onObjectivesChanged,
    super.viewMode = MapViewMode.tile,
    super.displaySettings,
  });

  void _ensureTileIndex() {
    if (_tileIndices.length == mapData.tiles.length &&
        _heightMap.length == mapData.tiles.length) {
      return;
    }
    _reindexTiles();
  }

  void _reindexTiles() {
    _tileIndices.clear();
    _heightMap.clear();
    for (int i = 0; i < mapData.tiles.length; i++) {
      final tile = mapData.tiles[i];
      final key = (tile.col, tile.row);
      _tileIndices[key] = i;
      _heightMap[key] = tile.height;
    }
  }

  @override
  ({int col, int row})? get selectedTileCoords => _selectedTileCoords;

  void startPaintStroke() {
    _lastPainted = null;
  }

  /// Called by [EditorWorld] with the world-space position from a tap or drag.
  void paintAtWorld(Vector2 worldPosition) => _paintAt(worldPosition);

  void endPaintStroke() {
    _lastPainted = null;
  }

  void _paintAt(Vector2 worldPosition) {
    // Convert world position to this component's local space.
    // absoluteToLocal handles the perspectiveY scale (0.62) from HexGrid.
    final localPos = absoluteToLocal(worldPosition);
    final hit = HexGeometry.tileAt(
      point: localPos,
      hexRadius: config.hexRadius,
      cols: mapData.cols,
      rows: mapData.rows,
    );
    if (hit == null) return;
    if (_lastPainted != null &&
        _lastPainted!.col == hit.col &&
        _lastPainted!.row == hit.row) {
      return;
    }
    _lastPainted = hit;
    _selectedTileCoords = (col: hit.col, row: hit.row);
    _applyState(hit.col, hit.row);
  }

  /// Tap on a tile: select it visually and sync toolbar to its stored values.
  void _paintTile(int col, int row) {
    if (_selectedTileCoords case final prev?) {
      _tileComponents[(prev.col, prev.row)]?.deselect();
    }
    _tileComponents[(col, row)]?.select();
    _selectedTileCoords = (col: col, row: row);

    // Notify screen so toolbar syncs to this tile's stored values.
    // The screen will call repaintSelected() after syncing editorState.
    onTileSelected?.call(col, row);
  }

  /// Applies the current editorState to the selected tile's data and rebuilds its component.
  /// Called by EditorWorld when the toolbar changes.
  void repaintSelected() {
    final coords = _selectedTileCoords;
    if (coords == null) return;
    _applyState(coords.col, coords.row);
  }

  bool clearSelectedTerrains() {
    final coords = _selectedTileCoords;
    if (coords == null) return false;
    _ensureTileIndex();
    final key = (coords.col, coords.row);
    final index = _tileIndices[key];
    if (index == null) return false;

    final tile = mapData.tiles[index];
    if (tile.terrains.isEmpty) return true;

    mapData.tiles[index] = tile.copyWith(terrains: const []);
    _rebuildTileComponent(coords.col, coords.row);
    return true;
  }

  void _applyState(int col, int row) {
    _ensureTileIndex();
    final key = (col, row);
    final index = _tileIndices[key];
    if (index == null) return;

    final newTile = mapData.tiles[index].copyWith(
      terrains: editorState.selectedTerrains.toList(),
      resources: editorState.selectedResources.toList(),
      height: editorState.selectedHeight,
    );
    mapData.tiles[index] = newTile;
    _heightMap[key] = newTile.height;

    _applyObjective(col, row);
    _rebuildTileComponent(col, row);

    // Rebuild adjacent tiles so walls and hidden top outlines stay consistent
    // when height changes.
    for (final (nc, nr) in _outlineAffectedNeighbors(col, row)) {
      _rebuildTileComponent(nc, nr);
    }
  }

  void _applyObjective(int col, int row) {
    switch (editorState.objectivePaintMode) {
      case EditorObjectivePaintMode.none:
        return;
      case EditorObjectivePaintMode.erase:
        if (_removeObjectiveAt(col, row)) onObjectivesChanged?.call();
      case EditorObjectivePaintMode.place:
        final type = editorState.selectedObjectiveType;
        if (type == null) return;
        _placeObjective(col, row, type);
        onObjectivesChanged?.call();
    }
  }

  bool _removeObjectiveAt(int col, int row) {
    final retained = [
      for (final objective in mapData.objectives)
        if (objective.hex.col != col || objective.hex.row != row) objective,
    ];
    if (retained.length == mapData.objectives.length) return false;
    mapData.objectives = retained;
    return true;
  }

  void _placeObjective(int col, int row, MapObjectiveType type) {
    final next = [
      for (final objective in mapData.objectives)
        if (objective.hex.col != col || objective.hex.row != row) objective,
      EditorMapObjectiveFactory.build(type: type, col: col, row: row),
    ]..sort((a, b) => a.id.compareTo(b.id));
    mapData.objectives = next;
  }

  void _rebuildTileComponent(int col, int row) {
    _ensureTileIndex();
    final index = _tileIndices[(col, row)];
    if (index == null) return;

    final tileData = mapData.tiles[index];
    final tilePos = HexGeometry.tilePosition(
      col: col,
      row: row,
      hexRadius: config.hexRadius,
    );

    final existing = _tileComponents[(col, row)];
    if (existing != null) remove(existing);

    final neighbors = neighborHeights(col, row, _heightMap);
    final outlineNeighbors = outlineNeighborHeights(col, row, _heightMap);
    final component = buildTileComponent(
      tileData: tileData,
      position: tilePos,
      neighborHeights: neighbors,
      outlineNeighborHeights: outlineNeighbors,
      onTapped: () => _paintTile(col, row),
    );
    if (_selectedTileCoords?.col == col && _selectedTileCoords?.row == row) {
      component.select();
    }
    _tileComponents[(col, row)] = component;
    unawaited(Future<void>.value(add(component)));
  }

  List<(int, int)> _outlineAffectedNeighbors(int col, int row) =>
      HexGridTopology.neighbors(
        col: col,
        row: row,
      ).map((hex) => (hex.col, hex.row)).toList(growable: false);

  /// Adds a column to the right filled with the currently selected terrain.
  void addColumn() {
    if (mapData.cols >= MapConstraints.maxCols) return;
    final newCol = mapData.cols;
    for (int row = 0; row < mapData.rows; row++) {
      mapData.tiles.add(
        TileData(
          col: newCol,
          row: row,
          terrains: editorState.selectedTerrains.toList(),
          resources: [],
          height: 0,
        ),
      );
    }
    mapData.cols++;
    rebuild();
  }

  /// Removes the rightmost column.
  void removeColumn() {
    if (mapData.cols <= MapConstraints.minCols) return;
    mapData.tiles.removeWhere((t) => t.col == mapData.cols - 1);
    final nextObjectives = _objectivesInsideBounds(
      maxColExclusive: mapData.cols - 1,
      maxRowExclusive: mapData.rows,
    );
    mapData.cols--;
    if (nextObjectives.length != mapData.objectives.length) {
      mapData.objectives = nextObjectives;
      onObjectivesChanged?.call();
    }
    rebuild();
  }

  /// Adds a row at the bottom filled with the currently selected terrain.
  void addRow() {
    if (mapData.rows >= MapConstraints.maxRows) return;
    final newRow = mapData.rows;
    for (int col = 0; col < mapData.cols; col++) {
      mapData.tiles.add(
        TileData(
          col: col,
          row: newRow,
          terrains: editorState.selectedTerrains.toList(),
          resources: [],
          height: 0,
        ),
      );
    }
    mapData.rows++;
    rebuild();
  }

  /// Removes the bottom row.
  void removeRow() {
    if (mapData.rows <= MapConstraints.minRows) return;
    mapData.tiles.removeWhere((t) => t.row == mapData.rows - 1);
    final nextObjectives = _objectivesInsideBounds(
      maxColExclusive: mapData.cols,
      maxRowExclusive: mapData.rows - 1,
    );
    mapData.rows--;
    if (nextObjectives.length != mapData.objectives.length) {
      mapData.objectives = nextObjectives;
      onObjectivesChanged?.call();
    }
    rebuild();
  }

  List<MapObjectiveDefinition> _objectivesInsideBounds({
    required int maxColExclusive,
    required int maxRowExclusive,
  }) {
    return [
      for (final objective in mapData.objectives)
        if (objective.hex.col >= 0 &&
            objective.hex.col < maxColExclusive &&
            objective.hex.row >= 0 &&
            objective.hex.row < maxRowExclusive)
          objective,
    ];
  }

  /// Clears all HexTile components and re-adds them from current mapData.
  @override
  void rebuild() {
    _lastPainted = null;
    _selectedTileCoords = null;
    _tileComponents.clear();
    _reindexTiles();
    removeWhere((c) => c is HexTile);
    final tiles = <HexTile>[];
    for (final tileData in mapData.tiles) {
      final pos = HexGeometry.tilePosition(
        col: tileData.col,
        row: tileData.row,
        hexRadius: config.hexRadius,
      );
      final col = tileData.col;
      final row = tileData.row;
      final neighbors = neighborHeights(col, row, _heightMap);
      final outlineNeighbors = outlineNeighborHeights(col, row, _heightMap);
      final tile = buildTileComponent(
        tileData: tileData,
        position: pos,
        neighborHeights: neighbors,
        outlineNeighborHeights: outlineNeighbors,
        onTapped: () => _paintTile(col, row),
      );
      _tileComponents[(col, row)] = tile;
      tiles.add(tile);
    }
    addTilesSorted(tiles);
  }
}
