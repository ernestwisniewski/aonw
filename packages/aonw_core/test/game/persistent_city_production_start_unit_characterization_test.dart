import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'persistent_city_production_start_unit_characterization_test_support.dart';

void main() {
  group('Persistent startUnitProduction rejection characterization', () {
    test('corpus covers the exact six rejection reasons', () {
      expect(const {
        'city_not_found',
        'city_not_controlled',
        'unit_production_not_available',
        'unit_production_requires_resource',
        'unit_production_requires_coast',
        'unit_supply_limit_reached',
      }, hasLength(6));
    });

    test('city-production-unit-not-found-rejected', () {
      final state = unitCharacterizationState(
        cities: unitCharacterizationCitiesWithTarget(
          unitCharacterizationCity(id: 'other_city'),
        ),
        units: unitCharacterizationWorkers(
          ownerPlayerId: unitCharacterizationPlayerId,
          count: 3,
        ),
      );
      const command = StartUnitProductionCommand(
        'missing_city',
        GameUnitType.warship,
      );
      final mapView = unitCharacterizationMap();

      final result = startUnitCharacterization(
        state,
        command: command,
        mapView: mapView,
        actorPlayerId: unitCharacterizationOtherPlayerId,
      );

      expectRejectedStartUnitIdentity(
        before: state,
        result: result,
        reason: 'city_not_found',
      );
    });

    test('city-production-unit-wrong-actor-available-rejected', () {
      final state = unitCharacterizationState(
        cities: unitCharacterizationCitiesWithTarget(
          unitCharacterizationCity(
            ownerPlayerId: unitCharacterizationOtherPlayerId,
          ),
        ),
      );
      const command = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );
      final mapView = unitCharacterizationMap();

      expect(
        unitCharacterizationRuleSnapshot(
          state: state,
          command: command,
          mapView: mapView,
        ),
        const (
          technologyUnlocked: true,
          requirementsMet: true,
          coastAvailable: true,
          supplyAvailable: true,
        ),
      );
      expect(
        startUnitCharacterization(
          state,
          command: command,
          mapView: mapView,
          actorPlayerId: unitCharacterizationOtherPlayerId,
        ).accepted,
        isTrue,
      );

      final result = startUnitCharacterization(
        state,
        command: command,
        mapView: mapView,
      );

      expectRejectedStartUnitIdentity(
        before: state,
        result: result,
        reason: 'city_not_controlled',
      );
    });

    test('city-production-unit-wrong-actor-compound-rejected', () {
      final state = unitCharacterizationState(
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
      const command = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warship,
      );
      final mapView = unitCharacterizationMap();

      expect(
        unitCharacterizationRuleSnapshot(
          state: state,
          command: command,
          mapView: mapView,
        ),
        const (
          technologyUnlocked: false,
          requirementsMet: false,
          coastAvailable: false,
          supplyAvailable: false,
        ),
      );
      expect(
        startUnitCharacterization(
          state,
          command: command,
          mapView: mapView,
          actorPlayerId: unitCharacterizationOtherPlayerId,
        ).reason,
        'unit_production_not_available',
      );

      final result = startUnitCharacterization(
        state,
        command: command,
        mapView: mapView,
      );

      expectRejectedStartUnitIdentity(
        before: state,
        result: result,
        reason: 'city_not_controlled',
      );
    });

    test('city-production-unit-technology-locked-rejected', () {
      final state = unitCharacterizationState(
        cities: unitCharacterizationCitiesWithTarget(
          unitCharacterizationCity(),
        ),
      );
      const command = StartUnitProductionCommand('city_1', GameUnitType.archer);
      final mapView = unitCharacterizationMap();

      expect(
        unitCharacterizationRuleSnapshot(
          state: state,
          command: command,
          mapView: mapView,
        ),
        const (
          technologyUnlocked: false,
          requirementsMet: true,
          coastAvailable: true,
          supplyAvailable: true,
        ),
      );

      final result = startUnitCharacterization(
        state,
        command: command,
        mapView: mapView,
      );

      expectRejectedStartUnitIdentity(
        before: state,
        result: result,
        reason: 'unit_production_not_available',
      );
    });

    test('city-production-unit-resource-missing-rejected', () {
      final state = unitCharacterizationState(
        cities: unitCharacterizationCitiesWithTarget(
          unitCharacterizationCity(),
        ),
        research: unitCharacterizationResearch({TechnologyId.horsebackRiding}),
      );
      const command = StartUnitProductionCommand(
        'city_1',
        GameUnitType.cavalry,
      );
      final mapView = unitCharacterizationMap();

      expect(
        unitCharacterizationRuleSnapshot(
          state: state,
          command: command,
          mapView: mapView,
        ),
        const (
          technologyUnlocked: true,
          requirementsMet: false,
          coastAvailable: true,
          supplyAvailable: true,
        ),
      );

      final result = startUnitCharacterization(
        state,
        command: command,
        mapView: mapView,
      );

      expectRejectedStartUnitIdentity(
        before: state,
        result: result,
        reason: 'unit_production_requires_resource',
      );
    });

    test('city-production-unit-coast-missing-rejected', () {
      final state = unitCharacterizationState(
        cities: unitCharacterizationCitiesWithTarget(
          unitCharacterizationCity(),
        ),
        research: unitCharacterizationResearch({TechnologyId.cartography}),
      );
      const command = StartUnitProductionCommand(
        'city_1',
        GameUnitType.scoutShip,
      );
      final mapView = unitCharacterizationMap();

      expect(
        unitCharacterizationRuleSnapshot(
          state: state,
          command: command,
          mapView: mapView,
        ),
        const (
          technologyUnlocked: true,
          requirementsMet: true,
          coastAvailable: false,
          supplyAvailable: true,
        ),
      );

      final result = startUnitCharacterization(
        state,
        command: command,
        mapView: mapView,
      );

      expectRejectedStartUnitIdentity(
        before: state,
        result: result,
        reason: 'unit_production_requires_coast',
      );
    });

    test('city-production-unit-supply-full-rejected', () {
      final state = unitCharacterizationState(
        cities: unitCharacterizationCitiesWithTarget(
          unitCharacterizationCity(),
        ),
        units: unitCharacterizationWorkers(
          ownerPlayerId: unitCharacterizationPlayerId,
          count: 3,
        ),
      );
      const command = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );
      final mapView = unitCharacterizationMap();

      expect(
        unitCharacterizationRuleSnapshot(
          state: state,
          command: command,
          mapView: mapView,
        ),
        const (
          technologyUnlocked: true,
          requirementsMet: true,
          coastAvailable: true,
          supplyAvailable: false,
        ),
      );

      final result = startUnitCharacterization(
        state,
        command: command,
        mapView: mapView,
      );

      expectRejectedStartUnitIdentity(
        before: state,
        result: result,
        reason: 'unit_supply_limit_reached',
      );
    });
  });

  group('Persistent startUnitProduction acceptance characterization', () {
    test('city-production-unit-overflow-standard60-accepted', () {
      final state = unitCharacterizationState(
        cities: unitCharacterizationCitiesWithTarget(
          unitCharacterizationCity(productionOverflow: 40),
        ),
      );
      const command = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );
      final mapView = unitCharacterizationMap();
      final productionCost = CityProductionRules.unitProductionCost(
        command.unitType,
        paceBalance: PaceBalance.standard60,
      );
      expect(productionCost, 12);

      final result = startUnitCharacterization(
        state,
        command: command,
        mapView: mapView,
        paceBalance: PaceBalance.standard60,
      );

      final identities = expectAcceptedStartUnitOnlyCitiesChanged(
        before: state,
        result: result,
        cityId: command.cityId,
      );
      expect(identities.beforeCity.productionQueue, isNull);
      expect(identities.beforeCity.productionOverflow, 40);
      expect(
        identities.afterCity.productionQueue,
        CityProductionQueue.unit(
          unitType: command.unitType,
          investedProduction: productionCost ~/ 2,
        ),
      );
      expect(identities.afterCity.productionOverflow, 0);
    });

    test('city-production-unit-import-coast-replacement-accepted', () {
      final activeQueue = CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 17,
      );
      final import = unitCharacterizationIronImport();
      final state = unitCharacterizationState(
        cities: unitCharacterizationCitiesWithTarget(
          unitCharacterizationCity(
            productionQueue: activeQueue,
            productionOverflow: 9,
          ),
        ),
        research: unitCharacterizationResearch({TechnologyId.navalDoctrine}),
        resourceTradeAgreements: [import],
      );
      const command = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warship,
      );
      final mapView = unitCharacterizationMap(coastal: true);

      expect(
        unitCharacterizationRuleSnapshot(
          state: state,
          command: command,
          mapView: mapView,
        ),
        const (
          technologyUnlocked: true,
          requirementsMet: true,
          coastAvailable: true,
          supplyAvailable: true,
        ),
      );
      expect(
        UnitProductionRequirementRules.meetsRequirements(
          playerId: unitCharacterizationPlayerId,
          unitType: command.unitType,
          cities: state.cities,
          mapTiles: mapView.mapTiles,
          research: state.research,
        ),
        isFalse,
      );
      expect(
        CityUnitProductionRules.canProduceInCity(
          city: state.cities.first,
          unitType: command.unitType,
          mapTiles: unitCharacterizationMap().mapTiles,
        ),
        isFalse,
      );

      final result = startUnitCharacterization(
        state,
        command: command,
        mapView: mapView,
      );

      final identities = expectAcceptedStartUnitOnlyCitiesChanged(
        before: state,
        result: result,
        cityId: command.cityId,
      );
      expect(identities.beforeCity.productionQueue, same(activeQueue));
      expect(
        identities.afterCity.productionQueue,
        isNot(same(identities.beforeCity.productionQueue)),
      );
      expect(
        identities.afterCity.productionQueue,
        CityProductionQueue.unit(
          unitType: command.unitType,
          investedProduction: 17,
        ),
      );
      expect(identities.afterCity.productionOverflow, 9);
      expect(
        result.state.runtimeState.resourceTradeAgreements.single,
        same(import),
      );
    });

    test('city-production-unit-same-target-accepted', () {
      final activeQueue = CityProductionQueue.unit(
        unitType: GameUnitType.warrior,
        investedProduction: 7,
      );
      final state = unitCharacterizationState(
        cities: unitCharacterizationCitiesWithTarget(
          unitCharacterizationCity(
            productionQueue: activeQueue,
            productionOverflow: 4,
          ),
        ),
      );
      const command = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );
      final mapView = unitCharacterizationMap();

      final result = startUnitCharacterization(
        state,
        command: command,
        mapView: mapView,
      );

      final identities = expectAcceptedStartUnitOnlyCitiesChanged(
        before: state,
        result: result,
        cityId: command.cityId,
      );
      expect(identities.beforeCity.productionQueue, same(activeQueue));
      expect(
        identities.afterCity.productionQueue,
        equals(identities.beforeCity.productionQueue),
      );
      expect(
        identities.afterCity.productionQueue,
        isNot(same(identities.beforeCity.productionQueue)),
      );
      expect(identities.afterCity.productionOverflow, 4);
    });

    registerStartUnitArtifactFarmSupplyCharacterization();
  });
}
