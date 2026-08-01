import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/map_objective_definition.dart';
import 'package:aonw_core/domain/world_map_invariants.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_source.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

export 'package:aonw_core/map/domain/map_read_view.dart';
export 'package:aonw_core/map/domain/map_tile_source.dart';
export 'package:aonw_core/map/domain/map_tile_view.dart';

final class WorldMapException implements Exception {
  const WorldMapException(this.message);

  final String message;

  @override
  String toString() => 'WorldMapException: $message';
}

/// Immutable terrain and resource data for one world coordinate.
final class WorldTile implements MapTileView {
  factory WorldTile({
    required int col,
    required int row,
    required Iterable<TerrainType> terrains,
    required Iterable<ResourceType> resources,
    required int height,
  }) => WorldTile._owned(
    col: col,
    row: row,
    terrains: terrains,
    resources: resources,
    height: height,
  );

  factory WorldTile.at({
    required HexCoord coordinate,
    required Iterable<TerrainType> terrains,
    required Iterable<ResourceType> resources,
    required int height,
  }) => WorldTile._owned(
    col: coordinate.col,
    row: coordinate.row,
    terrains: terrains,
    resources: resources,
    height: height,
  );

  WorldTile._owned({
    required this.col,
    required this.row,
    required Iterable<TerrainType> terrains,
    required Iterable<ResourceType> resources,
    required this.height,
  }) : terrains = List.unmodifiable(terrains),
       resources = List.unmodifiable(resources);

  @override
  final int col;

  @override
  final int row;

  HexCoord get coordinate => HexCoord(col: col, row: row);

  @override
  final List<TerrainType> terrains;

  @override
  final List<ResourceType> resources;

  @override
  final int height;

  @override
  TerrainType get primaryTerrain =>
      terrains.isEmpty ? TerrainType.ocean : terrains.first;

  WorldTile copyWith({
    Iterable<TerrainType>? terrains,
    Iterable<ResourceType>? resources,
    int? height,
  }) {
    return WorldTile(
      col: col,
      row: row,
      terrains: List.unmodifiable(terrains ?? this.terrains),
      resources: List.unmodifiable(resources ?? this.resources),
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toJson() => {
    'col': col,
    'row': row,
    'terrains': terrains.map((terrain) => terrain.name).toList(),
    'resources': resources.map((resource) => resource.name).toList(),
    'height': height,
  };
}

/// Immutable, sparse world map with constant-time coordinate lookup.
final class WorldMap implements MapReadView, MapTileSource<WorldTile> {
  static const Object _unset = Object();

  WorldMap({
    required this.cols,
    required this.rows,
    required Iterable<WorldTile> tiles,
    Iterable<MapObjectiveDefinition> objectives = const [],
    this.mapName,
    this.defaultZoom = 1.0,
  }) : tiles = List.unmodifiable(tiles.map(_worldTileFromView)),
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
    final sourceTiles = List<MapTileView>.of(tiles);
    for (final tile in sourceTiles) {
      validateWorldMapTile(
        terrains: tile.terrains,
        height: tile.height,
        reject: _rejectWorldMapInvariant,
      );
    }
    return WorldMap(
      cols: cols,
      rows: rows,
      tiles: sourceTiles.map(_worldTileFromView),
      objectives: objectives,
      mapName: mapName,
      defaultZoom: defaultZoom,
    );
  }

  @override
  final int cols;
  @override
  final int rows;
  @override
  final List<WorldTile> tiles;
  @override
  final List<MapObjectiveDefinition> objectives;
  @override
  final String? mapName;
  final double defaultZoom;
  late final Map<HexCoord, WorldTile> _tilesByCoordinate;

  int get indexedTileCount => _tilesByCoordinate.length;

  @override
  int get tileCount => indexedTileCount;

  @override
  MapTileLookup get mapTiles => this;

  @override
  Iterable<WorldTile> get tileViews => tiles;

  @override
  Iterable<Iterable<TerrainType>> get tileTerrains =>
      tiles.map((tile) => tile.terrains);

  @override
  WorldTile? tileAt(int col, int row) =>
      _tilesByCoordinate[HexCoord(col: col, row: row)];

  /// Canonical coordinate lookup for clients that own a [HexCoord].
  WorldTile? tileAtHex(HexCoord coordinate) => _tilesByCoordinate[coordinate];

  WorldMap copyWith({
    int? cols,
    int? rows,
    Iterable<WorldTile>? tiles,
    Iterable<MapObjectiveDefinition>? objectives,
    Object? mapName = _unset,
    double? defaultZoom,
  }) {
    return WorldMap(
      cols: cols ?? this.cols,
      rows: rows ?? this.rows,
      tiles: tiles ?? this.tiles,
      objectives: objectives ?? this.objectives,
      mapName: identical(mapName, _unset) ? this.mapName : mapName as String?,
      defaultZoom: defaultZoom ?? this.defaultZoom,
    );
  }
}

WorldTile _worldTileFromView(MapTileView tile) {
  return WorldTile._owned(
    col: tile.col,
    row: tile.row,
    terrains: tile.terrains,
    resources: tile.resources,
    height: tile.height,
  );
}

Never _rejectWorldMapInvariant(String message) {
  throw WorldMapException(message);
}
