import 'dart:convert';

import 'package:aonw_core/map/domain/terrain_type.dart';

class MapDefinitionException implements Exception {
  final String message;

  const MapDefinitionException(this.message);

  @override
  String toString() => 'MapDefinitionException: $message';
}

class MapTileDefinition {
  final int col;
  final int row;
  final List<TerrainType> terrains;
  final List<ResourceType> resources;
  final int height;

  MapTileDefinition({
    required this.col,
    required this.row,
    required Iterable<TerrainType> terrains,
    required Iterable<ResourceType> resources,
    required this.height,
  }) : terrains = List.unmodifiable(terrains),
       resources = List.unmodifiable(resources);

  factory MapTileDefinition.fromJson(Map<String, dynamic> json) {
    final terrains = [
      for (final terrain in _requiredList(json, 'TileData', 'terrains'))
        TerrainType.fromName(_requiredStringValue(terrain, 'TileData.terrain')),
    ];
    if (terrains.isEmpty) {
      throw const MapDefinitionException(
        'Tile terrains list must not be empty',
      );
    }
    return MapTileDefinition(
      col: _requiredInt(json, 'TileData', 'col'),
      row: _requiredInt(json, 'TileData', 'row'),
      terrains: terrains,
      resources: [
        for (final resource in _requiredList(json, 'TileData', 'resources'))
          ResourceType.fromName(
            _requiredStringValue(resource, 'TileData.resource'),
          ),
      ],
      height: _requiredInt(json, 'TileData', 'height'),
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

class MapDefinition {
  final int cols;
  final int rows;
  final String? mapName;
  final double defaultZoom;
  final List<MapTileDefinition> tiles;

  MapDefinition({
    required this.cols,
    required this.rows,
    this.mapName,
    this.defaultZoom = 1.0,
    required Iterable<MapTileDefinition> tiles,
  }) : tiles = List.unmodifiable(tiles) {
    _validate();
  }

  factory MapDefinition.fromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<Object?, Object?>) {
      throw const MapDefinitionException('Expected map JSON object');
    }
    return MapDefinition.fromJson(Map<String, dynamic>.from(decoded));
  }

  factory MapDefinition.fromJson(Map<String, dynamic> json) {
    return MapDefinition(
      cols: _requiredInt(json, 'MapDefinition', 'cols'),
      rows: _requiredInt(json, 'MapDefinition', 'rows'),
      mapName: _optionalString(json, 'MapDefinition', 'mapName'),
      defaultZoom: _optionalDouble(json, 'MapDefinition', 'defaultZoom') ?? 1.0,
      tiles: [
        for (final tile in _requiredList(json, 'MapDefinition', 'tiles'))
          MapTileDefinition.fromJson(_requiredMap(tile, 'MapDefinition.tile')),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'cols': cols,
    'rows': rows,
    if (mapName != null) 'mapName': mapName,
    if (defaultZoom != 1.0) 'defaultZoom': defaultZoom,
    'tiles': tiles.map((tile) => tile.toJson()).toList(),
  };

  MapTileDefinition? tileAt(int col, int row) {
    for (final tile in tiles) {
      if (tile.col == col && tile.row == row) return tile;
    }
    return null;
  }

  void _validate() {
    if (cols <= 0) {
      throw MapDefinitionException('Map cols must be positive, got $cols');
    }
    if (rows <= 0) {
      throw MapDefinitionException('Map rows must be positive, got $rows');
    }
    for (final tile in tiles) {
      if (tile.col < 0 || tile.col >= cols) {
        throw MapDefinitionException(
          'Tile col ${tile.col} out of range [0, $cols)',
        );
      }
      if (tile.row < 0 || tile.row >= rows) {
        throw MapDefinitionException(
          'Tile row ${tile.row} out of range [0, $rows)',
        );
      }
      if (tile.height < 0 || tile.height > 5) {
        throw MapDefinitionException(
          'Tile height ${tile.height} out of range [0, 5]',
        );
      }
    }
  }
}

int _requiredInt(Map<String, dynamic> json, String type, String field) {
  final value = json[field];
  if (value is int) return value;
  throw MapDefinitionException('Expected int field: $type.$field');
}

String _requiredStringValue(Object? value, String field) {
  if (value is String && value.isNotEmpty) return value;
  throw MapDefinitionException('Expected non-empty string value: $field');
}

String? _optionalString(Map<String, dynamic> json, String type, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return value;
  throw MapDefinitionException('Expected non-empty string field: $type.$field');
}

double? _optionalDouble(Map<String, dynamic> json, String type, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is num) return value.toDouble();
  throw MapDefinitionException('Expected number field: $type.$field');
}

List<dynamic> _requiredList(
  Map<String, dynamic> json,
  String type,
  String field,
) {
  final value = json[field];
  if (value is List<dynamic>) return value;
  throw MapDefinitionException('Expected list field: $type.$field');
}

Map<String, dynamic> _requiredMap(Object? value, String field) {
  if (value is Map<Object?, Object?>) return Map<String, dynamic>.from(value);
  throw MapDefinitionException('Expected object field: $field');
}
