import 'package:aonw_core/game/domain/technology/technology_catalog.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';

abstract final class TechnologyRulesets {
  static const standard = TechnologyRuleset(
    science: ScienceBalance(
      baseSciencePerCity: 2,
      maxSciencePerCity: 0,
      secondScienceBuildingMultiplier: 0.70,
      thirdScienceBuildingMultiplier: 0.35,
    ),
    costs: TechCostBalance(
      cityScalingPerExtraCity: 0.18,
      defaultBoostDiscount: 0.25,
      specializationEraCostMultiplier: 1.30,
      industryEraCostMultiplier: 1.75,
      strategyEraCostMultiplier: 3.50,
    ),
    technologies: TechnologyCatalog.standard,
  );
}
