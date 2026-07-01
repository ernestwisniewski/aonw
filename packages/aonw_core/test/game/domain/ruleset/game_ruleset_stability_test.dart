import 'package:aonw_core/game/domain/ruleset/game_ruleset.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:test/test.dart';

void main() {
  test('standard ruleset exposes stability rules', () {
    expect(GameRuleset.standard().stability, StabilityRuleset.standard);
    expect(GameRuleset.defaults.stability, StabilityRuleset.standard);
  });

  test('copyWith can replace stability rules', () {
    const stability = StabilityRuleset(
      baseOrder: 4,
      costPerCity: 3,
      populationCostThreshold: 5,
      costPerPopulationOverThreshold: 2,
      conqueredCityCost: 4,
      reachRadius: 3,
      frontierCostPerHexBeyondReach: 2,
      disconnectedCityCost: 2,
      warWearinessCap: 7,
      warWearinessAttackFreePerTurn: 1,
      warWearinessPerCityLost: 3,
      warWearinessPeaceDecay: 1,
      warWearinessTreatyDecay: 2,
      contentThreshold: 5,
      unrestThreshold: -5,
      relativeStandingOffset: 2,
      hegemonyK: 1.4,
      hegemonyTaxPointsPerCost: 4,
    );

    expect(
      GameRuleset.standard().copyWith(stability: stability).stability,
      stability,
    );
  });
}
