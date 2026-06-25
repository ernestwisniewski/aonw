import 'package:aonw/game/domain/hex_assessment/hex_assessment_model.dart';
import 'package:aonw/game/domain/hex_assessment/hex_kind_groups.dart';
import 'package:aonw/game/domain/hex_assessment/hex_score.dart';
import 'package:aonw/game/domain/hex_assessment/hex_score_rules.dart';
import 'package:aonw/game/domain/hex_assessment/resource_groups.dart';
import 'package:aonw/map/domain/terrain_type.dart';

abstract final class HexTagRules {
  static List<HexAssessmentTag> tagsFor({
    required HexAssessmentKind kind,
    required HexScore score,
    required TerrainType? terrain,
    required bool hasRiver,
    required Set<ResourceType> resources,
    required bool canFoundCity,
  }) {
    final tags = <HexAssessmentTag>[];

    void add(HexAssessmentTag tag) {
      if (!tags.contains(tag)) tags.add(tag);
    }

    if (HexKindGroups.avoid.contains(kind)) add(HexAssessmentTag.hostile);
    if (HexKindGroups.fertile.contains(kind) || score.city >= 5 || hasRiver) {
      add(HexAssessmentTag.fertile);
    }
    if (HexKindGroups.defense.contains(kind) || score.defense >= 4) {
      add(HexAssessmentTag.defense);
    }
    if (HexKindGroups.economy.contains(kind) || score.economy >= 5) {
      add(HexAssessmentTag.trade);
    }
    if (HexScoreRules.scoreTerrain(terrain).defense >= 2 ||
        HexKindGroups.production.contains(kind)) {
      add(HexAssessmentTag.production);
    }
    if (HexResourceGroups.hasAny(resources, HexResourceGroups.strategic)) {
      add(HexAssessmentTag.strategic);
    }
    if (terrain == TerrainType.coast ||
        terrain == TerrainType.lake ||
        terrain == TerrainType.ocean) {
      add(HexAssessmentTag.water);
    }
    if (canFoundCity &&
        (HexKindGroups.city.contains(kind) || score.city >= 5)) {
      add(HexAssessmentTag.city);
    }

    return tags;
  }
}
