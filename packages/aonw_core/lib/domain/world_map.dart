import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/map_objective_definition.dart';
import 'package:aonw_core/domain/world_map_invariants.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

final class WorldMapException implements Exception {
  const WorldMapException(this.message);

  final String message;

  @override
  String toString() => 'WorldMapException: $message';
}

/// Immutable terrain and resource data for one world coordinate.
final class WorldTile implements MapTileView {
  WorldTile({
    required this.coordinate,
    required Iterable<TerrainType> terrains,
    required Iterable<ResourceType> resources,
    required this.height,
  }) : terrains = List.unmodifiable(terrains),
       resources = List.unmodifiable(resources) {
    validateWorldMapTile(
      terrains: this.terrains,
      height: height,
      reject: _rejectWorldMapInvariant,
    );
  }

  final HexCoord coordinate;

  @override
  int get col => coordinate.col;

  @override
  int get row => coordinate.row;

  @override
  final List<TerrainType> terrains;

  @override
  final List<ResourceType> resources;

  @override
  final int height;

  @override
  TerrainType get primaryTerrain => terrains.first;
}

/// Immutable, sparse world map with constant-time coordinate lookup.
final class WorldMap {
  WorldMap({
    required this.cols,
    required this.rows,
    required Iterable<WorldTile> tiles,
    Iterable<MapObjectiveDefinition> objectives = const [],
    this.mapName,
    this.defaultZoom = 1.0,
  }) : tiles = List.unmodifiable(tiles),
       objectives = List.unmodifiable(objectives) {
    _tilesByCoordinate = buildValidatedWorldMapIndex(
      cols: cols,
      rows: rows,
      defaultZoom: defaultZoom,
      tiles: this.tiles,
      objectives: this.objectives,
      reject: _rejectWorldMapInvariant,
    );
  }

  /// Freezes representation-neutral tile views into canonical immutable tiles.
  ///
  /// Tile values are copied before map metadata is validated, preserving the
  /// tile-first error order while preventing later source mutations from
  /// changing this world.
  factory WorldMap.fromTileViews({
    required int cols,
    required int rows,
    required Iterable<MapTileView> tiles,
    Iterable<MapObjectiveDefinition> objectives = const [],
    String? mapName,
    double defaultZoom = 1.0,
  }) {
    return WorldMap(
      cols: cols,
      rows: rows,
      tiles: tiles.map(_worldTileFromView),
      objectives: objectives,
      mapName: mapName,
      defaultZoom: defaultZoom,
    );
  }

  final int cols;
  final int rows;
  final List<WorldTile> tiles;
  final List<MapObjectiveDefinition> objectives;
  final String? mapName;
  final double defaultZoom;
  late final Map<HexCoord, WorldTile> _tilesByCoordinate;

  int get indexedTileCount => _tilesByCoordinate.length;

  WorldTile? tileAt(HexCoord coordinate) => _tilesByCoordinate[coordinate];
}

WorldTile _worldTileFromView(MapTileView tile) {
  return WorldTile(
    coordinate: HexCoord(col: tile.col, row: tile.row),
    terrains: tile.terrains,
    resources: tile.resources,
    height: tile.height,
  );
}

Never _rejectWorldMapInvariant(String message) {
  throw WorldMapException(message);
}
