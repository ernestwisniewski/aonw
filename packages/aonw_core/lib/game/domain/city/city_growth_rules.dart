import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';

abstract final class CityGrowthRules {
  static int growthCost(
    GameCity city, {
    CityRuleset ruleset = CityRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final cost = ruleset.progression.growthCost(
      population: city.population,
      territoryHexCount: city.territoryHexCount,
    );
    return paceBalance.growthCost(cost);
  }

  static int populationUpkeep(
    GameCity city, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    return ruleset.progression.foodUpkeepForPopulation(city.population);
  }

  static int netFood({
    required int totalFood,
    required int population,
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    final net =
        totalFood - ruleset.progression.foodUpkeepForPopulation(population);
    return net > 0 ? net : 0;
  }
}
