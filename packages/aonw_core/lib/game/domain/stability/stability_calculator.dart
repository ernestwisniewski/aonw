import 'package:aonw_core/game/domain/stability/hegemony_pressure_calculator.dart';
import 'package:aonw_core/game/domain/stability/stability_breakdown.dart';
import 'package:aonw_core/game/domain/stability/stability_inputs.dart';
import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';

abstract final class StabilityCalculator {
  static StabilityBreakdown calculate({
    required StabilityInputs inputs,
    StabilityRuleset ruleset = StabilityRuleset.standard,
  }) {
    final citiesBeyondFirst = inputs.cityCount <= 1 ? 0 : inputs.cityCount - 1;
    return StabilityBreakdown(
      playerId: inputs.playerId,
      baseOrder: ruleset.baseOrder,
      buildingSources: inputs.buildingSources,
      luxurySources: inputs.luxurySources,
      techSources: inputs.techSources,
      artifactSources: inputs.artifactSources,
      cityCost: citiesBeyondFirst * ruleset.costPerCity,
      populationCost:
          inputs.sumPopulationOverThreshold *
          ruleset.costPerPopulationOverThreshold,
      cohesionCost: inputs.sumCohesionCost,
      conqueredCityCost: inputs.conqueredCityCount * ruleset.conqueredCityCost,
      warWearinessCost: inputs.warWeariness,
      hegemonyTax: HegemonyPressureCalculator.hegemonyTax(
        controlPercent: inputs.controlPercent,
        playerCount: inputs.playerCount,
        ruleset: ruleset,
      ),
    );
  }
}
