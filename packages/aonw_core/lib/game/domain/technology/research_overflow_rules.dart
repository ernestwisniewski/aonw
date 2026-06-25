import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology/player_research_state.dart';
import 'package:aonw_core/game/domain/technology/research_cost_calculator.dart';
import 'package:aonw_core/game/domain/technology/technology_boost_evaluator.dart';
import 'package:aonw_core/game/domain/technology/technology_id.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/map/domain/map_data.dart';

abstract final class ResearchOverflowRules {
  static const int maxOverflowCostNumerator = 1;
  static const int maxOverflowCostDenominator = 2;

  static PlayerResearchState applyToSelectedTechnology({
    required String playerId,
    required PlayerResearchState playerResearch,
    required TechnologyId technologyId,
    required Iterable<GameCity> cities,
    required Iterable<FieldImprovement> fieldImprovements,
    required TechnologyRuleset ruleset,
    MapData? mapData,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    var updated = playerResearch.withActiveTechnology(technologyId);
    final overflow = playerResearch.scienceOverflow;
    if (overflow <= 0) return updated;

    final cost = _effectiveCostForSelection(
      playerId: playerId,
      technologyId: technologyId,
      cities: cities,
      fieldImprovements: fieldImprovements,
      ruleset: ruleset,
      mapData: mapData,
      paceBalance: paceBalance,
    );
    final cap = cost * maxOverflowCostNumerator ~/ maxOverflowCostDenominator;
    final applied = overflow < cap ? overflow : cap;
    if (applied > 0) {
      updated = updated.withProgress(
        technologyId,
        updated.progressFor(technologyId) + applied,
      );
    }
    return updated.withScienceOverflow(0);
  }

  static int _effectiveCostForSelection({
    required String playerId,
    required TechnologyId technologyId,
    required Iterable<GameCity> cities,
    required Iterable<FieldImprovement> fieldImprovements,
    required TechnologyRuleset ruleset,
    MapData? mapData,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final technology = ruleset.definitionFor(technologyId);
    final boostDiscount = mapData == null
        ? 0.0
        : TechnologyBoostEvaluator.bestDiscountFor(
            playerId: playerId,
            technology: technology,
            cities: cities,
            fieldImprovements: fieldImprovements,
            mapData: mapData,
          );
    final cityCount = cities
        .where((city) => city.ownerPlayerId == playerId)
        .length;
    return ResearchCostCalculator.effectiveCost(
      technology: technology,
      cityCount: cityCount,
      ruleset: ruleset,
      boostDiscount: boostDiscount,
      paceBalance: paceBalance,
    );
  }
}
