part of 'city_site_scorer.dart';

final class _CitySiteScorecard {
  const _CitySiteScorecard({
    required this.centerTile,
    required this.controlledHexes,
    required this.view,
    required this.context,
    required this.assessment,
    required this.knownCities,
    required this.distanceFromFounder,
  });

  final TileData centerTile;
  final List<CityHex> controlledHexes;
  final GameView view;
  final AiContext context;
  final AiEmpireAssessment assessment;
  final Iterable<GameCity> knownCities;
  final int distanceFromFounder;

  double score() {
    return yieldScore +
        balanceScore +
        resourceScore +
        terrainScore +
        spacingScore +
        personaBonus -
        dangerPenalty -
        travelPenalty;
  }

  Iterable<TileData> get controlledTiles {
    return [
      for (final hex in controlledHexes) ?view.mapData.tileAt(hex.col, hex.row),
    ];
  }

  TileYield get controlledYield {
    return controlledTiles.fold(
      TileYield.zero,
      (total, tile) => total + CityTileYieldRules.forTile(tile),
    );
  }

  TileYield get centerYield => CityTileYieldRules.forTile(centerTile);

  double get yieldScore {
    return _weightedYieldScore(controlledYield) +
        _weightedYieldScore(centerYield) * 0.75;
  }

  double get balanceScore {
    return _balancedOutputScore(controlledYield) *
        (assessment.wantsExpansion ? 1.2 : 1.0);
  }

  double get resourceScore {
    final visibleResourceTypes = _visibleResourceTypes(view);
    final missingStrategicResourceTypes = _missingStrategicResourceTypes(view);
    return _resourceScore(
          centerTile,
          visibleResourceTypes,
          missingStrategicResourceTypes,
        ) +
        controlledTiles.fold<double>(
          0,
          (total, tile) =>
              total +
              _resourceScore(
                tile,
                visibleResourceTypes,
                missingStrategicResourceTypes,
              ),
        );
  }

  double get terrainScore => _terrainScore(centerTile, controlledTiles);

  double get spacingScore {
    return _spacingScore(
      CityHex(col: centerTile.col, row: centerTile.row),
      knownCities,
      view.forPlayerId,
    );
  }

  double get dangerPenalty => _dangerPenalty(centerTile);

  double get travelPenalty {
    return distanceFromFounder * 0.55 / context.civProfile.expansionDistance;
  }

  double get personaBonus {
    return context.effectiveWeights.expansion >= 1.2 ? 1.25 : 0.0;
  }

  double _weightedYieldScore(TileYield yield) {
    final weights = context.effectiveWeights;
    final pace = context.ruleset.paceBalance;
    final productionPace =
        (pace.unitProductionCostMultiplier +
            pace.buildingProductionCostMultiplier) /
        2;
    return yield.food * (1.3 / pace.growthCostMultiplier) +
        yield.production * (1.35 / productionPace) +
        yield.gold * (0.7 * weights.economy) +
        yield.defense * 0.35;
  }

  double _balancedOutputScore(TileYield yield) {
    final food = yield.food;
    final production = yield.production;
    if (food <= 0 || production <= 0) return 0;
    return food < production ? food.toDouble() : production.toDouble();
  }

  double _resourceScore(
    TileData tile,
    Set<ResourceType> visibleResourceTypes,
    Set<ResourceType> missingStrategicResourceTypes,
  ) {
    var score = 0.0;
    for (final resource in tile.resources) {
      if (!visibleResourceTypes.contains(resource)) continue;
      score += switch (resource) {
        ResourceType.wheat ||
        ResourceType.fish ||
        ResourceType.deer ||
        ResourceType.sheep ||
        ResourceType.rice ||
        ResourceType.cow ||
        ResourceType.apple ||
        ResourceType.banana ||
        ResourceType.citrus => 1.4,
        ResourceType.iron ||
        ResourceType.coal ||
        ResourceType.oil ||
        ResourceType.aluminium ||
        ResourceType.uranium ||
        ResourceType.horses ||
        ResourceType.marble => 1.8,
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
        ResourceType.sugar => 1.1,
      };
      if (missingStrategicResourceTypes.contains(resource)) {
        score += 2.2;
      }
    }
    return score;
  }

  double _terrainScore(
    TileData centerTile,
    Iterable<TileData> controlledTiles,
  ) {
    var score = 0.0;
    if (CityTileYieldRules.hasRiver(centerTile)) score += 1.4;
    if (centerTile.terrains.contains(TerrainType.hills)) score += 0.8;
    if (centerTile.primaryTerrain == TerrainType.coast) score += 0.6;
    for (final tile in controlledTiles) {
      if (CityTileYieldRules.hasRiver(tile)) score += 0.4;
      if (tile.primaryTerrain == TerrainType.coast) score += 0.25;
    }
    return score;
  }

  double _spacingScore(
    CityHex center,
    Iterable<GameCity> knownCities,
    String playerId,
  ) {
    var nearestOwn = 1 << 30;
    var nearestEnemy = 1 << 30;
    final origin = HexCoordinate(col: center.col, row: center.row);
    for (final city in knownCities) {
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
      final preferredMin = 3.0 * context.civProfile.expansionDistance;
      final sweetSpotMax = (5.0 * context.civProfile.expansionDistance)
          .round()
          .clamp(3, 8);
      if (nearestOwn < preferredMin) {
        score -= (preferredMin - nearestOwn) * 2.6;
      } else if (nearestOwn <= sweetSpotMax) {
        score += 1.2 + (nearestOwn - preferredMin) * 0.2;
      } else {
        score -= (nearestOwn - sweetSpotMax) * 0.25;
      }
    }
    if (nearestEnemy != 1 << 30 && nearestEnemy <= 3) {
      score -= 2.0 / context.civProfile.frontierTolerance;
    }
    return score;
  }

  double _dangerPenalty(TileData tile) {
    final origin = HexCoordinate(col: tile.col, row: tile.row);
    var penalty = 0.0;
    for (final enemy in view.visibleTargetableEnemyUnits) {
      if (enemy.isWorker ||
          enemy.type == GameUnitType.settler ||
          enemy.hasSettlers) {
        continue;
      }
      final distance = HexDistance.between(
        origin,
        HexCoordinate(col: enemy.col, row: enemy.row),
      );
      if (distance <= 1) {
        penalty += 4.0;
      } else if (distance == 2) {
        penalty += 1.5;
      }
    }
    return penalty / context.civProfile.frontierTolerance;
  }
}
