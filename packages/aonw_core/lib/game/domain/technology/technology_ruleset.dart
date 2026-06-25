import 'package:aonw_core/game/domain/technology/technology_definition.dart';
import 'package:aonw_core/game/domain/technology/technology_id.dart';

class TechnologyRuleset {
  final ScienceBalance science;
  final TechCostBalance costs;
  final Map<TechnologyId, TechnologyDefinition> technologies;

  const TechnologyRuleset({
    required this.science,
    required this.costs,
    required this.technologies,
  });

  TechnologyDefinition definitionFor(TechnologyId id) {
    final definition = technologies[id];
    if (definition == null) {
      throw ArgumentError('Technology is not defined: ${id.name}');
    }
    return definition;
  }
}

class ScienceBalance {
  final int baseSciencePerCity;
  final int maxSciencePerCity;
  final double secondScienceBuildingMultiplier;
  final double thirdScienceBuildingMultiplier;

  const ScienceBalance({
    required this.baseSciencePerCity,
    required this.maxSciencePerCity,
    required this.secondScienceBuildingMultiplier,
    required this.thirdScienceBuildingMultiplier,
  });
}

class TechCostBalance {
  final double cityScalingPerExtraCity;
  final double defaultBoostDiscount;
  final double specializationEraCostMultiplier;
  final double industryEraCostMultiplier;
  final double strategyEraCostMultiplier;

  const TechCostBalance({
    required this.cityScalingPerExtraCity,
    required this.defaultBoostDiscount,
    this.specializationEraCostMultiplier = 1.0,
    this.industryEraCostMultiplier = 1.0,
    required this.strategyEraCostMultiplier,
  });
}
