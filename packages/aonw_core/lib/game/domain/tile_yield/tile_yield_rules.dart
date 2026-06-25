import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/hex_assessment/hex_assessment_input.dart';
import 'package:aonw_core/game/domain/tile_yield/resource_yield_rules.dart';
import 'package:aonw_core/game/domain/tile_yield/terrain_yield_rules.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class TileYieldRules {
  static TileYield get riverModifier => CityRulesets.standard.riverYield;

  static TileYield forTile(
    TileData tile, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    return forInput(HexAssessmentInput.fromTile(tile), ruleset: ruleset);
  }

  static TileYield forInput(
    HexAssessmentInput input, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    final terrain = input.baseTerrain == null
        ? TileYield.zero
        : terrainYield(input.baseTerrain!, ruleset: ruleset);
    final river = input.hasRiver ? ruleset.riverYield : TileYield.zero;
    final resources = input.resources.fold<TileYield>(
      TileYield.zero,
      (total, resource) => total + resourceYield(resource, ruleset: ruleset),
    );
    return terrain + river + resources;
  }

  static TerrainType baseTerrainFor(TileData tile) {
    return baseTerrainOrNull(tile) ?? TerrainType.ocean;
  }

  static TerrainType? baseTerrainOrNull(TileData tile) {
    return HexAssessmentInput.baseTerrainFrom(tile.terrains);
  }

  static bool hasRiver(TileData tile) {
    return HexAssessmentInput.hasRiverIn(tile.terrains);
  }

  static TileYield terrainYield(
    TerrainType terrain, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    return TerrainYieldRules.yieldFor(terrain, ruleset: ruleset);
  }

  static TileYield resourceYield(
    ResourceType resource, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    return ResourceYieldRules.yieldFor(resource, ruleset: ruleset);
  }
}
