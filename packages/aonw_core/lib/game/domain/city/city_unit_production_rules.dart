import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class CityUnitProductionRules {
  static GameUnit? produce({
    required GameCity city,
    required GameUnitType unitType,
    required List<GameUnit> units,
    required MapData mapData,
  }) {
    if (!canProduceInCity(city: city, unitType: unitType, mapData: mapData)) {
      return null;
    }

    for (final candidate in _spawnCandidates(city, mapData)) {
      final occupied = units.any(
        (unit) => unit.occupies(candidate.col, candidate.row),
      );
      if (occupied && !_canShareSpawnTile(city, unitType, candidate)) {
        continue;
      }

      if (!_canSpawnUnitOnCandidate(unitType, candidate, mapData)) continue;

      return GameUnit.produced(
        id: _nextProducedUnitId(city, unitType, units),
        ownerPlayerId: city.ownerPlayerId,
        type: unitType,
        col: candidate.col,
        row: candidate.row,
      );
    }

    return null;
  }

  static bool canProduceInCity({
    required GameCity city,
    required GameUnitType unitType,
    required MapData mapData,
  }) {
    if (!unitType.canBeProducedByCities) return false;
    if (!unitType.isNaval) return true;

    return _spawnCandidates(city, mapData).any(
      (candidate) => _canSpawnUnitOnCandidate(unitType, candidate, mapData),
    );
  }

  static bool _canSpawnUnitOnCandidate(
    GameUnitType unitType,
    CityHex candidate,
    MapData mapData,
  ) {
    final tile = mapData.tileAt(candidate.col, candidate.row);
    if (tile == null) return false;
    if (unitType.isNaval && !_isOceanAdjacentCoast(candidate, tile, mapData)) {
      return false;
    }
    return UnitMovementCostRules.costToEnterTile(
      tile,
      unitType: unitType,
    ).passable;
  }

  static bool _canShareSpawnTile(
    GameCity city,
    GameUnitType unitType,
    CityHex candidate,
  ) {
    return unitType == GameUnitType.merchant && candidate == city.center;
  }

  static bool _isCoast(TileData tile) {
    return tile.terrains.contains(TerrainType.coast);
  }

  static bool _isOcean(TileData tile) {
    return tile.terrains.contains(TerrainType.ocean);
  }

  static bool _isOceanAdjacentCoast(
    CityHex hex,
    TileData tile,
    MapData mapData,
  ) {
    if (!_isCoast(tile)) return false;
    for (final neighbor in HexNeighbors.existingAround(
      hex.toCoordinate(),
      mapData,
    )) {
      final neighborTile = mapData.tileAt(neighbor.col, neighbor.row);
      if (neighborTile != null && _isOcean(neighborTile)) return true;
    }
    return false;
  }

  static Iterable<CityHex> _spawnCandidates(
    GameCity city,
    MapData mapData,
  ) sync* {
    final seen = <CityHex>{};

    if (seen.add(city.center)) {
      yield city.center;
    }

    for (final neighbor in HexNeighbors.existingAround(
      city.center.toCoordinate(),
      mapData,
    )) {
      final hex = CityHex.fromCoordinate(neighbor);
      if (seen.add(hex)) {
        yield hex;
      }
    }

    for (final hex in city.controlledHexes) {
      if (seen.add(hex)) {
        yield hex;
      }
    }
  }

  static String _nextProducedUnitId(
    GameCity city,
    GameUnitType unitType,
    List<GameUnit> units,
  ) {
    final prefix = '${city.id}_${unitType.name}';
    var index = 1;
    while (units.any((unit) => unit.id == '${prefix}_$index')) {
      index++;
    }
    return '${prefix}_$index';
  }
}
