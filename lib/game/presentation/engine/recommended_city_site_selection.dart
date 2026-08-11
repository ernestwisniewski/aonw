part of 'recommended_city_site_planner.dart';

extension _RecommendedCitySiteSelection on RecommendedCitySitePlanner {
  Set<(int, int)> _computeCoordinates({
    required GameClientState state,
    required GameUnit founder,
    required WorldMap mapData,
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
    final guaranteedCount = RecommendedCitySitePlanner
        ._minimumRecommendedCitySiteCount
        .clamp(0, candidates.length);
    final bestScore = candidates.first.score;
    final recommended = <(int, int)>{};
    for (var index = 0; index < candidates.length; index++) {
      final candidate = candidates[index];
      if (index >= maxCount) break;
      if (index >= guaranteedCount &&
          candidate.score <
              bestScore -
                  RecommendedCitySitePlanner._recommendedCitySiteScoreWindow) {
        break;
      }
      recommended.add((candidate.col, candidate.row));
    }

    return recommended;
  }

  int _recommendedCitySiteCountFor(int candidateCount) {
    final scaledCount = (candidateCount / 5).ceil() + 3;
    return scaledCount.clamp(
      RecommendedCitySitePlanner._minimumRecommendedCitySiteCount,
      RecommendedCitySitePlanner._maximumRecommendedCitySiteCount,
    );
  }

  bool _canUseAsCityCenter(WorldTile tile, Iterable<GameCity> cities) {
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
