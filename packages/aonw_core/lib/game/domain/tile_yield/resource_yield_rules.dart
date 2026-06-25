import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class ResourceYieldRules {
  static TileYield yieldFor(
    ResourceType resource, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    return ruleset.resourceYieldFor(resource);
  }
}
