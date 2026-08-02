import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameRuleset', () {
    test('GameRuleset.standard() creates standard ruleset', () {
      final ruleset = GameRuleset.standard();
      expect(ruleset.city, isA<CityRuleset>());
      expect(ruleset.combat, isA<CombatRuleset>());
      expect(ruleset.technology, isA<TechnologyRuleset>());
    });

    test('GameRuleset.standard().city is sourced from unit specs', () {
      final ruleset = GameRuleset.standard();
      final expectedUnits = UnitProductionCatalog.fromUnitSpecs(
        UnitSpecResolver.standard,
      );

      expect(ruleset.city.units.keys, unorderedEquals(expectedUnits.keys));
      for (final type in GameUnitType.values) {
        expect(
          ruleset.city.unitDefinitionFor(type).productionCost,
          UnitCatalog.specFor(type).productionCost,
          reason: '$type production cost',
        );
      }
    });

    test(
      'GameRuleset.standard().technology equals TechnologyRulesets.standard',
      () {
        final ruleset = GameRuleset.standard();
        expect(ruleset.technology, TechnologyRulesets.standard);
      },
    );

    test('GameRuleset.standard().combat equals CombatRuleset.standard', () {
      final ruleset = GameRuleset.standard();
      expect(ruleset.combat, CombatRuleset.standard);
    });

    test('GameRuleset constructor stores both rulesets', () {
      const ruleset = GameRuleset(
        city: CityRulesets.standard,
        combat: CombatRuleset.standard,
        technology: TechnologyRulesets.standard,
      );
      expect(ruleset.city, CityRulesets.standard);
      expect(ruleset.combat, CombatRuleset.standard);
      expect(ruleset.technology, TechnologyRulesets.standard);
    });
  });
}
