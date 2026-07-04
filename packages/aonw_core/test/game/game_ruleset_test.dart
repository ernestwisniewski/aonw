import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('GameRuleset', () {
    test('standard ruleset aggregates shared rulesets', () {
      final ruleset = GameRuleset.standard();

      expect(ruleset.city.progression, same(CityRulesets.standard.progression));
      expect(
        ruleset.city.cityCenterYield,
        CityRulesets.standard.cityCenterYield,
      );
      expect(ruleset.city.riverYield, CityRulesets.standard.riverYield);
      expect(
        ruleset.city.terrainYields,
        same(CityRulesets.standard.terrainYields),
      );
      expect(
        ruleset.city.resourceYields,
        same(CityRulesets.standard.resourceYields),
      );
      expect(
        ruleset.city.improvements,
        same(CityRulesets.standard.improvements),
      );
      expect(ruleset.city.buildings, same(CityRulesets.standard.buildings));
      _expectUnitProductionFromSpecs(ruleset.city);
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

void _expectUnitProductionFromSpecs(CityRuleset ruleset) {
  for (final type in GameUnitType.values) {
    final actual = ruleset.unitDefinitionFor(type);
    final spec = UnitSpecResolver.standard.specFor(type);

    expect(actual.type, spec.type, reason: '${type.name} type');
    expect(
      actual.productionCost,
      spec.productionCost,
      reason: '${type.name} production cost',
    );
    expect(
      actual.requirements.length,
      spec.requirements.length,
      reason: '${type.name} requirements length',
    );
    for (var i = 0; i < actual.requirements.length; i++) {
      expect(
        actual.requirements[i],
        spec.requirements[i],
        reason: '${type.name} requirement $i',
      );
    }
  }
}
