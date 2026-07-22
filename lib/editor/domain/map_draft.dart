import 'dart:collection';

import 'package:aonw_core/domain/map_objective_definition.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/map_constraints.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

/// Mutable map state owned exclusively by the map editor.
///
/// It deliberately permits incomplete tile data while a user is painting. Call
/// [freeze] at a persistence boundary to validate it as an immutable
/// [WorldMap]. [toMapData] is the single editor JSON/persistence projection.
final class MapDraft implements MapTileSource<TileData> {
  MapDraft({
    required int cols,
    required int rows,
    required Iterable<TileData> tiles,
    Iterable<MapObjectiveDefinition> objectives = const [],
    this.mapName,
    this.defaultZoom = 1.0,
  }) : _cols = cols,
       _rows = rows,
       _tiles = [for (final tile in tiles) _copyTile(tile)],
       _objectives = List.of(objectives) {
    _validateDimensions();
    _reindex();
  }

  factory MapDraft.fromMapData(MapData mapData) {
    return MapDraft(
      cols: mapData.cols,
      rows: mapData.rows,
      tiles: mapData.tiles,
      objectives: mapData.objectives,
      mapName: mapData.mapName,
      defaultZoom: mapData.defaultZoom,
    );
  }

  factory MapDraft.filled({
    required int cols,
    required int rows,
    required TerrainType defaultTerrain,
  }) {
    return MapDraft(
      cols: cols,
      rows: rows,
      tiles: [
        for (var row = 0; row < rows; row++)
          for (var col = 0; col < cols; col++)
            TileData(
              col: col,
              row: row,
              terrains: [defaultTerrain],
              resources: const [],
              height: 0,
            ),
      ],
    );
  }

  int _cols;
  int _rows;
  final List<TileData> _tiles;
  final List<MapObjectiveDefinition> _objectives;
  final Map<(int, int), int> _tileIndices = {};
  String? mapName;
  double defaultZoom;

  @override
  int get cols => _cols;

  @override
  int get rows => _rows;

  @override
  List<TileData> get tiles => UnmodifiableListView(_tiles);

  List<MapObjectiveDefinition> get objectives =>
      UnmodifiableListView(_objectives);

  @override
  TileData? tileAt(int col, int row) {
    final index = _tileIndices[(col, row)];
    return index == null ? null : _tiles[index];
  }

  bool updateTile({
    required int col,
    required int row,
    required Iterable<TerrainType> terrains,
    required Iterable<ResourceType> resources,
    required int height,
  }) {
    final index = _tileIndices[(col, row)];
    if (index == null) return false;
    _tiles[index] = TileData(
      col: col,
      row: row,
      terrains: List.unmodifiable(terrains),
      resources: List.unmodifiable(resources),
      height: height,
    );
    return true;
  }

  bool clearTerrainsAt(int col, int row) {
    final tile = tileAt(col, row);
    if (tile == null || tile.terrains.isEmpty) return tile != null;
    return updateTile(
      col: col,
      row: row,
      terrains: const [],
      resources: tile.resources,
      height: tile.height,
    );
  }

  bool removeObjectiveAt(int col, int row) {
    final initialLength = _objectives.length;
    _objectives.removeWhere(
      (objective) => objective.hex.col == col && objective.hex.row == row,
    );
    return _objectives.length != initialLength;
  }

  void placeObjective(MapObjectiveDefinition objective) {
    removeObjectiveAt(objective.hex.col, objective.hex.row);
    _objectives
      ..add(objective)
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  bool addColumn({required Iterable<TerrainType> terrains}) {
    if (_cols >= MapConstraints.maxCols) return false;
    final terrainValues = List<TerrainType>.of(terrains);
    final newCol = _cols;
    for (var row = 0; row < _rows; row++) {
      _tiles.add(
        TileData(
          col: newCol,
          row: row,
          terrains: List.unmodifiable(terrainValues),
          resources: const [],
          height: 0,
        ),
      );
    }
    _cols++;
    _reindex();
    return true;
  }

  bool removeColumn() {
    if (_cols <= MapConstraints.minCols) return false;
    final maxColExclusive = _cols - 1;
    _tiles.removeWhere((tile) => tile.col >= maxColExclusive);
    _cols = maxColExclusive;
    _removeObjectivesOutsideBounds();
    _reindex();
    return true;
  }

  bool addRow({required Iterable<TerrainType> terrains}) {
    if (_rows >= MapConstraints.maxRows) return false;
    final terrainValues = List<TerrainType>.of(terrains);
    final newRow = _rows;
    for (var col = 0; col < _cols; col++) {
      _tiles.add(
        TileData(
          col: col,
          row: newRow,
          terrains: List.unmodifiable(terrainValues),
          resources: const [],
          height: 0,
        ),
      );
    }
    _rows++;
    _reindex();
    return true;
  }

  bool removeRow() {
    if (_rows <= MapConstraints.minRows) return false;
    final maxRowExclusive = _rows - 1;
    _tiles.removeWhere((tile) => tile.row >= maxRowExclusive);
    _rows = maxRowExclusive;
    _removeObjectivesOutsideBounds();
    _reindex();
    return true;
  }

  MapData toMapData({String? mapName}) {
    return MapData(
      cols: _cols,
      rows: _rows,
      tiles: [for (final tile in _tiles) _copyTile(tile)],
      objectives: _objectives,
      mapName: mapName ?? this.mapName,
      defaultZoom: defaultZoom,
    );
  }

  WorldMap freeze({String? mapName}) {
    return WorldMap.fromTileViews(
      cols: _cols,
      rows: _rows,
      tiles: _tiles,
      objectives: _objectives,
      mapName: mapName ?? this.mapName,
      defaultZoom: defaultZoom,
    );
  }

  void _validateDimensions() {
    if (_cols <= 0 || _rows <= 0) {
      throw ArgumentError.value(
        '$_cols x $_rows',
        'dimensions',
        'Map draft dimensions must be positive',
      );
    }
  }

  void _reindex() {
    _tileIndices.clear();
    for (var index = 0; index < _tiles.length; index++) {
      final tile = _tiles[index];
      if (tile.col < 0 ||
          tile.col >= _cols ||
          tile.row < 0 ||
          tile.row >= _rows) {
        throw ArgumentError.value(
          tile,
          'tiles',
          'Tile coordinates must stay inside the draft bounds',
        );
      }
      if (_tileIndices.putIfAbsent((tile.col, tile.row), () => index) !=
          index) {
        throw ArgumentError.value(
          tile,
          'tiles',
          'Map draft cannot contain duplicate tile coordinates',
        );
      }
    }
  }

  void _removeObjectivesOutsideBounds() {
    _objectives.removeWhere(
      (objective) =>
          objective.hex.col < 0 ||
          objective.hex.col >= _cols ||
          objective.hex.row < 0 ||
          objective.hex.row >= _rows,
    );
  }
}

TileData _copyTile(TileData tile) {
  return TileData(
    col: tile.col,
    row: tile.row,
    terrains: List.unmodifiable(tile.terrains),
    resources: List.unmodifiable(tile.resources),
    height: tile.height,
  );
}
