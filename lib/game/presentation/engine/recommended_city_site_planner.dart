import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

class RecommendedCitySitePlanner {
  static const int _minimumRecommendedCitySiteCount = 4;
  static const int _maximumRecommendedCitySiteCount = 8;
  static const double _recommendedCitySiteScoreWindow = 4.5;

  _RecommendedCitySiteCache? _cache;

  Set<(int, int)> coordinates({
    required GameState state,
    required GameUnit founder,
    required MapData mapData,
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

  Set<(int, int)> _computeCoordinates({
    required GameState state,
    required GameUnit founder,
    required MapData mapData,
  }) {
    final visibility = state.activePlayerVisibility;
    final candidates =
        <_RecommendedCitySite>[
          for (final tile in mapData.tiles)
            if ((!visibility.isEnabled || visibility.canInspectTile(tile)) &&
                _canUseAsCityCenter(tile, state.cities))
              _RecommendedCitySite(
                col: tile.col,
                row: tile.row,
                score: _scoreRecommendedCitySite(
                  tile: tile,
                  state: state,
                  founder: founder,
                  mapData: mapData,
                ),
              ),
        ]..sort((a, b) {
          final scoreCompare = b.score.compareTo(a.score);
          if (scoreCompare != 0) return scoreCompare;
          final colCompare = a.col.compareTo(b.col);
          if (colCompare != 0) return colCompare;
          return a.row.compareTo(b.row);
        });

    if (candidates.isEmpty) return const <(int, int)>{};

    final maxCount = _recommendedCitySiteCountFor(candidates.length);
    final guaranteedCount = _minimumRecommendedCitySiteCount.clamp(
      0,
      candidates.length,
    );
    final bestScore = candidates.first.score;
    final recommended = <(int, int)>{};
    for (var index = 0; index < candidates.length; index++) {
      final candidate = candidates[index];
      if (index >= maxCount) break;
      if (index >= guaranteedCount &&
          candidate.score < bestScore - _recommendedCitySiteScoreWindow) {
        break;
      }
      recommended.add((candidate.col, candidate.row));
    }

    return recommended;
  }

  int _recommendedCitySiteCountFor(int candidateCount) {
    final scaledCount = (candidateCount / 5).ceil() + 3;
    return scaledCount.clamp(
      _minimumRecommendedCitySiteCount,
      _maximumRecommendedCitySiteCount,
    );
  }

  double _scoreRecommendedCitySite({
    required TileData tile,
    required GameState state,
    required GameUnit founder,
    required MapData mapData,
  }) {
    final center = CityHex(col: tile.col, row: tile.row);
    final founderDistance = HexDistance.between(
      HexCoordinate(col: founder.col, row: founder.row),
      HexCoordinate(col: tile.col, row: tile.row),
    );
    final initialHexes = CityInitialTerritorySelector.select(
      center: center,
      mapData: mapData,
      cities: state.cities,
      ruleset: CityRulesets.standard,
    ).toSet();
    final ringTiles = _citySiteExpansionTiles(
      center: center,
      state: state,
      mapData: mapData,
      initialHexes: initialHexes,
    ).toList(growable: false);
    final visibility = state.activePlayerVisibility;
    final initialTiles = [
      for (final hex in initialHexes)
        if (mapData.tileAt(hex.col, hex.row) case final tile?)
          if (!visibility.isEnabled || visibility.canInspectTile(tile)) tile,
    ];
    final visibleResourceTypes = ResourceVisibilityRules.visibleResourceTypes(
      playerId: state.activePlayerId,
      research: state.research,
    );

    return _weightedCitySiteYield(tile) * 1.15 +
        _weightedCitySiteYieldTotal(initialTiles) * 0.8 +
        _weightedCitySiteYieldTotal(ringTiles.take(4)) * 0.38 +
        _citySiteResourceScore(
          tile,
          visibleResourceTypes: visibleResourceTypes,
          distance: 0,
        ) +
        _citySiteResourceScoreTotal(
          initialTiles,
          visibleResourceTypes: visibleResourceTypes,
          distance: 1,
        ) +
        _citySiteResourceScoreTotal(
          ringTiles.take(6),
          visibleResourceTypes: visibleResourceTypes,
          distance: 2,
        ) +
        _citySiteTerrainScore(tile, initialTiles) +
        _citySiteSpacingScore(center, state.cities, founder.ownerPlayerId) -
        _citySiteFounderDistancePenalty(founderDistance);
  }

  Iterable<TileData> _citySiteExpansionTiles({
    required CityHex center,
    required GameState state,
    required MapData mapData,
    required Set<CityHex> initialHexes,
  }) sync* {
    final draft = CityFoundingDraft(
      unitId: '_city_site_preview',
      ownerPlayerId: '_city_site_preview',
      center: center,
    );
    final candidates = <_CitySiteExpansionTile>[];
    final visibility = state.activePlayerVisibility;
    for (final candidate in _tilesInCitySiteRadius(center, mapData)) {
      if (visibility.isEnabled && !visibility.canInspectTile(candidate)) {
        continue;
      }
      final hex = CityHex(col: candidate.col, row: candidate.row);
      if (hex == center || initialHexes.contains(hex)) continue;
      if (!CityFoundingRules.isControlledHexCandidate(
        draft: draft,
        tile: candidate,
        mapData: mapData,
        cities: state.cities,
      )) {
        continue;
      }
      final distance = HexDistance.between(
        HexCoordinate(col: center.col, row: center.row),
        HexCoordinate(col: candidate.col, row: candidate.row),
      );
      candidates.add(
        _CitySiteExpansionTile(
          tile: candidate,
          distance: distance,
          score: CityExpansionSelector.score(
            candidate,
            ruleset: CityRulesets.standard,
          ),
        ),
      );
    }
    candidates.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      final distanceCompare = a.distance.compareTo(b.distance);
      if (distanceCompare != 0) return distanceCompare;
      final colCompare = a.tile.col.compareTo(b.tile.col);
      if (colCompare != 0) return colCompare;
      return a.tile.row.compareTo(b.tile.row);
    });
    for (final candidate in candidates) {
      yield candidate.tile;
    }
  }

  Iterable<TileData> _tilesInCitySiteRadius(
    CityHex center,
    MapData mapData,
  ) sync* {
    final visited = <CityHex>{center};
    var frontier = <CityHex>[center];
    for (
      var distance = 1;
      distance <= CityFoundingDraft.maxRadius;
      distance++
    ) {
      final next = <CityHex>[];
      for (final current in frontier) {
        for (final neighbor in HexGridTopology.neighbors(
          col: current.col,
          row: current.row,
        )) {
          final hex = CityHex(col: neighbor.col, row: neighbor.row);
          if (!visited.add(hex)) continue;
          final tile = mapData.tileAt(hex.col, hex.row);
          if (tile == null) continue;
          next.add(hex);
          yield tile;
        }
      }
      frontier = next;
    }
  }

  double _weightedCitySiteYieldTotal(Iterable<TileData> tiles) {
    return tiles.fold<double>(
      0,
      (total, tile) => total + _weightedCitySiteYield(tile),
    );
  }

  double _weightedCitySiteYield(TileData tile) {
    final yield = CityTileYieldRules.forTile(
      tile,
      ruleset: CityRulesets.standard,
    );
    return yield.food * 1.15 +
        yield.production * 1.1 +
        yield.gold * 0.5 +
        yield.defense * 0.25;
  }

  double _citySiteResourceScoreTotal(
    Iterable<TileData> tiles, {
    required Set<ResourceType> visibleResourceTypes,
    required int distance,
  }) {
    return tiles.fold<double>(
      0,
      (total, tile) =>
          total +
          _citySiteResourceScore(
            tile,
            visibleResourceTypes: visibleResourceTypes,
            distance: distance,
          ),
    );
  }

  double _citySiteResourceScore(
    TileData tile, {
    required Set<ResourceType> visibleResourceTypes,
    required int distance,
  }) {
    final resources = [
      for (final resource in tile.resources)
        if (visibleResourceTypes.contains(resource)) resource,
    ];
    if (resources.isEmpty) return 0;
    final distanceWeight = switch (distance) {
      0 => 1.25,
      1 => 1.0,
      _ => 0.55,
    };
    return resources.fold<double>(
          0,
          (total, resource) => total + _resourceStrategicValue(resource),
        ) *
        distanceWeight;
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

  double _citySiteTerrainScore(
    TileData centerTile,
    Iterable<TileData> initialTiles,
  ) {
    var score = 0.0;
    if (CityTileYieldRules.hasRiver(centerTile)) score += 1.2;
    if (centerTile.terrains.contains(TerrainType.hills)) score += 0.75;
    if (centerTile.primaryTerrain == TerrainType.coast) score += 0.45;
    for (final tile in initialTiles) {
      if (CityTileYieldRules.hasRiver(tile)) score += 0.35;
      if (tile.primaryTerrain == TerrainType.hills) score += 0.25;
      if (tile.primaryTerrain == TerrainType.coast) score += 0.2;
    }
    return score;
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

  double _citySiteFounderDistancePenalty(int distance) {
    if (distance <= 3) return distance * 0.18;
    return 0.54 + (distance - 3) * 0.42;
  }

  bool _canUseAsCityCenter(TileData tile, Iterable<GameCity> cities) {
    if (!CitySiteRules.canFoundCityOn(tile)) return false;
    final hex = CityHex(col: tile.col, row: tile.row);
    return !_isControlledByAnyCity(hex, cities) &&
        CityFoundingRules.isCenterFarEnoughFromCities(hex, cities);
  }

  bool _isControlledByAnyCity(CityHex hex, Iterable<GameCity> cities) {
    for (final city in cities) {
      if (city.controlsHex(hex)) return true;
    }
    return false;
  }
}

class _RecommendedCitySite {
  const _RecommendedCitySite({
    required this.col,
    required this.row,
    required this.score,
  });

  final int col;
  final int row;
  final double score;
}

class _RecommendedCitySiteCache {
  _RecommendedCitySiteCache({
    required this.key,
    required Set<(int, int)> coordinates,
  }) : coordinates = Set.unmodifiable(coordinates);

  final _RecommendedCitySiteCacheKey key;
  final Set<(int, int)> coordinates;
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
    required GameState state,
    required GameUnit founder,
    required MapData mapData,
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

class _CitySiteExpansionTile {
  const _CitySiteExpansionTile({
    required this.tile,
    required this.distance,
    required this.score,
  });

  final TileData tile;
  final int distance;
  final int score;
}

int _cityPlanningHash(Iterable<GameCity> cities) {
  final sorted = cities.toList()
    ..sort((a, b) {
      final id = a.id.compareTo(b.id);
      if (id != 0) return id;
      final col = a.center.col.compareTo(b.center.col);
      if (col != 0) return col;
      return a.center.row.compareTo(b.center.row);
    });
  return Object.hashAll([for (final city in sorted) _cityHash(city)]);
}

int _cityHash(GameCity city) {
  final controlledHexes = city.controlledHexes.toList()
    ..sort((a, b) {
      final col = a.col.compareTo(b.col);
      if (col != 0) return col;
      return a.row.compareTo(b.row);
    });
  return Object.hash(
    city.id,
    city.ownerPlayerId,
    city.center.col,
    city.center.row,
    Object.hashAll([
      for (final hex in controlledHexes) Object.hash(hex.col, hex.row),
    ]),
  );
}
