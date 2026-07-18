import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'persistent_city_production_start_unit_characterization_test_support.dart';

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

  group('startUnitProduction adapters', () {
    test('preserve persistent/domain parity and structural sharing', () {
      final agreement = unitCharacterizationIronImport();
      final persistent = unitCharacterizationState(
        cities: unitCharacterizationCitiesWithTarget(
          unitCharacterizationCity(productionOverflow: 100),
        ),
        research: unitCharacterizationResearch({TechnologyId.writing}),
        resourceTradeAgreements: [agreement],
      );
      final domain = _domainFromPersistent(persistent);

      final results = _startAdapters(
        persistent: persistent,
        domain: domain,
        command: const StartUnitProductionCommand(
          'city_1',
          GameUnitType.warship,
        ),
        mapView: unitCharacterizationMap(coastal: true),
        cityRuleset: _customUnitRuleset(),
        technologyRuleset: _customUnitTechnologyRuleset(),
        paceBalance: PaceBalance.standard60,
      );

      expect(results.persistent.accepted, isTrue);
      expect(results.domain.accepted, isTrue);
      expect(results.persistent.reason, isNull);
      expect(results.domain.reason, isNull);
      expect(results.persistent.events, isEmpty);
      expect(results.persistent.state.cities, results.domain.state.cities);
      _expectPersistentAcceptedSharing(persistent, results.persistent.state);
      _expectDomainAcceptedSharing(domain, results.domain.state);
    });

    test('preserve complete state identity on rejection', () {
      final persistent = unitCharacterizationState(
        cities: unitCharacterizationCitiesWithTarget(
          unitCharacterizationCity(id: 'other_city'),
        ),
      );
      final domain = _domainFromPersistent(persistent);
      final results = _startAdapters(
        persistent: persistent,
        domain: domain,
        command: const StartUnitProductionCommand(
          'missing_city',
          GameUnitType.warrior,
        ),
        mapView: unitCharacterizationMap(),
      );

      expect(results.persistent.accepted, isFalse);
      expect(results.domain.accepted, isFalse);
      expect(results.persistent.reason, 'city_not_found');
      expect(results.domain.reason, 'city_not_found');
      expect(results.persistent.state, same(persistent));
      expect(results.domain.state, same(domain));
      expect(results.persistent.events, isEmpty);
    });
  });
}

CityProductionCommandResult _startKernel({
  required PersistentGameState state,
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
    resourceTradeAgreements: state.runtimeState.resourceTradeAgreements,
    mapView: mapView,
    command: command,
    actorPlayerId: actorPlayerId,
    cityRuleset: cityRuleset,
    technologyRuleset: technologyRuleset,
    paceBalance: paceBalance,
  );
}

void _expectKernelRejected({
  required PersistentGameState state,
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

({PersistentCityProductionResult persistent, DomainCityProductionResult domain})
_startAdapters({
  required PersistentGameState persistent,
  required DomainState domain,
  required StartUnitProductionCommand command,
  required MapReadView mapView,
  CityRuleset cityRuleset = CityRulesets.standard,
  TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  PaceBalance paceBalance = PaceBalance.unlimited,
}) {
  return (
    persistent: const PersistentCityProductionResolver().startUnitProduction(
      state: persistent,
      command: command,
      actorPlayerId: unitCharacterizationPlayerId,
      mapView: mapView,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    ),
    domain: const DomainCityProductionResolver().startUnitProduction(
      state: domain,
      command: command,
      actorPlayerId: unitCharacterizationPlayerId,
      mapView: mapView,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    ),
  );
}

DomainState _domainFromPersistent(PersistentGameState state) {
  return DomainState.snapshot(
    turn: 7,
    matchRules: MatchRules.standard,
    participants: const [
      Player(
        id: unitCharacterizationPlayerId,
        name: 'One',
        colorValue: 0xFF336699,
        country: PlayerCountry.poland,
      ),
      Player(
        id: unitCharacterizationOtherPlayerId,
        name: 'Two',
        colorValue: 0xFF993333,
        country: PlayerCountry.france,
      ),
    ],
    playerGold: state.playerGold,
    playerWarWeariness: state.playerWarWeariness,
    playerStabilityNet: state.playerStabilityNet,
    units: state.units,
    cities: state.cities,
    artifacts: state.artifacts,
    fieldImprovements: state.fieldImprovements,
    fogOfWar: state.fogOfWar,
    research: state.research,
    wonderRegistry: state.wonderRegistry,
    resourceTradeAgreements: state.runtimeState.resourceTradeAgreements,
  );
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

void _expectPersistentAcceptedSharing(
  PersistentGameState before,
  PersistentGameState after,
) {
  expect(after, isNot(same(before)));
  expect(after.cities, isNot(same(before.cities)));
  expect(after.cities.first, isNot(same(before.cities.first)));
  expect(after.cities.last, same(before.cities.last));
  expect(after.units, same(before.units));
  expect(after.artifacts, same(before.artifacts));
  expect(after.fieldImprovements, same(before.fieldImprovements));
  expect(after.research, same(before.research));
  expect(after.runtimeState, same(before.runtimeState));
}

void _expectDomainAcceptedSharing(DomainState before, DomainState after) {
  expect(after, isNot(same(before)));
  expect(after.cities, isNot(same(before.cities)));
  expect(after.cities.first, isNot(same(before.cities.first)));
  expect(after.cities.last, same(before.cities.last));
  expect(after.units, same(before.units));
  expect(after.artifacts, same(before.artifacts));
  expect(after.fieldImprovements, same(before.fieldImprovements));
  expect(after.research, same(before.research));
  expect(after.resourceTradeAgreements, same(before.resourceTradeAgreements));
}
