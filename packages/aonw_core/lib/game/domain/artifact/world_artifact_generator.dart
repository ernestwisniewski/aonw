import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/artifact/world_artifact_type.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/terrain.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class WorldArtifactGenerator {
  static const int artifactCount = 8;
  static const int preferredStartDistance = 4;
  static const int fallbackStartDistance = 2;

  static List<WorldArtifact> generate({
    required MapData mapData,
    required Iterable<GameUnit> startingUnits,
    int? seed,
  }) {
    if (mapData.tiles.isEmpty) return const [];

    final starts = List<GameUnit>.of(startingUnits);
    final occupiedStarts = {
      for (final unit in starts) _key(unit.col, unit.row),
    };
    final objectiveHexes = {
      for (final objective in mapData.objectives)
        _key(objective.hex.col, objective.hex.row),
    };
    final reachableTiles = _reachableTileKeys(mapData, starts);
    final passableTiles = [
      for (final tile in mapData.tiles)
        if (!_isBlocked(tile) &&
            !occupiedStarts.contains(_key(tile.col, tile.row)) &&
            !objectiveHexes.contains(_key(tile.col, tile.row)) &&
            (starts.isEmpty ||
                reachableTiles.contains(_key(tile.col, tile.row))))
          tile,
    ];
    if (passableTiles.isEmpty) return const [];

    final pool = passableTiles;
    final startHexes = [
      for (final unit in starts) HexCoordinate(col: unit.col, row: unit.row),
    ];
    final rng = _ArtifactPlacementRng(seed ?? _seedFromMap(mapData));
    final selected = <TileData>[];

    for (var i = 0; i < WorldArtifactType.values.length; i++) {
      final anchor = _anchorFor(mapData, i);
      final candidates = _candidatePool(
        pool: pool,
        selected: selected,
        startHexes: startHexes,
        minStartDistance: preferredStartDistance,
      );
      final fallbackCandidates = candidates.isEmpty
          ? _candidatePool(
              pool: pool,
              selected: selected,
              startHexes: startHexes,
              minStartDistance: fallbackStartDistance,
            )
          : candidates;
      final finalCandidates = fallbackCandidates.isEmpty
          ? [
              for (final tile in pool)
                if (!selected.any(
                  (picked) => picked.col == tile.col && picked.row == tile.row,
                ))
                  tile,
            ]
          : fallbackCandidates;
      if (finalCandidates.isEmpty) break;

      final picked = _bestTile(
        candidates: finalCandidates,
        anchor: anchor,
        selected: selected,
        startHexes: startHexes,
        rng: rng,
      );
      selected.add(picked);
    }

    return [
      for (var i = 0; i < selected.length && i < artifactCount; i++)
        WorldArtifact.placed(
          type: WorldArtifactType.values[i],
          col: selected[i].col,
          row: selected[i].row,
        ),
    ];
  }

  static List<TileData> _candidatePool({
    required Iterable<TileData> pool,
    required Iterable<TileData> selected,
    required Iterable<HexCoordinate> startHexes,
    required int minStartDistance,
  }) {
    final used = {for (final tile in selected) _key(tile.col, tile.row)};
    return [
      for (final tile in pool)
        if (!used.contains(_key(tile.col, tile.row)) &&
            _distanceToNearestStart(tile, startHexes) >= minStartDistance)
          tile,
    ];
  }

  static TileData _bestTile({
    required List<TileData> candidates,
    required ({int col, int row}) anchor,
    required List<TileData> selected,
    required List<HexCoordinate> startHexes,
    required _ArtifactPlacementRng rng,
  }) {
    final sorted = List<TileData>.of(candidates)
      ..sort((left, right) {
        final score =
            _score(
              right,
              anchor: anchor,
              selected: selected,
              startHexes: startHexes,
              jitter: rng.jitterFor(right.col, right.row),
            ).compareTo(
              _score(
                left,
                anchor: anchor,
                selected: selected,
                startHexes: startHexes,
                jitter: rng.jitterFor(left.col, left.row),
              ),
            );
        if (score != 0) return score;
        final row = left.row.compareTo(right.row);
        if (row != 0) return row;
        return left.col.compareTo(right.col);
      });
    return sorted.first;
  }

  static int _score(
    TileData tile, {
    required ({int col, int row}) anchor,
    required List<TileData> selected,
    required List<HexCoordinate> startHexes,
    required int jitter,
  }) {
    final anchorDistance = _squareDistance(
      tile.col,
      tile.row,
      anchor.col,
      anchor.row,
    );
    final nearestArtifactDistance = selected.isEmpty
        ? 10
        : selected
              .map(
                (picked) => HexDistance.between(
                  HexCoordinate(col: tile.col, row: tile.row),
                  HexCoordinate(col: picked.col, row: picked.row),
                ),
              )
              .reduce((a, b) => a < b ? a : b);
    final startDistance = _distanceToNearestStart(tile, startHexes);
    return _terrainScore(tile) * 12 +
        nearestArtifactDistance * 7 +
        startDistance * 4 -
        anchorDistance +
        jitter;
  }

  static int _terrainScore(TileData tile) {
    final terrains = tile.terrains.toSet();
    var score = tile.height;
    if (terrains.contains(TerrainType.desert)) score += 4;
    if (terrains.contains(TerrainType.jungle)) score += 4;
    if (terrains.contains(TerrainType.hills)) score += 3;
    if (terrains.contains(TerrainType.forest)) score += 3;
    if (terrains.contains(TerrainType.wetlands)) score += 3;
    if (terrains.contains(TerrainType.tundra)) score += 2;
    if (terrains.contains(TerrainType.snow)) score += 2;
    if (terrains.contains(TerrainType.coast)) score += 1;
    return score;
  }

  static ({int col, int row}) _anchorFor(MapData mapData, int index) {
    final cols = mapData.cols > 0 ? mapData.cols : 1;
    final rows = mapData.rows > 0 ? mapData.rows : 1;
    final anchors = <({int col, int row})>[
      (col: cols ~/ 4, row: rows ~/ 4),
      (col: 3 * cols ~/ 4, row: rows ~/ 4),
      (col: cols ~/ 4, row: 3 * rows ~/ 4),
      (col: 3 * cols ~/ 4, row: 3 * rows ~/ 4),
      (col: cols ~/ 2, row: rows ~/ 5),
      (col: cols ~/ 2, row: 4 * rows ~/ 5),
      (col: cols ~/ 5, row: rows ~/ 2),
      (col: 4 * cols ~/ 5, row: rows ~/ 2),
    ];
    return anchors[index % anchors.length];
  }

  static bool _isBlocked(TileData tile) {
    return UnitMovementCostRules.costToEnter(
      TileTerrainProfileRules.fromTile(tile),
    ).blocked;
  }

  static Set<String> _reachableTileKeys(
    MapData mapData,
    Iterable<GameUnit> startingUnits,
  ) {
    final reachable = <String>{};
    for (final unit in startingUnits) {
      final pathfinder = UnitMovementPathfinder(
        mapData: mapData,
        units: const [],
        canEnterTile: (tile) => _canUnitEventuallyEnter(unit, tile),
      );
      final costs = pathfinder.movementCostsFrom(unit: unit);
      for (final coords in costs.keys) {
        reachable.add(_key(coords.col, coords.row));
      }
    }
    return reachable;
  }

  static bool _canUnitEventuallyEnter(GameUnit unit, TileData tile) {
    final cost = UnitMovementCostRules.costToEnterTile(
      tile,
      unitType: unit.type,
    );
    if (cost.blocked) return false;
    if (unit.isCarryingArtifact) return true;
    final maxMovement = UnitMovementBalance.maxMovementPointsFor(
      type: unit.type,
      carriedArtifactId: unit.carriedArtifactId,
    );
    return cost.value <= maxMovement;
  }

  static int _distanceToNearestStart(
    TileData tile,
    Iterable<HexCoordinate> starts,
  ) {
    var best = 9999;
    for (final start in starts) {
      final distance = HexDistance.between(
        HexCoordinate(col: tile.col, row: tile.row),
        start,
      );
      if (distance < best) best = distance;
    }
    return best == 9999 ? 9999 : best;
  }

  static int _squareDistance(int col, int row, int targetCol, int targetRow) {
    final dc = col - targetCol;
    final dr = row - targetRow;
    return dc * dc + dr * dr;
  }

  static int _seedFromMap(MapData mapData) {
    var seed = Object.hash(mapData.cols, mapData.rows, mapData.mapName ?? '');
    for (final tile in mapData.tiles.take(32)) {
      seed = Object.hash(seed, tile.col, tile.row, tile.height);
    }
    return seed;
  }

  static String _key(int col, int row) => '$col:$row';
}

final class _ArtifactPlacementRng {
  static const int _mask32 = 0xFFFFFFFF;
  static const int _multiplier = 1664525;
  static const int _increment = 1013904223;

  final int _state;

  _ArtifactPlacementRng(int seed) : _state = seed & _mask32;

  int jitterFor(int col, int row) {
    var value = (_state ^ (col * 73856093) ^ (row * 19349663)) & _mask32;
    value = (_multiplier * value + _increment) & _mask32;
    return value % 9;
  }
}
