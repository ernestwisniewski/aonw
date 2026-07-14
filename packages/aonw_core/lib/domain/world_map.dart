import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/map_objective_definition.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

final class WorldMapException implements Exception {
  const WorldMapException(this.message);

  final String message;

  @override
  String toString() => 'WorldMapException: $message';
}

/// Immutable terrain and resource data for one world coordinate.
final class WorldTile {
  WorldTile({
    required this.coordinate,
    required Iterable<TerrainType> terrains,
    required Iterable<ResourceType> resources,
    required this.height,
  }) : terrains = List.unmodifiable(terrains),
       resources = List.unmodifiable(resources) {
    if (this.terrains.isEmpty) {
      throw const WorldMapException('Tile terrains must not be empty');
    }
    if (height < 0 || height > 5) {
      throw WorldMapException('Tile height $height out of range [0, 5]');
    }
  }

  final HexCoord coordinate;
  final List<TerrainType> terrains;
  final List<ResourceType> resources;
  final int height;

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
    _validateMapMetadata(cols: cols, rows: rows, defaultZoom: defaultZoom);
    _tilesByCoordinate = _buildIndex(cols: cols, rows: rows, tiles: this.tiles);
    _validateObjectives(
      cols: cols,
      rows: rows,
      objectives: this.objectives,
      tilesByCoordinate: _tilesByCoordinate,
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

void _validateMapMetadata({
  required int cols,
  required int rows,
  required double defaultZoom,
}) {
  if (cols <= 0) {
    throw WorldMapException('Map cols must be positive, got $cols');
  }
  if (rows <= 0) {
    throw WorldMapException('Map rows must be positive, got $rows');
  }
  if (!defaultZoom.isFinite || defaultZoom <= 0) {
    throw WorldMapException(
      'Map default zoom must be finite and positive, got $defaultZoom',
    );
  }
}

Map<HexCoord, WorldTile> _buildIndex({
  required int cols,
  required int rows,
  required List<WorldTile> tiles,
}) {
  final index = <HexCoord, WorldTile>{};
  for (final tile in tiles) {
    _validateCoordinate(
      tile.coordinate,
      cols: cols,
      rows: rows,
      subject: 'Tile',
    );
    if (index.containsKey(tile.coordinate)) {
      throw WorldMapException('Duplicate tile at ${tile.coordinate}');
    }
    index[tile.coordinate] = tile;
  }
  return Map.unmodifiable(index);
}

void _validateCoordinate(
  HexCoord coordinate, {
  required int cols,
  required int rows,
  required String subject,
}) {
  if (coordinate.col < 0 || coordinate.col >= cols) {
    throw WorldMapException(
      '$subject col ${coordinate.col} out of range [0, $cols)',
    );
  }
  if (coordinate.row < 0 || coordinate.row >= rows) {
    throw WorldMapException(
      '$subject row ${coordinate.row} out of range [0, $rows)',
    );
  }
}

void _validateObjectives({
  required int cols,
  required int rows,
  required List<MapObjectiveDefinition> objectives,
  required Map<HexCoord, WorldTile> tilesByCoordinate,
}) {
  final ids = <String>{};
  final coordinates = <HexCoord>{};
  for (final objective in objectives) {
    if (objective.id.trim().isEmpty) {
      throw const WorldMapException('Objective id must not be empty');
    }
    if (!ids.add(objective.id)) {
      throw WorldMapException('Duplicate objective id: ${objective.id}');
    }
    _validateCoordinate(
      objective.hex,
      cols: cols,
      rows: rows,
      subject: 'Objective ${objective.id}',
    );
    if (!tilesByCoordinate.containsKey(objective.hex)) {
      throw WorldMapException(
        'Objective ${objective.id} has no tile at ${objective.hex}',
      );
    }
    if (!coordinates.add(objective.hex)) {
      throw WorldMapException('Duplicate objective at ${objective.hex}');
    }
    if (objective.requiredHoldTurns <= 0) {
      throw WorldMapException(
        'Objective ${objective.id} hold turns must be positive',
      );
    }
    if (objective.victoryPoints < 0 || objective.goldPerTurn < 0) {
      throw WorldMapException(
        'Objective ${objective.id} rewards must be non-negative',
      );
    }
  }
}
