import 'dart:convert';

import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/map_objective_definition.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

class WorldMapLoadException implements Exception {
  const WorldMapLoadException(this.message);

  final String message;

  @override
  String toString() => 'WorldMapLoadException: $message';
}

abstract final class WorldMapCodec {
  static WorldMap fromJson(String jsonString) {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;

      _requireMapField(map, 'cols');
      _requireMapField(map, 'rows');
      _requireMapField(map, 'tiles');

      final cols = map['cols'] as int;
      final rows = map['rows'] as int;
      final tilesJson = map['tiles'] as List<dynamic>;
      final mapName = map['mapName'] as String?;
      final objectivesJson = (map['objectives'] as List<dynamic>?) ?? const [];

      final tiles = tilesJson.map(_decodeWorldTile).toList();
      _validateTileBounds(tiles, cols: cols, rows: rows);

      final defaultZoom = (map['defaultZoom'] as num?)?.toDouble() ?? 1.0;
      return _validateCanonicalMap(
        WorldMap(
          cols: cols,
          rows: rows,
          tiles: tiles,
          objectives: objectivesJson.map(_decodeMapObjective),
          mapName: mapName,
          defaultZoom: defaultZoom,
        ),
      );
    } on WorldMapLoadException {
      rethrow;
    } on WorldMapException catch (error) {
      throw WorldMapLoadException(error.message);
    } catch (error) {
      throw WorldMapLoadException('Failed to parse map JSON: $error');
    }
  }

  static String toJson(WorldMap worldMap) {
    _validateCanonicalMap(worldMap);
    final map = <String, dynamic>{
      'cols': worldMap.cols,
      'rows': worldMap.rows,
      if (worldMap.mapName != null) 'mapName': worldMap.mapName,
      if (worldMap.defaultZoom != 1.0) 'defaultZoom': worldMap.defaultZoom,
      if (worldMap.objectives.isNotEmpty)
        'objectives': [
          for (final objective in worldMap.objectives) objective.toJson(),
        ],
      'tiles': worldMap.tiles.map((tile) => tile.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }
}

void _requireMapField(Map<String, dynamic> map, String field) {
  if (map.containsKey(field)) return;
  throw WorldMapLoadException('Missing field: $field');
}

WorldTile _decodeWorldTile(Object? entry) {
  final tile = entry as Map<String, dynamic>;
  try {
    for (final field in [
      'col',
      'row',
      'terrains',
      'displayTerrain',
      'yieldTerrain',
      'terrainTags',
      'resources',
      'height',
    ]) {
      if (!tile.containsKey(field)) {
        throw WorldMapLoadException('Missing tile field: $field');
      }
    }
    final terrains = (tile['terrains'] as List<dynamic>)
        .map((value) => TerrainType.fromString(value as String))
        .toList();
    final displayTerrain = TerrainType.fromString(
      tile['displayTerrain'] as String,
    );
    final yieldTerrain = TerrainType.fromString(tile['yieldTerrain'] as String);
    final terrainTags = (tile['terrainTags'] as List<dynamic>)
        .map((value) => TerrainType.fromString(value as String))
        .toList();
    final resources = (tile['resources'] as List<dynamic>)
        .map((value) => ResourceType.fromString(value as String))
        .toList();
    if (terrains.isEmpty) {
      throw const WorldMapLoadException('Tile terrains list must not be empty');
    }
    return WorldTile.atWithTerrainSemantics(
      coordinate: HexCoord(col: tile['col'] as int, row: tile['row'] as int),
      terrain: TileTerrainSemantics(
        movementTerrains: terrains,
        displayTerrain: displayTerrain,
        yieldTerrain: yieldTerrain,
        terrainTags: terrainTags,
      ),
      resources: resources,
      height: tile['height'] as int,
    );
  } on WorldMapLoadException {
    rethrow;
  } on ArgumentError catch (error) {
    throw WorldMapLoadException(error.message.toString());
  } on TileTerrainSemanticsException catch (error) {
    throw WorldMapLoadException(error.message);
  }
}

void _validateTileBounds(
  Iterable<WorldTile> tiles, {
  required int cols,
  required int rows,
}) {
  for (final tile in tiles) {
    if (tile.col < 0 || tile.col >= cols) {
      throw WorldMapLoadException(
        'Tile col ${tile.col} out of range [0, $cols)',
      );
    }
    if (tile.row < 0 || tile.row >= rows) {
      throw WorldMapLoadException(
        'Tile row ${tile.row} out of range [0, $rows)',
      );
    }
    if (tile.height < 0 || tile.height > 5) {
      throw WorldMapLoadException(
        'Tile height ${tile.height} out of range [0, 5]',
      );
    }
  }
}

MapObjectiveDefinition _decodeMapObjective(Object? entry) {
  if (entry is Map<String, dynamic>) {
    return MapObjectiveDefinition.fromJson(entry);
  }
  throw const WorldMapLoadException(
    'Map objective entries must be JSON objects',
  );
}

WorldMap _validateCanonicalMap(WorldMap worldMap) {
  try {
    // Re-freezing preserves the validation/error boundary even when a map
    // came from a custom implementation or was constructed in a fixture.
    return WorldMap.fromTileViews(
      cols: worldMap.cols,
      rows: worldMap.rows,
      tiles: worldMap.tiles,
      objectives: worldMap.objectives,
      mapName: worldMap.mapName,
      defaultZoom: worldMap.defaultZoom,
    );
  } on WorldMapException catch (error) {
    throw WorldMapLoadException(error.message);
  }
}
