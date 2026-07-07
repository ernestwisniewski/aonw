import 'package:aonw_core/game/domain/city/city_building_rules.dart';
import 'package:aonw_core/game/domain/city/city_growth_rules.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/city_specialization.dart';
import 'package:aonw_core/game/domain/city/city_technology_effect_rules.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/stability/stability_modifier.dart';
import 'package:aonw_core/game/domain/technology/technology_effect_summary.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/game/domain/wonder/wonder_effect_resolver.dart';
import 'package:aonw_core/game/domain/wonder/wonder_registry.dart';
import 'package:aonw_core/game/domain/wonder/wonder_ruleset.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class CityEconomyBreakdown {
  final GameCity city;
  final TileYield tileYield;
  final TileYield buildingYield;
  final TileYield wonderYield;
  final TileYield specializationYield;
  final TileYield technologyYield;
  final TechnologyEffectSummary technologyEffects;
  final double wonderGoldMultiplier;
  final double wonderProductionMultiplier;
  final StabilityModifier stabilityModifier;
  final int populationUpkeep;
  final int netFood;
  final int foodDeposit;
  final int growthCost;

  const CityEconomyBreakdown({
    required this.city,
    required this.tileYield,
    required this.buildingYield,
    this.wonderYield = TileYield.zero,
    this.specializationYield = TileYield.zero,
    this.technologyYield = TileYield.zero,
    this.technologyEffects = TechnologyEffectSummary.empty,
    this.wonderGoldMultiplier = 0,
    this.wonderProductionMultiplier = 0,
    this.stabilityModifier = StabilityModifier.stable,
    required this.populationUpkeep,
    required this.netFood,
    required this.foodDeposit,
    required this.growthCost,
  });

  factory CityEconomyBreakdown.from({
    required GameCity city,
    required TileYield tileYield,
    required MapData mapData,
    CityRuleset ruleset = CityRulesets.standard,
    TechnologyEffectSummary technologyEffects = TechnologyEffectSummary.empty,
    Iterable<GameCity> cities = const [],
    WonderRegistry wonderRegistry = WonderRegistry.empty,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
    StabilityModifier stabilityModifier = StabilityModifier.stable,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final buildingYield = CityBuildingRules.yieldForCity(
      city,
      mapData,
      ruleset: ruleset,
    );
    final wonderCities = cities.isEmpty ? [city] : cities;
    final wonderYield = WonderEffectResolver.yieldForCity(
      city: city,
      cities: wonderCities,
      registry: wonderRegistry,
      ruleset: wonderRuleset,
    );
    final wonderGoldMultiplier = WonderEffectResolver.goldMultiplierForPlayer(
      playerId: city.ownerPlayerId,
      cities: wonderCities,
      registry: wonderRegistry,
      ruleset: wonderRuleset,
    );
    final wonderProductionMultiplier =
        WonderEffectResolver.productionMultiplierForPlayer(
          playerId: city.ownerPlayerId,
          cities: wonderCities,
          registry: wonderRegistry,
          ruleset: wonderRuleset,
        );
    final specializationYield = CitySpecializationRules.yieldFor(
      city.specialization,
    );
    final technologyYield = CityTechnologyEffectRules.yieldForCity(
      city,
      mapData,
      effects: technologyEffects,
    );
    final populationUpkeep = CityGrowthRules.populationUpkeep(
      city,
      ruleset: ruleset,
    );
    final totalFood =
        tileYield.food +
        buildingYield.food +
        wonderYield.food +
        specializationYield.food +
        technologyYield.food;
    final netFood = CityGrowthRules.netFood(
      totalFood: totalFood,
      population: city.population,
      ruleset: ruleset,
    );
    final baseFoodDeposit = CityBuildingRules.foodDeposited(
      city,
      netFood,
      ruleset: ruleset,
    );
    final foodDeposit = stabilityModifier.haltsGrowth
        ? 0
        : baseFoodDeposit + stabilityModifier.foodBonus;

    return CityEconomyBreakdown(
      city: city,
      tileYield: tileYield,
      buildingYield: buildingYield,
      wonderYield: wonderYield,
      specializationYield: specializationYield,
      technologyYield: technologyYield,
      technologyEffects: technologyEffects,
      wonderGoldMultiplier: wonderGoldMultiplier,
      wonderProductionMultiplier: wonderProductionMultiplier,
      stabilityModifier: stabilityModifier,
      populationUpkeep: populationUpkeep,
      netFood: netFood,
      foodDeposit: foodDeposit,
      growthCost: CityGrowthRules.growthCost(
        city,
        ruleset: ruleset,
        paceBalance: paceBalance,
      ),
    );
  }

  TileYield get grossYield => _applyGoldMultiplier(
    CityTechnologyEffectRules.applyGoldMultiplier(
      tileYield +
          buildingYield +
          wonderYield +
          specializationYield +
          technologyYield,
      effects: technologyEffects,
    ),
    wonderGoldMultiplier,
  );

  TileYield get netYield => TileYield(
    food: netFood,
    production: _scale(
      _scale(grossYield.production, stabilityModifier.productionMultiplier),
      1 + wonderProductionMultiplier,
    ),
    gold: _scale(grossYield.gold, stabilityModifier.goldMultiplier),
    defense: grossYield.defense,
  );

  int get storedFoodAfterTurn => city.storedFood + foodDeposit;

  bool get willGrow => storedFoodAfterTurn >= growthCost;

  static int _scale(int value, double multiplier) {
    if (multiplier == 1.0) return value;
    return (value * multiplier).floor();
  }

  static TileYield _applyGoldMultiplier(TileYield yield, double multiplier) {
    if (yield.gold <= 0 || multiplier <= 0) return yield;
    return TileYield(
      food: yield.food,
      production: yield.production,
      gold: (yield.gold * (1 + multiplier)).floor(),
      defense: yield.defense,
    );
  }
}
