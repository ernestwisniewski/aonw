import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield_rules.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class CityTileYieldRules {
  static TileYield forCityHex({
    required GameCity city,
    required CityHex hex,
    required TileData? tile,
    Iterable<FieldImprovement> fieldImprovements = const [],
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    if (hex == city.center) return ruleset.cityCenterYield;
    if (tile == null) return TileYield.zero;
    final improvement = improvementAt(hex, fieldImprovements);
    return forTile(tile, improvement: improvement?.type, ruleset: ruleset);
  }

  static TileYield forTile(
    TileData tile, {
    FieldImprovementType? improvement,
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    final baseYield = TileYieldRules.forTile(tile, ruleset: ruleset);
    final improved = improvement == null
        ? TileYield.zero
        : improvementYield(improvement, ruleset: ruleset);
    return baseYield + improved;
  }

  static FieldImprovement? improvementAt(
    CityHex hex,
    Iterable<FieldImprovement> fieldImprovements,
  ) {
    for (final improvement in fieldImprovements) {
      if (improvement.hex == hex) return improvement;
    }
    return null;
  }

  static TerrainType? baseTerrainOrNull(TileData tile) {
    return TileYieldRules.baseTerrainOrNull(tile);
  }

  static bool hasRiver(TileData tile) => TileYieldRules.hasRiver(tile);

  /// Terrain does not restrict city territory; callers enforce map presence,
  /// ownership, adjacency, and radius before a tile becomes controlled.
  static bool canCityControlTile(
    TileData tile, {
    bool allowCoast = false,
    bool allowLake = false,
    bool allowOcean = false,
  }) => true;

  static TileYield terrainYield(
    TerrainType terrain, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    return TileYieldRules.terrainYield(terrain, ruleset: ruleset);
  }

  static TileYield resourceYield(
    ResourceType resource, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    return TileYieldRules.resourceYield(resource, ruleset: ruleset);
  }

  static TileYield improvementYield(
    FieldImprovementType improvement, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    return ruleset.improvementYieldFor(improvement);
  }
}
