import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/hex_assessment/hex_assessment_model.dart';
import 'package:aonw/game/domain/hex_assessment/hex_kind_rules.dart';
import 'package:aonw/game/domain/hex_assessment/hex_recommendation_rules.dart';
import 'package:aonw/game/domain/hex_assessment/hex_score.dart';
import 'package:aonw/game/domain/hex_assessment/hex_score_rules.dart';
import 'package:aonw/game/domain/hex_assessment/hex_tag_rules.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/hex_assessment/hex_assessment_input.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';

abstract final class HexAssessmentRules {
  static HexAssessment assess(TileData tile) {
    return assessInput(HexAssessmentInput.fromTile(tile));
  }

  static HexAssessment assessInput(HexAssessmentInput input) {
    final score = HexScoreRules.score(input);
    final kind = HexKindRules.classify(input, score);
    final canFoundCity = CitySiteRules.canFoundCityForInput(input);
    final recommendation = HexRecommendationRules.recommend(
      kind: kind,
      score: score,
      terrain: input.baseTerrain,
    );

    return HexAssessment(
      baseTerrain: input.baseTerrain,
      hasRiver: input.hasRiver,
      canFoundCity: canFoundCity,
      yield: TileYieldRules.forInput(input),
      score: score,
      kind: kind,
      recommendation: recommendation,
      tags: HexTagRules.tagsFor(
        kind: kind,
        score: score,
        terrain: input.baseTerrain,
        hasRiver: input.hasRiver,
        resources: input.resources.toSet(),
        canFoundCity: canFoundCity,
      ),
    );
  }

  static HexScore scoreTile(TileData tile) {
    return scoreInput(HexAssessmentInput.fromTile(tile));
  }

  static HexScore scoreInput(HexAssessmentInput input) {
    return HexScoreRules.score(input);
  }

  static HexScore scoreTerrain(TerrainType? terrain) {
    return HexScoreRules.scoreTerrain(terrain);
  }

  static int cityScoreFromTerrain(TerrainType terrain) {
    return HexScoreRules.cityScoreFromTerrain(terrain);
  }

  static int defenseScoreFromTerrain(TerrainType terrain) {
    return HexScoreRules.defenseScoreFromTerrain(terrain);
  }

  static int economyScoreFromTerrain(TerrainType terrain) {
    return HexScoreRules.economyScoreFromTerrain(terrain);
  }

  static HexScore applyRiverBonus(HexScore score) {
    return HexScoreRules.applyRiverBonus(score);
  }

  static HexScore scoreResource(ResourceType resource) {
    return HexScoreRules.scoreResource(resource);
  }

  static HexScore applyPenaltyRules({
    required TerrainType? terrain,
    required bool hasRiver,
    required bool hasResources,
    required HexScore score,
  }) {
    return HexScoreRules.applyPenaltyRules(
      terrain: terrain,
      hasRiver: hasRiver,
      hasResources: hasResources,
      score: score,
    );
  }
}
