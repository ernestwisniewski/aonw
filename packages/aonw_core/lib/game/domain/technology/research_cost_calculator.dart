import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology/technology_definition.dart';
import 'package:aonw_core/game/domain/technology/technology_era.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';

abstract final class ResearchCostCalculator {
  static int effectiveCost({
    required TechnologyDefinition technology,
    required int cityCount,
    required TechnologyRuleset ruleset,
    double? boostDiscount,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final extraCities = cityCount > 1 ? cityCount - 1 : 0;
    final cityMultiplier =
        1 + ruleset.costs.cityScalingPerExtraCity * extraCities;
    final discount = boostDiscount ?? 0;
    final boostMultiplier = 1 - discount.clamp(0, 1);
    final eraMultiplier = switch (technology.era) {
      TechnologyEra.foundation ||
      TechnologyEra.settlement ||
      TechnologyEra.expansion => 1.0,
      TechnologyEra.specialization =>
        ruleset.costs.specializationEraCostMultiplier,
      TechnologyEra.industry => ruleset.costs.industryEraCostMultiplier,
      TechnologyEra.strategy => ruleset.costs.strategyEraCostMultiplier,
    };

    final baseCost =
        (technology.baseCost * cityMultiplier * boostMultiplier * eraMultiplier)
            .ceil();
    final cost = baseCost > 1 ? baseCost : 1;
    return paceBalance.researchCost(cost);
  }
}
