import 'package:aonw_core/game/domain/city/city_building_rules.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/technology/technology_effect_summary.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/map/domain/map_data.dart';

abstract final class CityTechnologyEffectRules {
  static int effectiveMaxHexes(
    GameCity city, {
    CityRuleset ruleset = CityRulesets.standard,
    TechnologyEffectSummary effects = TechnologyEffectSummary.empty,
  }) {
    return CityBuildingRules.effectiveMaxHexes(city, ruleset: ruleset) +
        effects.maxControlledHexesBonus;
  }

  static TileYield yieldForCity(
    GameCity city,
    MapData mapData, {
    TechnologyEffectSummary effects = TechnologyEffectSummary.empty,
  }) {
    var production = 0;
    for (final hex in city.territoryHexes) {
      final tile = mapData.tileAt(hex.col, hex.row);
      if (tile == null) continue;

      for (final resource in tile.resources) {
        production += effects.strategicResourceProductionByType[resource] ?? 0;
      }
    }

    return TileYield(
      food: 0,
      production: production,
      gold: 0,
      defense: effects.cityDefenseBonus,
    );
  }

  static TileYield applyGoldMultiplier(
    TileYield yield, {
    TechnologyEffectSummary effects = TechnologyEffectSummary.empty,
  }) {
    final multiplier = effects.globalGoldMultiplier;
    if (yield.gold <= 0 || multiplier <= 0) return yield;

    return TileYield(
      food: yield.food,
      production: yield.production,
      gold: (yield.gold * (1 + multiplier)).floor(),
      defense: yield.defense,
    );
  }

  static int unitProductionPerTurn(
    int productionPerTurn, {
    TechnologyEffectSummary effects = TechnologyEffectSummary.empty,
  }) {
    final multiplier = effects.armyProductionMultiplier;
    if (productionPerTurn <= 0 || multiplier <= 0) return productionPerTurn;

    final bonus = (productionPerTurn * multiplier).round();
    return productionPerTurn + (bonus > 0 ? bonus : 1);
  }
}
