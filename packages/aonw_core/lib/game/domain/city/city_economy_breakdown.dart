import 'package:aonw_core/game/domain/city/city_building_rules.dart';
import 'package:aonw_core/game/domain/city/city_growth_rules.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/city_specialization.dart';
import 'package:aonw_core/game/domain/city/city_technology_effect_rules.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology/technology_effect_summary.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class CityEconomyBreakdown {
  final GameCity city;
  final TileYield tileYield;
  final TileYield buildingYield;
  final TileYield specializationYield;
  final TileYield technologyYield;
  final TechnologyEffectSummary technologyEffects;
  final int populationUpkeep;
  final int netFood;
  final int foodDeposit;
  final int growthCost;

  const CityEconomyBreakdown({
    required this.city,
    required this.tileYield,
    required this.buildingYield,
    this.specializationYield = TileYield.zero,
    this.technologyYield = TileYield.zero,
    this.technologyEffects = TechnologyEffectSummary.empty,
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
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final buildingYield = CityBuildingRules.yieldForCity(
      city,
      mapData,
      ruleset: ruleset,
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
        specializationYield.food +
        technologyYield.food;
    final netFood = CityGrowthRules.netFood(
      totalFood: totalFood,
      population: city.population,
      ruleset: ruleset,
    );
    return CityEconomyBreakdown(
      city: city,
      tileYield: tileYield,
      buildingYield: buildingYield,
      specializationYield: specializationYield,
      technologyYield: technologyYield,
      technologyEffects: technologyEffects,
      populationUpkeep: populationUpkeep,
      netFood: netFood,
      foodDeposit: CityBuildingRules.foodDeposited(
        city,
        netFood,
        ruleset: ruleset,
      ),
      growthCost: CityGrowthRules.growthCost(
        city,
        ruleset: ruleset,
        paceBalance: paceBalance,
      ),
    );
  }

  TileYield get grossYield => CityTechnologyEffectRules.applyGoldMultiplier(
    tileYield + buildingYield + specializationYield + technologyYield,
    effects: technologyEffects,
  );

  TileYield get netYield => TileYield(
    food: netFood,
    production: grossYield.production,
    gold: grossYield.gold,
    defense: grossYield.defense,
  );

  int get storedFoodAfterTurn => city.storedFood + foodDeposit;

  bool get willGrow => storedFoodAfterTurn >= growthCost;
}
