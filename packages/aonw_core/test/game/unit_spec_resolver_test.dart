import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('UnitSpecResolver', () {
    test('resolves every standard unit spec', () {
      for (final type in GameUnitType.values) {
        expect(
          UnitSpecResolver.standard.specFor(type),
          UnitCatalog.specFor(type),
        );
      }
    });

    test('supports custom unit spec catalogs', () {
      final warriorSpec = UnitCatalog.specFor(GameUnitType.warrior);
      final resolver = UnitSpecResolver(
        catalog: {
          ...UnitCatalog.standard,
          GameUnitType.warrior: warriorSpec.copyWith(productionCost: 99),
        },
      );

      expect(resolver.specFor(GameUnitType.warrior).productionCost, 99);
      expect(UnitCatalog.specFor(GameUnitType.warrior).productionCost, 15);
    });

    test('throws when a unit spec is missing', () {
      const resolver = UnitSpecResolver(catalog: {});

      expect(() => resolver.specFor(GameUnitType.warrior), throwsStateError);
    });
  });

  group('UnitProductionCatalog', () {
    test('standard production catalog matches resolved unit specs', () {
      final expected = UnitProductionCatalog.fromUnitSpecs(
        UnitSpecResolver.standard,
      );

      expect(
        UnitProductionCatalog.standard.keys,
        unorderedEquals(expected.keys),
      );
      for (final type in GameUnitType.values) {
        final standard = UnitProductionCatalog.standard[type]!;
        final fromSpec = expected[type]!;

        expect(standard.type, fromSpec.type, reason: '$type type');
        expect(
          standard.productionCost,
          fromSpec.productionCost,
          reason: '$type production cost',
        );
        _expectRequirements(
          standard.requirements,
          fromSpec.requirements,
          reason: '$type requirements',
        );
      }
    });

    test('builds production definitions from resolved unit specs', () {
      final production = UnitProductionCatalog.fromUnitSpecs(
        UnitSpecResolver.standard,
      );

      expect(production.keys, unorderedEquals(GameUnitType.values));
      for (final type in GameUnitType.values) {
        final spec = UnitCatalog.specFor(type);
        final definition = production[type]!;

        expect(definition.type, spec.type, reason: '$type type');
        expect(
          definition.productionCost,
          spec.productionCost,
          reason: '$type production cost',
        );
        _expectRequirements(
          definition.requirements,
          spec.requirements,
          reason: '$type requirements',
        );
      }
    });

    test('carries custom specs into city production rulesets', () {
      final workerSpec = UnitCatalog.specFor(GameUnitType.worker);
      final cityRuleset = CityRulesets.fromUnitSpecs(
        UnitSpecResolver(
          catalog: {
            ...UnitCatalog.standard,
            GameUnitType.worker: workerSpec.copyWith(productionCost: 33),
          },
        ),
      );

      expect(
        cityRuleset.unitDefinitionFor(GameUnitType.worker).productionCost,
        33,
      );
      expect(
        CityProductionRules.unitProductionCost(
          GameUnitType.worker,
          ruleset: cityRuleset,
          paceBalance: PaceBalance.long120,
        ),
        33,
      );
      expect(
        CityRulesets.standard
            .unitDefinitionFor(GameUnitType.worker)
            .productionCost,
        14,
      );
    });
  });
}

void _expectRequirements(
  List<UnitProductionRequirement> actual,
  List<UnitProductionRequirement> expected, {
  required String reason,
}) {
  expect(actual.length, expected.length, reason: reason);
  for (var i = 0; i < actual.length; i++) {
    switch ((actual[i], expected[i])) {
      case (
        UnitResourceRequirement(resources: final actualResources),
        UnitResourceRequirement(resources: final expectedResources),
      ):
        expect(actualResources, expectedResources, reason: reason);
      case (
        UnitStockpileCostRequirement(options: final actualOptions),
        UnitStockpileCostRequirement(options: final expectedOptions),
      ):
        expect(actualOptions, expectedOptions, reason: reason);
      default:
        fail(
          'Requirement kinds differ at index $i: ${actual[i]} vs ${expected[i]}',
        );
    }
  }
}
