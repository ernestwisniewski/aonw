import 'package:aonw/game/domain/hex_assessment/hex_score.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/hex_assessment/hex_assessment_input.dart';

abstract final class HexScoreRules {
  static const blockedScore = -999;

  static HexScore score(HexAssessmentInput input) {
    var score = scoreTerrain(input.baseTerrain);
    if (input.hasRiver) {
      score = applyRiverBonus(score);
    }
    for (final resource in input.resources) {
      score = score + scoreResource(resource);
    }
    return applyPenaltyRules(
      terrain: input.baseTerrain,
      hasRiver: input.hasRiver,
      hasResources: input.resources.isNotEmpty,
      score: score,
    );
  }

  static HexScore scoreTerrain(TerrainType? terrain) {
    if (terrain == null) return HexScore.zero;
    return HexScore(
      city: cityScoreFromTerrain(terrain),
      defense: defenseScoreFromTerrain(terrain),
      economy: economyScoreFromTerrain(terrain),
    );
  }

  static int cityScoreFromTerrain(TerrainType terrain) {
    return switch (terrain) {
      TerrainType.grassland => 3,
      TerrainType.plains => 2,
      TerrainType.forest => 2,
      TerrainType.jungle => 1,
      TerrainType.wetlands => 1,
      TerrainType.hills => 1,
      TerrainType.desert => 0,
      TerrainType.tundra => 0,
      TerrainType.snow => -2,
      TerrainType.coast => 2,
      TerrainType.lake => blockedScore,
      TerrainType.ocean => blockedScore,
      TerrainType.mountain => blockedScore,
      TerrainType.river => 0,
    };
  }

  static int defenseScoreFromTerrain(TerrainType terrain) {
    return switch (terrain) {
      TerrainType.hills => 3,
      TerrainType.forest => 2,
      TerrainType.jungle => 2,
      TerrainType.wetlands => 2,
      TerrainType.mountain => 4,
      TerrainType.tundra => 1,
      TerrainType.snow => 1,
      TerrainType.grassland => 0,
      TerrainType.plains => 0,
      TerrainType.desert => -1,
      TerrainType.coast => 0,
      TerrainType.lake => blockedScore,
      TerrainType.ocean => blockedScore,
      TerrainType.river => 1,
    };
  }

  static int economyScoreFromTerrain(TerrainType terrain) {
    return switch (terrain) {
      TerrainType.grassland => 3,
      TerrainType.plains => 2,
      TerrainType.coast => 2,
      TerrainType.forest => 1,
      TerrainType.hills => 1,
      TerrainType.jungle => 1,
      TerrainType.wetlands => 2,
      TerrainType.desert => 1,
      TerrainType.tundra => 0,
      TerrainType.snow => -2,
      TerrainType.lake => blockedScore,
      TerrainType.ocean => blockedScore,
      TerrainType.mountain => blockedScore,
      TerrainType.river => 1,
    };
  }

  static HexScore applyRiverBonus(HexScore score) {
    return score.add(city: 2, economy: 2, defense: 1);
  }

  static HexScore scoreResource(ResourceType resource) {
    return _bonusResourceScore(resource) +
        _luxuryResourceScore(resource) +
        _strategicResourceScore(resource);
  }

  static HexScore applyPenaltyRules({
    required TerrainType? terrain,
    required bool hasRiver,
    required bool hasResources,
    required HexScore score,
  }) {
    var result = score;
    if (terrain == TerrainType.snow) {
      result = result.add(city: -2, economy: -2);
    }
    if (terrain == TerrainType.desert && !hasRiver && !hasResources) {
      result = result.add(city: -2, economy: -1);
    }
    if (terrain == TerrainType.tundra && !hasResources) {
      result = result.add(city: -1);
    }
    if (terrain == TerrainType.jungle && !hasRiver) {
      result = result.add(city: -1);
    }
    return result;
  }

  static HexScore _bonusResourceScore(ResourceType resource) {
    return switch (resource) {
      ResourceType.wheat ||
      ResourceType.rice ||
      ResourceType.fish => const HexScore(city: 3, economy: 2),
      ResourceType.deer ||
      ResourceType.sheep ||
      ResourceType.cow => const HexScore(city: 2, economy: 1, defense: 1),
      ResourceType.apple ||
      ResourceType.banana ||
      ResourceType.citrus => const HexScore(city: 2, economy: 2),
      _ => HexScore.zero,
    };
  }

  static HexScore _luxuryResourceScore(ResourceType resource) {
    return switch (resource) {
      ResourceType.gold ||
      ResourceType.silver ||
      ResourceType.gems => const HexScore(city: 1, economy: 4),
      ResourceType.silk ||
      ResourceType.spices ||
      ResourceType.cotton ||
      ResourceType.grapes ||
      ResourceType.pearls ||
      ResourceType.coffee ||
      ResourceType.cocoa ||
      ResourceType.tobacco ||
      ResourceType.sugar => const HexScore(city: 1, economy: 3),
      ResourceType.ivory => const HexScore(city: 1, defense: 1, economy: 2),
      _ => HexScore.zero,
    };
  }

  static HexScore _strategicResourceScore(ResourceType resource) {
    return switch (resource) {
      ResourceType.iron ||
      ResourceType.coal ||
      ResourceType.oil ||
      ResourceType.aluminium ||
      ResourceType.uranium => const HexScore(city: 1, defense: 2, economy: 2),
      ResourceType.horses => const HexScore(city: 1, economy: 1),
      ResourceType.marble => const HexScore(city: 2, defense: 1, economy: 1),
      _ => HexScore.zero,
    };
  }
}
