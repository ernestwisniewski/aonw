import 'package:aonw_core/game/domain/stability/stability_calculator.dart';
import 'package:aonw_core/game/domain/stability/stability_inputs.dart';
import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';
import 'package:test/test.dart';

void main() {
  const ruleset = StabilityRuleset.standard;

  StabilityInputs inputs({
    int cityCount = 1,
    int conqueredCityCount = 0,
    int sumCohesionCost = 0,
    int sumPopulationOverThreshold = 0,
    int buildingSources = 0,
    int luxurySources = 0,
    int techSources = 0,
    int artifactSources = 0,
    int warWeariness = 0,
    double controlPercent = 0,
    int playerCount = 4,
  }) {
    return StabilityInputs(
      playerId: 'p1',
      cityCount: cityCount,
      conqueredCityCount: conqueredCityCount,
      sumCohesionCost: sumCohesionCost,
      sumPopulationOverThreshold: sumPopulationOverThreshold,
      buildingSources: buildingSources,
      luxurySources: luxurySources,
      techSources: techSources,
      artifactSources: artifactSources,
      warWeariness: warWeariness,
      controlPercent: controlPercent,
      playerCount: playerCount,
    );
  }

  test('a lone capital nets the base order', () {
    final breakdown = StabilityCalculator.calculate(
      inputs: inputs(),
      ruleset: ruleset,
    );
    expect(breakdown.cityCost, 0);
    expect(breakdown.net, ruleset.baseOrder);
  });

  test('extra cities cost per city beyond the first', () {
    final breakdown = StabilityCalculator.calculate(
      inputs: inputs(cityCount: 3),
      ruleset: ruleset,
    );
    expect(breakdown.cityCost, 2 * ruleset.costPerCity);
  });

  test('sources and costs aggregate into net', () {
    final breakdown = StabilityCalculator.calculate(
      inputs: inputs(
        cityCount: 2,
        conqueredCityCount: 1,
        sumCohesionCost: 3,
        sumPopulationOverThreshold: 2,
        buildingSources: 4,
        luxurySources: 2,
        warWeariness: 1,
        controlPercent: 55,
      ),
      ruleset: ruleset,
    );

    expect(breakdown.sources, 12);
    expect(breakdown.cityCost, 2);
    expect(breakdown.populationCost, 2);
    expect(breakdown.conqueredCityCost, 3);
    expect(breakdown.warWearinessCost, 1);
    expect(breakdown.hegemonyTax, 3);
    expect(breakdown.costs, 14);
    expect(breakdown.net, -2);
  });
}
