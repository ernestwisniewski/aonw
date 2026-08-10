part of 'recommended_city_site_planner.dart';

extension _RecommendedCitySiteScoring on RecommendedCitySitePlanner {
  double _scoreRecommendedCitySite({
    required WorldTile tile,
    required GameClientState state,
    required GameUnit founder,
    required WorldMap mapData,
  }) {
    final center = CityHex(col: tile.col, row: tile.row);
    final founderDistance = HexDistance.between(
      HexCoordinate(col: founder.col, row: founder.row),
      HexCoordinate(col: tile.col, row: tile.row),
    );
    final initialHexes = CityInitialTerritorySelector.select(
      center: center,
      mapTiles: mapData,
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

  double _weightedCitySiteYieldTotal(Iterable<WorldTile> tiles) {
    return tiles.fold<double>(
      0,
      (total, tile) => total + _weightedCitySiteYield(tile),
    );
  }

  double _weightedCitySiteYield(WorldTile tile) {
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
    Iterable<WorldTile> tiles, {
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
    WorldTile tile, {
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

  double _citySiteTerrainScore(
    WorldTile centerTile,
    Iterable<WorldTile> initialTiles,
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

  double _citySiteFounderDistancePenalty(int distance) {
    if (distance <= 3) return distance * 0.18;
    return 0.54 + (distance - 3) * 0.42;
  }
}
