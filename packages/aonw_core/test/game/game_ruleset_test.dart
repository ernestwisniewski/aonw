import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('GameRuleset', () {
    test('standard ruleset aggregates shared rulesets', () {
      final ruleset = GameRuleset.standard();

      expect(ruleset.city, CityRulesets.standard);
      expect(ruleset.combat, CombatRuleset.standard);
      expect(ruleset.technology, TechnologyRulesets.standard);
    });

    test('defaults is a compile-time standard ruleset', () {
      expect(GameRuleset.defaults.city, CityRulesets.standard);
      expect(GameRuleset.defaults.combat, CombatRuleset.standard);
      expect(GameRuleset.defaults.technology, TechnologyRulesets.standard);
    });
  });
}
