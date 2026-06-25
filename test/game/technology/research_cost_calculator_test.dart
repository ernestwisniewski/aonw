import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResearchCostCalculator', () {
    const ruleset = TechnologyRulesets.standard;

    test('does not scale cost for the first city', () {
      final technology = ruleset.definitionFor(TechnologyId.advancedTrade);

      final cost = ResearchCostCalculator.effectiveCost(
        technology: technology,
        cityCount: 1,
        ruleset: ruleset,
      );

      expect(cost, 14);
    });

    test('scales by extra cities according to the balance table', () {
      final technology = ruleset.definitionFor(TechnologyId.advancedTrade);

      int costFor(int cityCount) => ResearchCostCalculator.effectiveCost(
        technology: technology,
        cityCount: cityCount,
        ruleset: ruleset,
      );

      expect(costFor(1), 14);
      expect(costFor(2), 17);
      expect(costFor(3), 20);
      expect(costFor(4), 22);
      expect(costFor(5), 25);
    });

    test('applies technology boost discounts', () {
      final technology = ruleset.definitionFor(TechnologyId.trade);

      final cost = ResearchCostCalculator.effectiveCost(
        technology: technology,
        cityCount: 1,
        ruleset: ruleset,
        boostDiscount: ruleset.costs.defaultBoostDiscount,
      );

      expect(cost, 6);
    });

    test('applies strategy era multiplier after city scaling', () {
      final technology = ruleset.definitionFor(TechnologyId.strategy);

      final cost = ResearchCostCalculator.effectiveCost(
        technology: technology,
        cityCount: 2,
        ruleset: ruleset,
      );

      expect(cost, 124);
    });

    test('clamps invalid boost discounts', () {
      final technology = ruleset.definitionFor(TechnologyId.trade);

      final cost = ResearchCostCalculator.effectiveCost(
        technology: technology,
        cityCount: 1,
        ruleset: ruleset,
        boostDiscount: 2,
      );

      expect(cost, 1);
    });
  });
}
