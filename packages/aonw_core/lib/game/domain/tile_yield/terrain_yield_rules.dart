import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class TerrainYieldRules {
  static TileYield get riverModifier => CityRulesets.standard.riverYield;

  static TileYield yieldFor(
    TerrainType terrain, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    if (terrain == TerrainType.river) return ruleset.riverYield;
    return ruleset.terrainYieldFor(terrain);
  }
}
