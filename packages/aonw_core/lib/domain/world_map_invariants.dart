import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/map_objective_definition.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

typedef WorldMapInvariantViolation = Never Function(String message);

/// Validates map-wide invariants and builds the canonical coordinate index.
///
/// The returned map borrows tile values while owning an immutable index. This
/// keeps validation independent of both [WorldTile] and legacy [WorldTile]
/// representations.
Map<HexCoord, TTile> buildValidatedWorldMapIndex<TTile extends MapTileView>({
  required int cols,
  required int rows,
  required double defaultZoom,
  required Iterable<TTile> tiles,
  required Iterable<MapObjectiveDefinition> objectives,
  required WorldMapInvariantViolation reject,
}) {
  _validateMapMetadata(
    cols: cols,
    rows: rows,
    defaultZoom: defaultZoom,
    reject: reject,
  );

  final index = <HexCoord, TTile>{};
  for (final tile in tiles) {
    validateWorldMapTile(
      terrains: tile.terrains,
      height: tile.height,
      reject: reject,
    );
    final coordinate = HexCoord(col: tile.col, row: tile.row);
    _validateCoordinate(
      coordinate,
      cols: cols,
      rows: rows,
      subject: 'Tile',
      reject: reject,
    );
    if (index.containsKey(coordinate)) {
      reject('Duplicate tile at $coordinate');
    }
    index[coordinate] = tile;
  }

  _validateObjectives(
    cols: cols,
    rows: rows,
    objectives: objectives,
    tilesByCoordinate: index,
    reject: reject,
  );
  return Map.unmodifiable(index);
}

/// Validates the invariants owned by one tile independently of a map.
void validateWorldMapTile({
  required Iterable<TerrainType> terrains,
  required int height,
  required WorldMapInvariantViolation reject,
}) {
  if (terrains.isEmpty) {
    reject('Tile terrains must not be empty');
  }
  if (height < 0 || height > 5) {
    reject('Tile height $height out of range [0, 5]');
  }
}

void _validateMapMetadata({
  required int cols,
  required int rows,
  required double defaultZoom,
  required WorldMapInvariantViolation reject,
}) {
  if (cols <= 0) {
    reject('Map cols must be positive, got $cols');
  }
  if (rows <= 0) {
    reject('Map rows must be positive, got $rows');
  }
  if (!defaultZoom.isFinite || defaultZoom <= 0) {
    reject('Map default zoom must be finite and positive, got $defaultZoom');
  }
}

void _validateCoordinate(
  HexCoord coordinate, {
  required int cols,
  required int rows,
  required String subject,
  required WorldMapInvariantViolation reject,
}) {
  if (coordinate.col < 0 || coordinate.col >= cols) {
    reject('$subject col ${coordinate.col} out of range [0, $cols)');
  }
  if (coordinate.row < 0 || coordinate.row >= rows) {
    reject('$subject row ${coordinate.row} out of range [0, $rows)');
  }
}

void _validateObjectives({
  required int cols,
  required int rows,
  required Iterable<MapObjectiveDefinition> objectives,
  required Map<HexCoord, Object?> tilesByCoordinate,
  required WorldMapInvariantViolation reject,
}) {
  final ids = <String>{};
  final coordinates = <HexCoord>{};
  for (final objective in objectives) {
    if (objective.id.trim().isEmpty) {
      reject('Objective id must not be empty');
    }
    if (!ids.add(objective.id)) {
      reject('Duplicate objective id: ${objective.id}');
    }
    _validateCoordinate(
      objective.hex,
      cols: cols,
      rows: rows,
      subject: 'Objective ${objective.id}',
      reject: reject,
    );
    if (!tilesByCoordinate.containsKey(objective.hex)) {
      reject('Objective ${objective.id} has no tile at ${objective.hex}');
    }
    if (!coordinates.add(objective.hex)) {
      reject('Duplicate objective at ${objective.hex}');
    }
    if (objective.requiredHoldTurns <= 0) {
      reject('Objective ${objective.id} hold turns must be positive');
    }
    if (objective.victoryPoints < 0 || objective.goldPerTurn < 0) {
      reject('Objective ${objective.id} rewards must be non-negative');
    }
  }
}
