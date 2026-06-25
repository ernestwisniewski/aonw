import 'dart:convert';

import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

class MapDataLoadException implements Exception {
  const MapDataLoadException(this.message);

  final String message;

  @override
  String toString() => 'MapDataLoadException: $message';
}

abstract final class MapDataCodec {
  static MapData fromJson(String jsonString) {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;

      if (!map.containsKey('cols')) {
        throw const MapDataLoadException('Missing field: cols');
      }
      if (!map.containsKey('rows')) {
        throw const MapDataLoadException('Missing field: rows');
      }
      if (!map.containsKey('tiles')) {
        throw const MapDataLoadException('Missing field: tiles');
      }

      final cols = map['cols'] as int;
      final rows = map['rows'] as int;
      final tilesJson = map['tiles'] as List<dynamic>;
      final mapName = map['mapName'] as String?;
      final objectivesJson = (map['objectives'] as List<dynamic>?) ?? const [];

      final tiles = tilesJson.map((entry) {
        final tile = entry as Map<String, dynamic>;
        try {
          final terrains = (tile['terrains'] as List<dynamic>)
              .map((value) => TerrainType.fromString(value as String))
              .toList();
          final resources = (tile['resources'] as List<dynamic>)
              .map((value) => ResourceType.fromString(value as String))
              .toList();

          if (terrains.isEmpty) {
            throw const MapDataLoadException(
              'Tile terrains list must not be empty',
            );
          }

          return TileData(
            col: tile['col'] as int,
            row: tile['row'] as int,
            terrains: terrains,
            resources: resources,
            height: tile['height'] as int,
          );
        } on MapDataLoadException {
          rethrow;
        } on ArgumentError catch (error) {
          throw MapDataLoadException(error.message.toString());
        }
      }).toList();

      for (final tile in tiles) {
        if (tile.col < 0 || tile.col >= cols) {
          throw MapDataLoadException(
            'Tile col ${tile.col} out of range [0, $cols)',
          );
        }
        if (tile.row < 0 || tile.row >= rows) {
          throw MapDataLoadException(
            'Tile row ${tile.row} out of range [0, $rows)',
          );
        }
        if (tile.height < 0 || tile.height > 5) {
          throw MapDataLoadException(
            'Tile height ${tile.height} out of range [0, 5]',
          );
        }
      }

      final defaultZoom = (map['defaultZoom'] as num?)?.toDouble() ?? 1.0;
      return MapData(
        cols: cols,
        rows: rows,
        tiles: tiles,
        objectives: objectivesJson.map((entry) {
          if (entry is! Map<String, dynamic>) {
            throw const MapDataLoadException(
              'Map objective entries must be JSON objects',
            );
          }
          return MapObjectiveDefinition.fromJson(entry);
        }),
        mapName: mapName,
        defaultZoom: defaultZoom,
      );
    } on MapDataLoadException {
      rethrow;
    } catch (error) {
      throw MapDataLoadException('Failed to parse map JSON: $error');
    }
  }

  static String toJson(MapData mapData) {
    final map = <String, dynamic>{
      'cols': mapData.cols,
      'rows': mapData.rows,
      if (mapData.mapName != null) 'mapName': mapData.mapName,
      if (mapData.defaultZoom != 1.0) 'defaultZoom': mapData.defaultZoom,
      if (mapData.objectives.isNotEmpty)
        'objectives': [
          for (final objective in mapData.objectives) objective.toJson(),
        ],
      'tiles': mapData.tiles.map((tile) => tile.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }
}
