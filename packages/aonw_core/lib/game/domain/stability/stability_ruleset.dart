class StabilityRuleset {
  final int baseOrder;
  final int costPerCity;
  final int populationCostThreshold;
  final int costPerPopulationOverThreshold;
  final int conqueredCityCost;
  final int reachRadius;
  final int frontierCostPerHexBeyondReach;
  final int disconnectedCityCost;
  final int warWearinessCap;
  final int warWearinessAttackFreePerTurn;
  final int warWearinessPerCityLost;
  final int warWearinessPeaceDecay;
  final int warWearinessTreatyDecay;
  final int contentThreshold;
  final int unrestThreshold;
  final int relativeStandingOffset;
  final double hegemonyK;
  final double hegemonyTaxPointsPerCost;
  final int stabilityPerOrderBuilding;
  final int stabilityPerOrderTechnology;
  final int stabilityPerLuxuryResource;
  final int stabilityPerStoredArtifact;

  const StabilityRuleset({
    required this.baseOrder,
    required this.costPerCity,
    required this.populationCostThreshold,
    required this.costPerPopulationOverThreshold,
    required this.conqueredCityCost,
    required this.reachRadius,
    required this.frontierCostPerHexBeyondReach,
    required this.disconnectedCityCost,
    required this.warWearinessCap,
    required this.warWearinessAttackFreePerTurn,
    required this.warWearinessPerCityLost,
    required this.warWearinessPeaceDecay,
    required this.warWearinessTreatyDecay,
    required this.contentThreshold,
    required this.unrestThreshold,
    required this.relativeStandingOffset,
    required this.hegemonyK,
    required this.hegemonyTaxPointsPerCost,
    required this.stabilityPerOrderBuilding,
    required this.stabilityPerOrderTechnology,
    required this.stabilityPerLuxuryResource,
    required this.stabilityPerStoredArtifact,
  });

  static const StabilityRuleset standard = StabilityRuleset(
    baseOrder: 6,
    costPerCity: 2,
    populationCostThreshold: 6,
    costPerPopulationOverThreshold: 1,
    conqueredCityCost: 3,
    reachRadius: 4,
    frontierCostPerHexBeyondReach: 1,
    disconnectedCityCost: 1,
    warWearinessCap: 8,
    warWearinessAttackFreePerTurn: 1,
    warWearinessPerCityLost: 2,
    warWearinessPeaceDecay: 1,
    warWearinessTreatyDecay: 2,
    contentThreshold: 4,
    unrestThreshold: -4,
    relativeStandingOffset: 3,
    hegemonyK: 1.6,
    hegemonyTaxPointsPerCost: 5,
    stabilityPerOrderBuilding: 1,
    stabilityPerOrderTechnology: 2,
    stabilityPerLuxuryResource: 1,
    stabilityPerStoredArtifact: 1,
  );

  StabilityRuleset copyWith({
    int? baseOrder,
    int? costPerCity,
    int? populationCostThreshold,
    int? costPerPopulationOverThreshold,
    int? conqueredCityCost,
    int? reachRadius,
    int? frontierCostPerHexBeyondReach,
    int? disconnectedCityCost,
    int? warWearinessCap,
    int? warWearinessAttackFreePerTurn,
    int? warWearinessPerCityLost,
    int? warWearinessPeaceDecay,
    int? warWearinessTreatyDecay,
    int? contentThreshold,
    int? unrestThreshold,
    int? relativeStandingOffset,
    double? hegemonyK,
    double? hegemonyTaxPointsPerCost,
    int? stabilityPerOrderBuilding,
    int? stabilityPerOrderTechnology,
    int? stabilityPerLuxuryResource,
    int? stabilityPerStoredArtifact,
  }) {
    return StabilityRuleset(
      baseOrder: baseOrder ?? this.baseOrder,
      costPerCity: costPerCity ?? this.costPerCity,
      populationCostThreshold:
          populationCostThreshold ?? this.populationCostThreshold,
      costPerPopulationOverThreshold:
          costPerPopulationOverThreshold ?? this.costPerPopulationOverThreshold,
      conqueredCityCost: conqueredCityCost ?? this.conqueredCityCost,
      reachRadius: reachRadius ?? this.reachRadius,
      frontierCostPerHexBeyondReach:
          frontierCostPerHexBeyondReach ?? this.frontierCostPerHexBeyondReach,
      disconnectedCityCost: disconnectedCityCost ?? this.disconnectedCityCost,
      warWearinessCap: warWearinessCap ?? this.warWearinessCap,
      warWearinessAttackFreePerTurn:
          warWearinessAttackFreePerTurn ?? this.warWearinessAttackFreePerTurn,
      warWearinessPerCityLost:
          warWearinessPerCityLost ?? this.warWearinessPerCityLost,
      warWearinessPeaceDecay:
          warWearinessPeaceDecay ?? this.warWearinessPeaceDecay,
      warWearinessTreatyDecay:
          warWearinessTreatyDecay ?? this.warWearinessTreatyDecay,
      contentThreshold: contentThreshold ?? this.contentThreshold,
      unrestThreshold: unrestThreshold ?? this.unrestThreshold,
      relativeStandingOffset:
          relativeStandingOffset ?? this.relativeStandingOffset,
      hegemonyK: hegemonyK ?? this.hegemonyK,
      hegemonyTaxPointsPerCost:
          hegemonyTaxPointsPerCost ?? this.hegemonyTaxPointsPerCost,
      stabilityPerOrderBuilding:
          stabilityPerOrderBuilding ?? this.stabilityPerOrderBuilding,
      stabilityPerOrderTechnology:
          stabilityPerOrderTechnology ?? this.stabilityPerOrderTechnology,
      stabilityPerLuxuryResource:
          stabilityPerLuxuryResource ?? this.stabilityPerLuxuryResource,
      stabilityPerStoredArtifact:
          stabilityPerStoredArtifact ?? this.stabilityPerStoredArtifact,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StabilityRuleset &&
        other.baseOrder == baseOrder &&
        other.costPerCity == costPerCity &&
        other.populationCostThreshold == populationCostThreshold &&
        other.costPerPopulationOverThreshold ==
            costPerPopulationOverThreshold &&
        other.conqueredCityCost == conqueredCityCost &&
        other.reachRadius == reachRadius &&
        other.frontierCostPerHexBeyondReach == frontierCostPerHexBeyondReach &&
        other.disconnectedCityCost == disconnectedCityCost &&
        other.warWearinessCap == warWearinessCap &&
        other.warWearinessAttackFreePerTurn == warWearinessAttackFreePerTurn &&
        other.warWearinessPerCityLost == warWearinessPerCityLost &&
        other.warWearinessPeaceDecay == warWearinessPeaceDecay &&
        other.warWearinessTreatyDecay == warWearinessTreatyDecay &&
        other.contentThreshold == contentThreshold &&
        other.unrestThreshold == unrestThreshold &&
        other.relativeStandingOffset == relativeStandingOffset &&
        other.hegemonyK == hegemonyK &&
        other.hegemonyTaxPointsPerCost == hegemonyTaxPointsPerCost &&
        other.stabilityPerOrderBuilding == stabilityPerOrderBuilding &&
        other.stabilityPerOrderTechnology == stabilityPerOrderTechnology &&
        other.stabilityPerLuxuryResource == stabilityPerLuxuryResource &&
        other.stabilityPerStoredArtifact == stabilityPerStoredArtifact;
  }

  @override
  int get hashCode => Object.hashAll([
    baseOrder,
    costPerCity,
    populationCostThreshold,
    costPerPopulationOverThreshold,
    conqueredCityCost,
    reachRadius,
    frontierCostPerHexBeyondReach,
    disconnectedCityCost,
    warWearinessCap,
    warWearinessAttackFreePerTurn,
    warWearinessPerCityLost,
    warWearinessPeaceDecay,
    warWearinessTreatyDecay,
    contentThreshold,
    unrestThreshold,
    relativeStandingOffset,
    hegemonyK,
    hegemonyTaxPointsPerCost,
    stabilityPerOrderBuilding,
    stabilityPerOrderTechnology,
    stabilityPerLuxuryResource,
    stabilityPerStoredArtifact,
  ]);
}
