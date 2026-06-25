import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

final class AiTechnologyScoreSnapshot {
  final List<TileData> visibleTiles;
  final Set<ResourceType> visibleResources;
  final Set<ResourceType> controlledResources;
  final double productionPressure;
  final double growthPressure;
  final double goldPressure;
  final double sciencePressure;
  final double militaryPressure;
  final bool hasRiverTile;
  final bool hasCoastalOpportunity;

  const AiTechnologyScoreSnapshot({
    required this.visibleTiles,
    required this.visibleResources,
    required this.controlledResources,
    required this.productionPressure,
    required this.growthPressure,
    required this.goldPressure,
    required this.sciencePressure,
    required this.militaryPressure,
    required this.hasRiverTile,
    required this.hasCoastalOpportunity,
  });

  factory AiTechnologyScoreSnapshot.from(GameView view) {
    final research = ResearchState(
      players: {view.forPlayerId: view.ownResearch},
    );
    final visibleTiles = [
      for (final tile in view.mapData.tiles)
        if (view.visibility.canInspectTile(tile)) tile,
    ];
    final visibleResources = {
      for (final tile in visibleTiles)
        ...ResourceVisibilityRules.visibleResources(
          resources: tile.resources,
          playerId: view.forPlayerId,
          research: research,
        ),
    };
    final controlledResources = {
      for (final city in view.ownCities)
        for (final hex in city.territoryHexes)
          ...ResourceVisibilityRules.visibleResources(
            resources:
                view.mapData.tileAt(hex.col, hex.row)?.resources ?? const [],
            playerId: view.forPlayerId,
            research: research,
          ),
    };
    final economy = _EmpireYieldSnapshot.from(view);
    final pace = view.ruleset.paceBalance;
    final averageProduction = view.ownCities.isEmpty
        ? 0.0
        : economy.production / view.ownCities.length;
    final averageFood = view.ownCities.isEmpty
        ? 0.0
        : economy.food / view.ownCities.length;
    final paceProductionPressure =
        _positivePressure(pace.unitProductionCostMultiplier - 1.0) * 0.45 +
        _positivePressure(pace.buildingProductionCostMultiplier - 1.0) * 0.55;
    final productionPressure = view.ownCities.isEmpty
        ? 0.0
        : _clamp01((4.0 - averageProduction) / 4.0) * 0.65 +
              paceProductionPressure * 0.35;
    final growthPressure = view.ownCities.isEmpty
        ? 0.0
        : _clamp01((2.0 - averageFood) / 3.0) * 0.60 +
              _positivePressure(pace.growthCostMultiplier - 1.0) * 0.40;
    final goldPressure = _clamp01((3.0 - economy.gold) / 6.0);
    final sciencePressure = view.ownCities.isEmpty
        ? 0.0
        : _clamp01((view.ownCities.length * 2.0 - economy.science) / 4.0) *
                  0.50 +
              _positivePressure(pace.researchCostMultiplier - 1.0) * 0.50;
    final militaryPressure = view.ownUnits.isEmpty
        ? 0.35
        : _clamp01(view.visibleEnemyUnits.length / (view.ownUnits.length + 1));

    return AiTechnologyScoreSnapshot(
      visibleTiles: List.unmodifiable(visibleTiles),
      visibleResources: Set.unmodifiable(visibleResources),
      controlledResources: Set.unmodifiable(controlledResources),
      productionPressure: _clamp01(productionPressure),
      growthPressure: _clamp01(growthPressure),
      goldPressure: goldPressure,
      sciencePressure: _clamp01(sciencePressure),
      militaryPressure: militaryPressure,
      hasRiverTile: visibleTiles.any(CityTileYieldRules.hasRiver),
      hasCoastalOpportunity: visibleTiles.any(_isCoastalTile),
    );
  }

  bool hasVisibleResource(ResourceType resource) {
    return visibleResources.contains(resource);
  }

  bool controlsResource(ResourceType resource) {
    return controlledResources.contains(resource);
  }

  double visibleImprovementFit(FieldImprovementType type, CityRuleset ruleset) {
    final definition = ruleset.improvementDefinitionFor(type);
    var best = 0.0;
    for (final tile in visibleTiles) {
      if (!definition.canImprove(tile)) continue;
      final hasResource = visibleResources.any(tile.resources.contains);
      final fit = definition.resourceSpecialist
          ? hasResource
                ? 1.0
                : 0.55
          : 0.45;
      if (fit > best) best = fit;
      if (best >= 1.0) return best;
    }
    return best;
  }

  static bool _isCoastalTile(TileData tile) {
    return tile.terrains.contains(TerrainType.coast) ||
        tile.terrains.contains(TerrainType.ocean);
  }
}

final class _EmpireYieldSnapshot {
  final int food;
  final int production;
  final int gold;
  final int science;

  const _EmpireYieldSnapshot({
    required this.food,
    required this.production,
    required this.gold,
    required this.science,
  });

  factory _EmpireYieldSnapshot.from(GameView view) {
    var food = 0;
    var production = 0;
    var gold = 0;
    final research = ResearchState(
      players: {view.forPlayerId: view.ownResearch},
    );
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: view.forPlayerId,
      research: research,
      ruleset: view.ruleset.technology,
    );

    for (final city in view.ownCities) {
      final tileYield = CityYieldCalculator.totalFor(
        city,
        view.mapData,
        fieldImprovements: view.ownImprovements,
        units: view.ownUnits,
        ruleset: view.ruleset.city,
      );
      final economy = CityEconomyBreakdown.from(
        city: city,
        tileYield: tileYield,
        mapData: view.mapData,
        ruleset: view.ruleset.city,
        paceBalance: view.ruleset.paceBalance,
        technologyEffects: technologyEffects,
      );
      food += economy.netYield.food;
      production += economy.netYield.production;
      gold += economy.netYield.gold;
    }

    final science = ScienceYieldCalculator.totalForPlayer(
      playerId: view.forPlayerId,
      cities: view.ownCities,
      research: research,
      ruleset: view.ruleset.technology,
      cityRuleset: view.ruleset.city,
    ).total;

    return _EmpireYieldSnapshot(
      food: food,
      production: production,
      gold: gold,
      science: science,
    );
  }
}

double _positivePressure(double value) {
  if (value <= 0) return 0;
  if (value >= 1) return 1;
  return value;
}

double _clamp01(double value) {
  if (value <= 0) return 0;
  if (value >= 1) return 1;
  return value;
}
