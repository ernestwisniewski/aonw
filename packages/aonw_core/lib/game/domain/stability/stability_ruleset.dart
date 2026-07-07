import 'package:freezed_annotation/freezed_annotation.dart';

part 'stability_ruleset.freezed.dart';

@freezed
abstract class StabilityRuleset with _$StabilityRuleset {
  const StabilityRuleset._();

  const factory StabilityRuleset({
    required int baseOrder,
    required int costPerCity,
    required int populationCostThreshold,
    required int costPerPopulationOverThreshold,
    required int conqueredCityCost,
    required int reachRadius,
    required int frontierCostPerHexBeyondReach,
    required int disconnectedCityCost,
    required int warWearinessCap,
    required int warWearinessAttackFreePerTurn,
    required int warWearinessPerCityLost,
    required int warWearinessPeaceDecay,
    required int warWearinessTreatyDecay,
    required int contentThreshold,
    required int unrestThreshold,
    required int relativeStandingOffset,
    required double hegemonyK,
    required double hegemonyTaxPointsPerCost,
    required int stabilityPerOrderBuilding,
    required int stabilityPerOrderTechnology,
    required int stabilityPerLuxuryResource,
    required int stabilityPerStoredArtifact,
  }) = _StabilityRuleset;

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
}
