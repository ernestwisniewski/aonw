import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'city_production_start_unit_test_support.dart';

void main() {
  group('CityProductionCommandResolver.startUnitProduction', () {
    test(
      'preserves the authoritative rejection precedence and input identity',
      () {
        final missing = unitCharacterizationState(
          cities: unitCharacterizationCitiesWithTarget(
            unitCharacterizationCity(id: 'other_city'),
          ),
        );
        _expectKernelRejected(
          state: missing,
          command: const StartUnitProductionCommand(
            'missing_city',
            GameUnitType.warship,
          ),
          actorPlayerId: unitCharacterizationOtherPlayerId,
          reason: 'city_not_found',
        );

        final foreign = unitCharacterizationState(
          cities: unitCharacterizationCitiesWithTarget(
            unitCharacterizationCity(
              ownerPlayerId: unitCharacterizationOtherPlayerId,
            ),
          ),
          units: unitCharacterizationWorkers(
            ownerPlayerId: unitCharacterizationOtherPlayerId,
            count: 6,
          ),
        );
        _expectKernelRejected(
          state: foreign,
          command: const StartUnitProductionCommand(
            'city_1',
            GameUnitType.warship,
          ),
          reason: 'city_not_controlled',
        );

        final unavailable = unitCharacterizationState(
          cities: unitCharacterizationCitiesWithTarget(
            unitCharacterizationCity(),
          ),
        );
        _expectKernelRejected(
          state: unavailable,
          command: const StartUnitProductionCommand(
            'city_1',
            GameUnitType.cavalry,
          ),
          reason: 'unit_production_not_available',
        );

        final resourceMissing = unitCharacterizationState(
          cities: unitCharacterizationCitiesWithTarget(
            unitCharacterizationCity(),
          ),
          research: unitCharacterizationResearch({
            TechnologyId.horsebackRiding,
          }),
        );
        _expectKernelRejected(
          state: resourceMissing,
          command: const StartUnitProductionCommand(
            'city_1',
            GameUnitType.cavalry,
          ),
          reason: 'unit_production_requires_resource',
        );

        final coastMissing = unitCharacterizationState(
          cities: unitCharacterizationCitiesWithTarget(
            unitCharacterizationCity(),
          ),
          research: unitCharacterizationResearch({TechnologyId.cartography}),
        );
        _expectKernelRejected(
          state: coastMissing,
          command: const StartUnitProductionCommand(
            'city_1',
            GameUnitType.scoutShip,
          ),
          reason: 'unit_production_requires_coast',
        );

        final supplyFull = unitCharacterizationState(
          cities: unitCharacterizationCitiesWithTarget(
            unitCharacterizationCity(),
          ),
          units: unitCharacterizationWorkers(
            ownerPlayerId: unitCharacterizationPlayerId,
            count: 3,
          ),
        );
        _expectKernelRejected(
          state: supplyFull,
          command: const StartUnitProductionCommand(
            'city_1',
            GameUnitType.warrior,
          ),
          reason: 'unit_supply_limit_reached',
        );
      },
    );

    test('forwards custom rules, technology, map, imports, and pace', () {
      final agreement = unitCharacterizationIronImport();
      final cities = unitCharacterizationCitiesWithTarget(
        unitCharacterizationCity(productionOverflow: 100),
      );
      final state = unitCharacterizationState(
        cities: cities,
        research: unitCharacterizationResearch({TechnologyId.writing}),
        resourceTradeAgreements: [agreement],
      );
      final result = _startKernel(
        state: state,
        command: const StartUnitProductionCommand(
          'city_1',
          GameUnitType.warship,
        ),
        mapView: unitCharacterizationMap(coastal: true),
        cityRuleset: _customUnitRuleset(),
        technologyRuleset: _customUnitTechnologyRuleset(),
        paceBalance: PaceBalance.standard60,
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(result.cities, isNot(same(cities)));
      expect(() => result.cities.clear(), throwsUnsupportedError);
      expect(result.cities.last, same(cities.last));
      expect(result.cities.first, isNot(same(cities.first)));
      expect(
        result.cities.first.productionQueue,
        CityProductionQueue.unit(
          unitType: GameUnitType.warship,
          investedProduction: 8,
        ),
      );
      expect(result.cities.first.productionOverflow, 0);
      expect(cities.first.productionQueue, isNull);
      expect(cities.first.productionOverflow, 100);
    });
  });
}

CityProductionCommandResult _startKernel({
  required DomainState state,
  required StartUnitProductionCommand command,
  required MapReadView mapView,
  String actorPlayerId = unitCharacterizationPlayerId,
  CityRuleset cityRuleset = CityRulesets.standard,
  TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  PaceBalance paceBalance = PaceBalance.unlimited,
}) {
  return CityProductionCommandResolver.startUnitProduction(
    cities: state.cities,
    units: state.units,
    artifacts: state.artifacts,
    fieldImprovements: state.fieldImprovements,
    research: state.research,
    resourceTradeAgreements: state.resourceTradeAgreements,
    mapView: mapView,
    command: command,
    actorPlayerId: actorPlayerId,
    cityRuleset: cityRuleset,
    technologyRuleset: technologyRuleset,
    paceBalance: paceBalance,
  );
}

void _expectKernelRejected({
  required DomainState state,
  required StartUnitProductionCommand command,
  required String reason,
  String actorPlayerId = unitCharacterizationPlayerId,
}) {
  final result = _startKernel(
    state: state,
    command: command,
    actorPlayerId: actorPlayerId,
    mapView: unitCharacterizationMap(),
  );
  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(result.cities, same(state.cities));
}

CityRuleset _customUnitRuleset() {
  final warship = CityRulesets.standard.unitDefinitionFor(GameUnitType.warship);
  return CityRulesets.standard.copyWith(
    units: {
      ...CityRulesets.standard.units,
      GameUnitType.warship: UnitProductionDefinition(
        type: warship.type,
        productionCost: 20,
        requirements: warship.requirements,
      ),
    },
  );
}

TechnologyRuleset _customUnitTechnologyRuleset() {
  final writing = TechnologyRulesets.standard.definitionFor(
    TechnologyId.writing,
  );
  return TechnologyRuleset(
    science: TechnologyRulesets.standard.science,
    costs: TechnologyRulesets.standard.costs,
    technologies: {
      TechnologyId.writing: TechnologyDefinition(
        id: writing.id,
        name: writing.name,
        description: writing.description,
        era: writing.era,
        baseCost: writing.baseCost,
        treePosition: writing.treePosition,
        prerequisites: writing.prerequisites,
        blockedBy: writing.blockedBy,
        unlocks: [
          ...writing.unlocks,
          const UnlockUnitType(GameUnitType.warship),
        ],
        effects: writing.effects,
        boosts: writing.boosts,
      ),
    },
  );
}
