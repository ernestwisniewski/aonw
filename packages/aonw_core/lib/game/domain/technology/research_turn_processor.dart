import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology/research_cost_calculator.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/science_yield.dart';
import 'package:aonw_core/game/domain/technology/science_yield_calculator.dart';
import 'package:aonw_core/game/domain/technology/technology_availability_service.dart';
import 'package:aonw_core/game/domain/technology/technology_boost_evaluator.dart';
import 'package:aonw_core/game/domain/technology/technology_id.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_rulesets.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class ResearchTurnResult {
  final ResearchState research;
  final ScienceYieldBreakdown scienceYield;
  final TechnologyId? completedTechnologyId;
  final bool changed;

  const ResearchTurnResult({
    required this.research,
    required this.scienceYield,
    this.completedTechnologyId,
    this.changed = false,
  });
}

abstract final class ResearchTurnProcessor {
  static ResearchTurnResult advanceForPlayer({
    required String playerId,
    required List<GameCity> cities,
    required List<FieldImprovement> fieldImprovements,
    required ResearchState research,
    required MapData mapData,
    TechnologyRuleset ruleset = TechnologyRulesets.standard,
    CityRuleset cityRuleset = CityRulesets.standard,
    ScienceYieldBreakdown bonusScience = ScienceYieldBreakdown.empty,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final scienceYield = _combineScience(
      ScienceYieldCalculator.totalForPlayer(
        playerId: playerId,
        cities: cities,
        research: research,
        ruleset: ruleset,
        cityRuleset: cityRuleset,
      ),
      bonusScience,
    );

    final playerResearch = research.forPlayer(playerId);
    final activeTechnologyId = playerResearch.activeTechnologyId;
    if (activeTechnologyId == null) {
      return ResearchTurnResult(research: research, scienceYield: scienceYield);
    }

    final availability = TechnologyAvailabilityService.availabilityFor(
      technologyId: activeTechnologyId,
      playerResearch: playerResearch,
      ruleset: ruleset,
    );
    if (availability != TechnologyAvailability.active) {
      return ResearchTurnResult(
        research: research.updatePlayer(
          playerId,
          playerResearch.withActiveTechnology(null),
        ),
        scienceYield: scienceYield,
        changed: true,
      );
    }

    if (scienceYield.total <= 0) {
      return ResearchTurnResult(research: research, scienceYield: scienceYield);
    }

    final technology = ruleset.definitionFor(activeTechnologyId);
    final boostDiscount = TechnologyBoostEvaluator.bestDiscountFor(
      playerId: playerId,
      technology: technology,
      cities: cities,
      fieldImprovements: fieldImprovements,
      mapData: mapData,
    );
    final cityCount = cities
        .where((city) => city.ownerPlayerId == playerId)
        .length;
    final cost = ResearchCostCalculator.effectiveCost(
      technology: technology,
      cityCount: cityCount,
      ruleset: ruleset,
      boostDiscount: boostDiscount,
      paceBalance: paceBalance,
    );
    final progress =
        playerResearch.progressFor(activeTechnologyId) + scienceYield.total;

    final completed = progress >= cost;
    final updatedPlayer = completed
        ? playerResearch
              .unlock(activeTechnologyId)
              .withScienceOverflow(progress - cost)
        : playerResearch.withProgress(activeTechnologyId, progress);

    return ResearchTurnResult(
      research: research.updatePlayer(playerId, updatedPlayer),
      scienceYield: scienceYield,
      completedTechnologyId: completed ? activeTechnologyId : null,
      changed: true,
    );
  }

  static ScienceYieldBreakdown _combineScience(
    ScienceYieldBreakdown base,
    ScienceYieldBreakdown bonus,
  ) {
    if (bonus.total <= 0) return base;
    if (base.total <= 0) return bonus;

    final byCityId = <String, int>{...base.byCityId};
    for (final entry in bonus.byCityId.entries) {
      byCityId[entry.key] = (byCityId[entry.key] ?? 0) + entry.value;
    }

    return ScienceYieldBreakdown(
      total: base.total + bonus.total,
      byCityId: Map.unmodifiable(byCityId),
      sources: List.unmodifiable([...base.sources, ...bonus.sources]),
    );
  }
}
