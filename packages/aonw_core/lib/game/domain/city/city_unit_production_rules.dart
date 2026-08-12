import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class CityUnitProductionRules {
  static GameUnit? produce({
    required GameCity city,
    required GameUnitType unitType,
    required List<GameUnit> units,
    required MapTileLookup mapTiles,
  }) {
    if (!canProduceInCity(city: city, unitType: unitType, mapTiles: mapTiles)) {
      return null;
    }

    final spawnHex = _spawnHexFor(
      city: city,
      unitType: unitType,
      units: units,
      mapTiles: mapTiles,
    );
    if (spawnHex == null) return null;

    return GameUnit.produced(
      id: _nextProducedUnitId(city, unitType, units),
      ownerPlayerId: city.ownerPlayerId,
      type: unitType,
      col: spawnHex.col,
      row: spawnHex.row,
    );
  }

  static bool canSpawnProducedUnit({
    required GameCity city,
    required GameUnitType unitType,
    required Iterable<GameUnit> units,
    required MapTileLookup mapTiles,
  }) =>
      canProduceInCity(city: city, unitType: unitType, mapTiles: mapTiles) &&
      _spawnHexFor(
            city: city,
            unitType: unitType,
            units: units,
            mapTiles: mapTiles,
          ) !=
          null;

  static CityHex? _spawnHexFor({
    required GameCity city,
    required GameUnitType unitType,
    required Iterable<GameUnit> units,
    required MapTileLookup mapTiles,
  }) {
    for (final candidate in _spawnCandidates(city, mapTiles)) {
      final occupied = units.any(
        (unit) => unit.occupies(candidate.col, candidate.row),
      );
      if (occupied && !_canShareSpawnTile(city, unitType, candidate)) {
        continue;
      }

      if (!_canSpawnUnitOnCandidate(unitType, candidate, mapTiles)) continue;

      return candidate;
    }
    return null;
  }

  static bool canProduceInCity({
    required GameCity city,
    required GameUnitType unitType,
    required MapTileLookup mapTiles,
  }) {
    if (!unitType.canBeProducedByCities) return false;
    if (!unitType.isNaval) return true;

    return _spawnCandidates(city, mapTiles).any(
      (candidate) => _canSpawnUnitOnCandidate(unitType, candidate, mapTiles),
    );
  }

  static bool _canSpawnUnitOnCandidate(
    GameUnitType unitType,
    CityHex candidate,
    MapTileLookup mapTiles,
  ) {
    final tile = mapTiles.tileAt(candidate.col, candidate.row);
    if (tile == null) return false;
    if (unitType.isNaval && !_isOceanAdjacentCoast(candidate, tile, mapTiles)) {
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

  static bool _isCoast(MapTileView tile) {
    return tile.terrains.contains(TerrainType.coast);
  }

  static bool _isOcean(MapTileView tile) {
    return tile.terrains.contains(TerrainType.ocean);
  }

  static bool _isOceanAdjacentCoast(
    CityHex hex,
    MapTileView tile,
    MapTileLookup mapTiles,
  ) {
    if (!_isCoast(tile)) return false;
    for (final neighbor in HexNeighbors.existingAround(
      hex.toCoordinate(),
      mapTiles,
    )) {
      final neighborTile = mapTiles.tileAt(neighbor.col, neighbor.row);
      if (neighborTile != null && _isOcean(neighborTile)) return true;
    }
    return false;
  }

  static Iterable<CityHex> _spawnCandidates(
    GameCity city,
    MapTileLookup mapTiles,
  ) sync* {
    final seen = <CityHex>{};

    if (seen.add(city.center)) {
      yield city.center;
    }

    for (final neighbor in HexNeighbors.existingAround(
      city.center.toCoordinate(),
      mapTiles,
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
    Iterable<GameUnit> units,
  ) {
    final prefix = '${city.id}_${unitType.name}';
    var index = 1;
    while (units.any((unit) => unit.id == '${prefix}_$index')) {
      index++;
    }
    return '${prefix}_$index';
  }
}
