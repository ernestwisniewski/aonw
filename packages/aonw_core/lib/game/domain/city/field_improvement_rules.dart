import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/field_improvement_requirement.dart';
import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/map/domain/map_data.dart';

abstract final class FieldImprovementRules {
  static FieldImprovementType? preferredFor(
    TileData tile, {
    CityRuleset ruleset = CityRulesets.standard,
    Iterable<FieldImprovementType>? allowedTypes,
  }) {
    final allowed = allowedTypes?.toSet();
    for (final definition in ruleset.improvements.values) {
      if (allowed != null && !allowed.contains(definition.type)) continue;
      if (definition.canImprove(tile)) return definition.type;
    }
    return null;
  }

  static bool canImprove(
    TileData tile, {
    CityRuleset ruleset = CityRulesets.standard,
    FieldImprovementType? type,
  }) {
    if (type != null) {
      return requirementFailureFor(type, tile, ruleset: ruleset) == null;
    }
    return preferredFor(tile, ruleset: ruleset) != null;
  }

  static FieldImprovementRequirementFailure? requirementFailureFor(
    FieldImprovementType type,
    TileData tile, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    return ruleset.improvementDefinitionFor(type).failureFor(tile);
  }

  static TileYield yieldFor(
    FieldImprovementType type, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    return ruleset.improvementYieldFor(type);
  }

  static bool isResourceSpecialist(
    FieldImprovementType type, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    return ruleset.improvementDefinitionFor(type).resourceSpecialist;
  }

  static int buildTurnsFor(
    FieldImprovementType type, {
    CityRuleset ruleset = CityRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    return paceBalance.improvementTurns(
      ruleset.improvementDefinitionFor(type).buildTurns,
    );
  }
}
