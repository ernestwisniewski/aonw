import 'package:aonw/game/domain/hex_assessment/hex_assessment_model.dart';
import 'package:aonw/game/domain/hex_assessment/hex_kind_groups.dart';
import 'package:aonw/game/domain/hex_assessment/hex_score.dart';
import 'package:aonw/map/domain/terrain_type.dart';

abstract final class HexRecommendationRules {
  static HexRecommendation recommend({
    required HexAssessmentKind kind,
    required HexScore score,
    required TerrainType? terrain,
  }) {
    if (terrain == TerrainType.ocean ||
        terrain == TerrainType.lake ||
        terrain == TerrainType.mountain) {
      return HexRecommendation.avoid;
    }
    if (HexKindGroups.city.contains(kind) || score.city >= 7) {
      return HexRecommendation.foundCity;
    }
    if (HexKindGroups.defense.contains(kind) || score.defense >= 6) {
      return HexRecommendation.defendHere;
    }
    if (HexKindGroups.economy.contains(kind) || score.economy >= 6) {
      return HexRecommendation.exploitEconomy;
    }
    if (HexKindGroups.avoid.contains(kind) ||
        (score.city <= 0 && score.economy <= 0)) {
      return HexRecommendation.avoid;
    }
    return HexRecommendation.neutral;
  }
}
