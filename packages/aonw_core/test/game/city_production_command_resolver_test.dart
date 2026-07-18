import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'city_production_command_resolver_test_support.dart';

void main() {
  group('CityProductionCommandResolver.startBuilding', () {
    test('starts production in one city and owns the immutable output', () {
      final selected = _productionCity();
      final unrelated = _productionCity(
        id: 'city_2',
        ownerPlayerId: _otherPlayerId,
      );
      final cities = [selected, unrelated];

      final result = _startBuilding(cities: cities);

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(identical(result.cities, cities), isFalse);
      expect(identical(result.cities.first, selected), isFalse);
      expect(identical(result.cities.last, unrelated), isTrue);
      expect(
        result.cities.first.productionQueue,
        CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );
      expect(selected.productionQueue, isNull);
      expect(identical(cities.first, selected), isTrue);
      expect(() => result.cities.clear(), throwsUnsupportedError);
    });

    test('rolls capped stored overflow into a fresh queue', () {
      final result = _startBuilding(
        cities: [_productionCity(productionOverflow: 21)],
      );

      expect(result.accepted, isTrue);
      expect(
        result.cities.single.productionQueue,
        CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 3,
        ),
      );
      expect(result.cities.single.productionOverflow, 0);
    });

    test('preserves active investment and stored overflow', () {
      final result = _startBuilding(
        cities: [
          _productionCity(
            productionQueue: CityProductionQueue.project(
              projectType: CityProjectType.research,
              investedProduction: 7,
            ),
            productionOverflow: 13,
          ),
        ],
      );

      expect(result.accepted, isTrue);
      expect(
        result.cities.single.productionQueue,
        CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 7,
        ),
      );
      expect(result.cities.single.productionOverflow, 13);
    });

    test('same target is an accepted value no-op with fresh identities', () {
      final queue = CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 5,
      );
      final city = _productionCity(
        productionQueue: queue,
        productionOverflow: 6,
      );
      final cities = [city];

      final result = _startBuilding(cities: cities);

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(identical(result.cities, cities), isFalse);
      expect(identical(result.cities.single, city), isFalse);
      expect(result.cities.single.productionQueue, queue);
      expect(identical(result.cities.single.productionQueue, queue), isFalse);
      expect(result.cities.single.productionOverflow, 6);
    });

    test('preserves exact rejection precedence and input identity', () {
      _expectBuildingRejected(
        cities: const [],
        actorPlayerId: _otherPlayerId,
        reason: 'city_not_found',
      );
      _expectBuildingRejected(
        cities: [
          _productionCity(
            ownerPlayerId: _otherPlayerId,
            buildings: const {CityBuildingType.granary},
          ),
        ],
        reason: 'city_not_controlled',
      );
      _expectBuildingRejected(
        cities: [
          _productionCity(buildings: const {CityBuildingType.granary}),
        ],
        reason: 'building_not_available',
      );
    });

    test('requires the configured technology unlock', () {
      final locked = _startBuilding(
        cities: [_productionCity()],
        buildingType: CityBuildingType.workshop,
      );
      final unlocked = _startBuilding(
        cities: [_productionCity()],
        buildingType: CityBuildingType.workshop,
        research: _researchWith({TechnologyId.craftsmanship}),
      );

      expect(locked.accepted, isFalse);
      expect(locked.reason, 'building_not_available');
      expect(unlocked.accepted, isTrue);
    });

    test('evaluates map-backed resource requirements', () {
      final research = _researchWith({
        TechnologyId.machinery,
        TechnologyId.combustion,
      });
      final unavailable = _startBuilding(
        cities: [_productionCity()],
        buildingType: CityBuildingType.factory,
        research: research,
      );
      final available = _startBuilding(
        cities: [_productionCity()],
        buildingType: CityBuildingType.factory,
        research: research,
        mapTiles: _productionMapTiles(resource: ResourceType.oil),
      );

      expect(unavailable.accepted, isFalse);
      expect(unavailable.reason, 'building_not_available');
      expect(available.accepted, isTrue);
    });
  });

  group('CityProductionCommandResolver.startWonder', () {
    test('starts one immutable queue without mutating input identities', () {
      final activeQueue = CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 7,
      );
      final selected = _productionCity(
        productionQueue: activeQueue,
        productionOverflow: 13,
      );
      final unrelated = _productionCity(
        id: 'city_2',
        ownerPlayerId: _otherPlayerId,
      );
      final cities = [selected, unrelated];

      final result = _startWonder(cities: cities);

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(identical(result.cities, cities), isFalse);
      expect(identical(result.cities.first, selected), isFalse);
      expect(
        identical(result.cities.first.productionQueue, activeQueue),
        isFalse,
      );
      expect(identical(result.cities.last, unrelated), isTrue);
      expect(
        result.cities.first.productionQueue,
        CityProductionQueue.wonder(
          wonderType: WonderType.greatLibrary,
          investedProduction: 7,
        ),
      );
      expect(result.cities.first.productionOverflow, 13);
      expect(selected.productionQueue, same(activeQueue));
      expect(selected.productionOverflow, 13);
      expect(() => result.cities.clear(), throwsUnsupportedError);
    });

    test('forwards custom rules, map requirements, and pace-scaled cost', () {
      final unavailableCities = [_productionCity(productionOverflow: 100)];
      final unavailable = _startWonder(
        cities: unavailableCities,
        wonderRuleset: _customWonderRuleset,
      );

      expect(unavailable.accepted, isFalse);
      expect(unavailable.reason, 'wonder_not_available');
      expect(identical(unavailable.cities, unavailableCities), isTrue);

      final availableCities = [_productionCity(productionOverflow: 100)];
      final available = _startWonder(
        cities: availableCities,
        mapTiles: _productionMapTiles(hostTerrain: TerrainType.desert),
        wonderRuleset: _customWonderRuleset,
      );

      expect(available.accepted, isTrue);
      expect(
        available.cities.single.productionQueue,
        CityProductionQueue.wonder(
          wonderType: WonderType.greatLibrary,
          investedProduction: 8,
        ),
      );
      expect(available.cities.single.productionOverflow, 0);
    });

    test('preserves exact rejection precedence and input identity', () {
      final completed = WonderRegistry.empty.complete(
        type: WonderType.greatLibrary,
        playerId: _otherPlayerId,
      );
      _expectWonderRejected(
        cities: const [],
        actorPlayerId: _otherPlayerId,
        research: ResearchState.empty,
        wonderRegistry: completed,
        reason: 'city_not_found',
      );
      _expectWonderRejected(
        cities: [
          _productionCity(
            ownerPlayerId: _otherPlayerId,
            productionQueue: CityProductionQueue.wonder(
              wonderType: WonderType.greatLibrary,
              investedProduction: 11,
            ),
          ),
        ],
        research: ResearchState.empty,
        wonderRegistry: completed,
        reason: 'city_not_controlled',
      );
      _expectWonderRejected(
        cities: [_productionCity()],
        research: ResearchState.empty,
        reason: 'wonder_not_available',
      );
    });
  });

  group('CityProductionCommandResolver.startCityProject', () {
    test('starts a fresh immutable project without carrying overflow', () {
      final selected = _productionCity(productionOverflow: 21);
      final unrelated = _productionCity(
        id: 'city_2',
        ownerPlayerId: _otherPlayerId,
      );
      final cities = [selected, unrelated];

      final result = _startProject(cities: cities);

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(identical(result.cities, cities), isFalse);
      expect(identical(result.cities.last, unrelated), isTrue);
      expect(
        result.cities.first.productionQueue,
        CityProductionQueue.project(
          projectType: CityProjectType.research,
          investedProduction: 0,
        ),
      );
      expect(result.cities.first.productionOverflow, 0);
      expect(selected.productionQueue, isNull);
      expect(selected.productionOverflow, 21);
      expect(() => result.cities.clear(), throwsUnsupportedError);
    });

    test('preserves active investment and stored overflow', () {
      final cities = [
        _productionCity(
          productionQueue: CityProductionQueue.building(
            buildingType: CityBuildingType.granary,
            investedProduction: 7,
          ),
          productionOverflow: 13,
        ),
      ];

      final result = _startProject(cities: cities);

      expect(result.accepted, isTrue);
      expect(
        result.cities.single.productionQueue,
        CityProductionQueue.project(
          projectType: CityProjectType.research,
          investedProduction: 7,
        ),
      );
      expect(result.cities.single.productionOverflow, 13);
    });

    test('same project is an accepted semantic no-op', () {
      final city = _productionCity(
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.research,
          investedProduction: 9,
        ),
        productionOverflow: 4,
      );
      final cities = [city];

      final result = _startProject(cities: cities);

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(identical(result.cities, cities), isTrue);
      expect(identical(result.cities.single, city), isTrue);
    });

    test('preserves rejection precedence and input identity', () {
      final missing = <GameCity>[];
      _expectProjectRejected(
        cities: missing,
        actorPlayerId: _otherPlayerId,
        reason: 'city_not_found',
      );

      final foreign = [_productionCity(ownerPlayerId: _otherPlayerId)];
      _expectProjectRejected(cities: foreign, reason: 'city_not_controlled');
    });
  });

  group('CityProductionCommandResolver.setCitySpecialization', () {
    test('updates one city in an immutable list without mutating inputs', () {
      final selected = _productionCity(
        buildings: const {CityBuildingType.workshop},
      );
      final unrelated = _productionCity(
        id: 'city_2',
        ownerPlayerId: _otherPlayerId,
      );
      final cities = [selected, unrelated];

      final result = _setSpecialization(
        cities: cities,
        research: _specializationResearch(),
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(identical(result.cities, cities), isFalse);
      expect(
        result.cities.first.specialization,
        CitySpecializationType.industry,
      );
      expect(identical(result.cities.last, unrelated), isTrue);
      expect(selected.specialization, isNull);
      expect(identical(cities.first, selected), isTrue);
      expect(() => result.cities.clear(), throwsUnsupportedError);
    });

    test('preserves exact rejection precedence and input identity', () {
      _expectSpecializationRejected(
        cities: const [],
        research: _specializationResearch(),
        actorPlayerId: _otherPlayerId,
        reason: 'city_not_found',
      );
      _expectSpecializationRejected(
        cities: [
          _productionCity(
            ownerPlayerId: _otherPlayerId,
            specialization: CitySpecializationType.industry,
          ),
        ],
        research: ResearchState.empty,
        reason: 'city_not_controlled',
      );
      _expectSpecializationRejected(
        cities: [
          _productionCity(specialization: CitySpecializationType.industry),
        ],
        research: ResearchState.empty,
        reason: 'city_specialization_locked',
      );
      _expectSpecializationRejected(
        cities: [
          _productionCity(specialization: CitySpecializationType.industry),
        ],
        research: _specializationResearch(),
        reason: 'city_specialization_unchanged',
      );
      _expectSpecializationRejected(
        cities: [_productionCity()],
        research: _specializationResearch(),
        reason: 'city_specialization_missing_building',
      );
    });
  });
}
