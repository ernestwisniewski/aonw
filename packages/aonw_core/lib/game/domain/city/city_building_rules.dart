import 'package:aonw_core/game/domain/city/city_building_effect.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield_rules.dart';
import 'package:aonw_core/map/domain/map_data.dart';

abstract final class CityBuildingRules {
  static TileYield yieldForCity(
    GameCity city,
    MapData mapData, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    var total = TileYield.zero;

    for (final effect in _effectsFor(city, ruleset)) {
      total = switch (effect) {
        FlatCityYieldEffect(:final yield) => total + yield,
        RiverHexCityYieldEffect(
          :final yieldPerRiverHex,
          :final maxApplications,
        ) =>
          total +
              _scaleYield(
                yieldPerRiverHex,
                _effectiveApplicationCount(
                  _riverHexCount(city, mapData),
                  maxApplications,
                ),
              ),
        FlatCityScienceEffect() => total,
        MaxControlledHexesEffect() || FoodDepositMultiplierEffect() => total,
      };
    }

    return total;
  }

  static int effectiveMaxHexes(
    GameCity city, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    var bonus = 0;
    for (final effect in _effectsFor(city, ruleset)) {
      if (effect case MaxControlledHexesEffect(:final amount)) {
        bonus += amount;
      }
    }
    return city.maxHexes + bonus;
  }

  static int foodDeposited(
    GameCity city,
    int netFood, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    var deposited = netFood;
    for (final effect in _effectsFor(city, ruleset)) {
      if (effect case FoodDepositMultiplierEffect(:final multiplier)) {
        deposited = (deposited * multiplier).floor();
      }
    }
    return deposited;
  }

  static Iterable<CityBuildingEffect> _effectsFor(
    GameCity city,
    CityRuleset ruleset,
  ) sync* {
    for (final buildingType in city.buildings) {
      yield* ruleset.buildingDefinitionFor(buildingType).effects;
    }
  }

  static int _effectiveApplicationCount(int count, int? maxApplications) {
    if (maxApplications == null) return count;
    return count < maxApplications ? count : maxApplications;
  }

  static TileYield _scaleYield(TileYield yield, int multiplier) {
    if (multiplier <= 0) return TileYield.zero;
    return TileYield(
      food: yield.food * multiplier,
      production: yield.production * multiplier,
      gold: yield.gold * multiplier,
      defense: yield.defense * multiplier,
    );
  }

  static int _riverHexCount(GameCity city, MapData mapData) {
    var count = 0;
    for (final hex in city.territoryHexes) {
      final tile = mapData.tileAt(hex.col, hex.row);
      if (tile != null && TileYieldRules.hasRiver(tile)) {
        count++;
      }
    }
    return count;
  }
}
