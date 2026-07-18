import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'city_production_command_resolver_test_support.dart';

void main() {
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
