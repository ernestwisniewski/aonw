import 'dart:async';

import 'package:aonw/editor/domain/editor_map_objective_factory.dart';
import 'package:aonw/editor/domain/map_draft.dart';
import 'package:aonw/editor/engine/editor_state.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/hex_tile.dart';
import 'package:aonw/map/rendering/hex_tile_markers.dart';
import 'package:aonw_core/domain/world_map.dart' show WorldTile;
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

class EditorGrid extends HexGrid<MapDraft> {
  final MapDraft draft;
  EditorState editorState;

  /// Called when a tile is tapped with its coordinates.
  /// The screen uses this to sync the toolbar to the tile's current values.
  final void Function(int col, int row)? onTileSelected;
  final VoidCallback? onObjectivesChanged;

  ({int col, int row})? _lastPainted;
  ({int col, int row})? _selectedTileCoords;

  @override
  HexTile buildTileComponent({
    required WorldTile tileData,
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
  HexTileMarkers markersForTile(WorldTile tileData) {
    return HexTileMarkers(
      canFoundCity: CitySiteRules.canFoundCityOn(tileData),
      canGrowCity: CityTileYieldRules.canCityControlTile(tileData),
    );
  }

  static bool _blocksWarriorMovement(WorldTile tileData) {
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
  final Map<(int, int), int> _heightMap = {};

  EditorGrid({
    required this.draft,
    required super.config,
    required this.editorState,
    this.onTileSelected,
    this.onObjectivesChanged,
    super.viewMode = MapViewMode.tile,
    super.displaySettings,
  }) : super(mapData: draft);

  void _reindexTiles() {
    _heightMap.clear();
    for (final tile in draft.tiles) {
      final key = (tile.col, tile.row);
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
      cols: draft.cols,
      rows: draft.rows,
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
    final tile = draft.tileAt(coords.col, coords.row);
    if (tile == null) return false;
    if (tile.terrains.isEmpty) return true;

    draft.clearTerrainsAt(coords.col, coords.row);
    _rebuildTileComponent(coords.col, coords.row);
    return true;
  }

  void _applyState(int col, int row) {
    final key = (col, row);
    if (!draft.updateTile(
      col: col,
      row: row,
      terrains: editorState.selectedTerrains.toList(),
      resources: editorState.selectedResources.toList(),
      height: editorState.selectedHeight,
    )) {
      return;
    }
    _heightMap[key] = editorState.selectedHeight;

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
    return draft.removeObjectiveAt(col, row);
  }

  void _placeObjective(int col, int row, MapObjectiveType type) {
    draft.placeObjective(
      EditorMapObjectiveFactory.build(type: type, col: col, row: row),
    );
  }

  void _rebuildTileComponent(int col, int row) {
    final tileData = draft.tileAt(col, row);
    if (tileData == null) return;
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
    if (!draft.addColumn(terrains: editorState.selectedTerrains)) return;
    rebuild();
  }

  /// Removes the rightmost column.
  void removeColumn() {
    final objectiveCount = draft.objectives.length;
    if (!draft.removeColumn()) return;
    if (draft.objectives.length != objectiveCount) {
      onObjectivesChanged?.call();
    }
    rebuild();
  }

  /// Adds a row at the bottom filled with the currently selected terrain.
  void addRow() {
    if (!draft.addRow(terrains: editorState.selectedTerrains)) return;
    rebuild();
  }

  /// Removes the bottom row.
  void removeRow() {
    final objectiveCount = draft.objectives.length;
    if (!draft.removeRow()) return;
    if (draft.objectives.length != objectiveCount) {
      onObjectivesChanged?.call();
    }
    rebuild();
  }

  /// Clears all HexTile components and re-adds them from the current draft.
  @override
  void rebuild() {
    _lastPainted = null;
    _selectedTileCoords = null;
    _tileComponents.clear();
    _reindexTiles();
    removeWhere((c) => c is HexTile);
    final tiles = <HexTile>[];
    for (final tileData in draft.tiles) {
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
