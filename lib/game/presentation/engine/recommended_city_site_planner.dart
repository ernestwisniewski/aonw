import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

part 'recommended_city_site_expansion.dart';
part 'recommended_city_site_scoring.dart';
part 'recommended_city_site_selection.dart';

class RecommendedCitySitePlanner {
  static const int _minimumRecommendedCitySiteCount = 4;
  static const int _maximumRecommendedCitySiteCount = 8;
  static const double _recommendedCitySiteScoreWindow = 4.5;

  _RecommendedCitySiteCache? _cache;

  Set<(int, int)> coordinates({
    required GameClientState state,
    required GameUnit founder,
    required WorldMap mapData,
  }) {
    final cacheKey = _RecommendedCitySiteCacheKey.fromState(
      state: state,
      founder: founder,
      mapData: mapData,
    );
    final cached = _cache;
    if (cached != null && cached.key == cacheKey) {
      return cached.coordinates;
    }

    final coordinates = _computeCoordinates(
      state: state,
      founder: founder,
      mapData: mapData,
    );
    _cache = _RecommendedCitySiteCache(key: cacheKey, coordinates: coordinates);
    return coordinates;
  }

  double _resourceStrategicValue(ResourceType resource) {
    return switch (resource) {
      ResourceType.wheat ||
      ResourceType.fish ||
      ResourceType.deer ||
      ResourceType.sheep ||
      ResourceType.rice ||
      ResourceType.cow ||
      ResourceType.apple ||
      ResourceType.banana ||
      ResourceType.citrus => 1.55,
      ResourceType.iron ||
      ResourceType.coal ||
      ResourceType.oil ||
      ResourceType.aluminium ||
      ResourceType.uranium ||
      ResourceType.horses ||
      ResourceType.marble => 1.85,
      ResourceType.gold ||
      ResourceType.silver ||
      ResourceType.gems ||
      ResourceType.silk ||
      ResourceType.spices ||
      ResourceType.cotton ||
      ResourceType.grapes ||
      ResourceType.ivory ||
      ResourceType.pearls ||
      ResourceType.coffee ||
      ResourceType.cocoa ||
      ResourceType.tobacco ||
      ResourceType.sugar => 1.25,
    };
  }

  double _citySiteSpacingScore(
    CityHex center,
    Iterable<GameCity> cities,
    String playerId,
  ) {
    var nearestOwn = 1 << 30;
    var nearestEnemy = 1 << 30;
    final origin = HexCoordinate(col: center.col, row: center.row);
    for (final city in cities) {
      final distance = HexDistance.between(
        origin,
        HexCoordinate(col: city.center.col, row: city.center.row),
      );
      if (city.ownerPlayerId == playerId) {
        if (distance < nearestOwn) nearestOwn = distance;
      } else if (distance < nearestEnemy) {
        nearestEnemy = distance;
      }
    }

    var score = 0.0;
    if (nearestOwn != 1 << 30) {
      if (nearestOwn <= 3) {
        score += 0.4;
      } else if (nearestOwn <= 6) {
        score += 1.8;
      } else if (nearestOwn <= 9) {
        score += 0.9;
      } else {
        score -= (nearestOwn - 9) * 0.25;
      }
    }
    if (nearestEnemy != 1 << 30) {
      if (nearestEnemy <= 3) {
        score -= 3.0;
      } else if (nearestEnemy <= 5) {
        score -= 1.2;
      } else if (nearestEnemy <= 7) {
        score += 0.35;
      }
    }
    return score;
  }
}

class _RecommendedCitySiteCacheKey {
  const _RecommendedCitySiteCacheKey({
    required this.mapIdentity,
    required this.mapCols,
    required this.mapRows,
    required this.mapTileCount,
    required this.activePlayerId,
    required this.founderId,
    required this.founderOwnerPlayerId,
    required this.founderCol,
    required this.founderRow,
    required this.activePlayerFogIdentity,
    required this.citiesHash,
  });

  factory _RecommendedCitySiteCacheKey.fromState({
    required GameClientState state,
    required GameUnit founder,
    required WorldMap mapData,
  }) {
    final playerFog = state.activePlayerId.isEmpty
        ? null
        : state.fogOfWar.players[state.activePlayerId];
    return _RecommendedCitySiteCacheKey(
      mapIdentity: identityHashCode(mapData),
      mapCols: mapData.cols,
      mapRows: mapData.rows,
      mapTileCount: mapData.tiles.length,
      activePlayerId: state.activePlayerId,
      founderId: founder.id,
      founderOwnerPlayerId: founder.ownerPlayerId,
      founderCol: founder.col,
      founderRow: founder.row,
      activePlayerFogIdentity: playerFog == null
          ? 0
          : identityHashCode(playerFog),
      citiesHash: _cityPlanningHash(state.cities),
    );
  }

  final int mapIdentity;
  final int mapCols;
  final int mapRows;
  final int mapTileCount;
  final String activePlayerId;
  final String founderId;
  final String founderOwnerPlayerId;
  final int founderCol;
  final int founderRow;
  final int activePlayerFogIdentity;
  final int citiesHash;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _RecommendedCitySiteCacheKey &&
            other.mapIdentity == mapIdentity &&
            other.mapCols == mapCols &&
            other.mapRows == mapRows &&
            other.mapTileCount == mapTileCount &&
            other.activePlayerId == activePlayerId &&
            other.founderId == founderId &&
            other.founderOwnerPlayerId == founderOwnerPlayerId &&
            other.founderCol == founderCol &&
            other.founderRow == founderRow &&
            other.activePlayerFogIdentity == activePlayerFogIdentity &&
            other.citiesHash == citiesHash;
  }

  @override
  int get hashCode => Object.hash(
    mapIdentity,
    mapCols,
    mapRows,
    mapTileCount,
    activePlayerId,
    founderId,
    founderOwnerPlayerId,
    founderCol,
    founderRow,
    activePlayerFogIdentity,
    citiesHash,
  );
}
