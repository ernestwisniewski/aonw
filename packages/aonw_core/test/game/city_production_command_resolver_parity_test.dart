import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'city_production_command_resolver_parity_test_support.dart';

void main() {
  group('city production persistent/domain adapter parity', () {
    test('fresh building has exact state-boundary parity', () {
      final research = _parityBuildingResearch();
      final states = _productionStates(
        primary: _parityProductionCity(productionOverflow: 21),
        research: research,
      );

      final results = _startBuildingBoth(states);

      _expectAcceptedProductionParity(states, results);
      expect(
        results.persistent.state.cities.first.productionQueue,
        CityProductionQueue.building(
          buildingType: CityBuildingType.workshop,
          investedProduction: 6,
        ),
      );
      expect(results.persistent.state.cities.first.productionOverflow, 0);
      expect(identical(results.persistent.state.research, research), isTrue);
      expect(identical(results.domain.state.research, research), isTrue);
    });

    test('active building queue preserves investment across adapters', () {
      final states = _productionStates(
        primary: _parityProductionCity(
          productionQueue: CityProductionQueue.project(
            projectType: CityProjectType.research,
            investedProduction: 7,
          ),
          productionOverflow: 13,
        ),
        research: _parityBuildingResearch(),
      );

      final results = _startBuildingBoth(states);

      _expectAcceptedProductionParity(states, results);
      expect(
        results.domain.state.cities.first.productionQueue,
        CityProductionQueue.building(
          buildingType: CityBuildingType.workshop,
          investedProduction: 7,
        ),
      );
      expect(results.domain.state.cities.first.productionOverflow, 13);
    });

    test('same building target creates fresh identities in both adapters', () {
      final primary = _parityProductionCity(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.workshop,
          investedProduction: 9,
        ),
        productionOverflow: 4,
      );
      final states = _productionStates(
        primary: primary,
        research: _parityBuildingResearch(),
      );

      final results = _startBuildingBoth(states);

      _expectAcceptedProductionParity(states, results);
      expect(
        results.persistent.state.cities.first.productionQueue,
        states.persistent.cities.first.productionQueue,
      );
      expect(
        identical(
          results.persistent.state.cities.first,
          states.persistent.cities.first,
        ),
        isFalse,
      );
      expect(
        identical(
          results.domain.state.cities.first,
          states.domain.cities.first,
        ),
        isFalse,
      );
      expect(
        identical(
          results.persistent.state.cities.first.productionQueue,
          states.persistent.cities.first.productionQueue,
        ),
        isFalse,
      );
    });

    test('building rejections preserve precedence and state identities', () {
      final missingStates = _productionStates(
        primary: _parityProductionCity(id: 'city_missing'),
      );
      _expectRejectedProductionParity(
        missingStates,
        _startBuildingBoth(missingStates, actorPlayerId: _otherPlayerId),
        reason: 'city_not_found',
      );

      final foreignStates = _productionStates(
        primary: _parityProductionCity(
          ownerPlayerId: _otherPlayerId,
          buildings: const {CityBuildingType.workshop},
        ),
        research: _parityBuildingResearch(),
      );
      _expectRejectedProductionParity(
        foreignStates,
        _startBuildingBoth(foreignStates),
        reason: 'city_not_controlled',
      );

      final unavailableStates = _productionStates(
        primary: _parityProductionCity(),
      );
      _expectRejectedProductionParity(
        unavailableStates,
        _startBuildingBoth(unavailableStates),
        reason: 'building_not_available',
      );
    });

    test('wonder forwards custom rules, map, and pace across adapters', () {
      final research = _parityWonderResearch();
      final wonderRegistry = WonderRegistry.empty.complete(
        type: WonderType.centralBank,
        playerId: _otherPlayerId,
      );
      final states = _productionStates(
        primary: _parityProductionCity(productionOverflow: 100),
        research: research,
        wonderRegistry: wonderRegistry,
      );

      final results = _startWonderBoth(
        states,
        mapTiles: _parityProductionMapTiles(hostTerrain: TerrainType.desert),
        wonderRuleset: _parityCustomWonderRuleset,
      );

      _expectAcceptedProductionParity(states, results);
      expect(
        results.persistent.state.cities.first.productionQueue,
        CityProductionQueue.wonder(
          wonderType: WonderType.greatLibrary,
          investedProduction: 8,
        ),
      );
      expect(results.persistent.state.cities.first.productionOverflow, 0);
      expect(identical(results.persistent.state.research, research), isTrue);
      expect(identical(results.domain.state.research, research), isTrue);
      expect(
        identical(results.persistent.state.wonderRegistry, wonderRegistry),
        isTrue,
      );
      expect(
        identical(results.domain.state.wonderRegistry, wonderRegistry),
        isTrue,
      );
    });

    test('wonder rejections preserve precedence and state identities', () {
      final completed = WonderRegistry.empty.complete(
        type: WonderType.greatLibrary,
        playerId: _otherPlayerId,
      );
      final missingStates = _productionStates(
        primary: _parityProductionCity(id: 'city_missing'),
        wonderRegistry: completed,
      );
      _expectRejectedProductionParity(
        missingStates,
        _startWonderBoth(missingStates, actorPlayerId: _otherPlayerId),
        reason: 'city_not_found',
      );

      final foreignStates = _productionStates(
        primary: _parityProductionCity(
          ownerPlayerId: _otherPlayerId,
          productionQueue: CityProductionQueue.wonder(
            wonderType: WonderType.greatLibrary,
            investedProduction: 11,
          ),
        ),
        research: ResearchState(
          players: {
            _otherPlayerId: PlayerResearchState(
              unlockedTechnologyIds: const {TechnologyId.writing},
            ),
          },
        ),
        wonderRegistry: completed,
      );
      _expectRejectedProductionParity(
        foreignStates,
        _startWonderBoth(foreignStates),
        reason: 'city_not_controlled',
      );

      final lockedStates = _productionStates(primary: _parityProductionCity());
      _expectRejectedProductionParity(
        lockedStates,
        _startWonderBoth(lockedStates),
        reason: 'wonder_not_available',
      );

      final missingRequirementStates = _productionStates(
        primary: _parityProductionCity(productionOverflow: 100),
        research: _parityWonderResearch(),
      );
      _expectRejectedProductionParity(
        missingRequirementStates,
        _startWonderBoth(
          missingRequirementStates,
          wonderRuleset: _parityCustomWonderRuleset,
        ),
        reason: 'wonder_not_available',
      );
    });

    test('fresh project has exact state-boundary parity', () {
      final states = _productionStates(
        primary: _parityProductionCity(productionOverflow: 21),
      );

      final results = _startBoth(states);

      _expectAcceptedProductionParity(states, results);
      expect(
        results.persistent.state.cities.first.productionQueue,
        CityProductionQueue.project(
          projectType: CityProjectType.research,
          investedProduction: 0,
        ),
      );
      expect(results.persistent.state.cities.first.productionOverflow, 0);
    });

    test('active queue preserves investment and overflow across adapters', () {
      final states = _productionStates(
        primary: _parityProductionCity(
          productionQueue: CityProductionQueue.building(
            buildingType: CityBuildingType.granary,
            investedProduction: 7,
          ),
          productionOverflow: 13,
        ),
      );

      final results = _startBoth(states);

      _expectAcceptedProductionParity(states, results);
      expect(
        results.domain.state.cities.first.productionQueue,
        CityProductionQueue.project(
          projectType: CityProjectType.research,
          investedProduction: 7,
        ),
      );
      expect(results.domain.state.cities.first.productionOverflow, 13);
    });

    test('same project preserves both complete state identities', () {
      final states = _productionStates(
        primary: _parityProductionCity(
          productionQueue: CityProductionQueue.project(
            projectType: CityProjectType.research,
            investedProduction: 9,
          ),
          productionOverflow: 4,
        ),
      );

      final results = _startBoth(states);

      expect(results.persistent.accepted, isTrue);
      expect(results.domain.accepted, isTrue);
      expect(identical(results.persistent.state, states.persistent), isTrue);
      expect(identical(results.domain.state, states.domain), isTrue);
    });

    test('rejections preserve precedence and complete state identities', () {
      final missingStates = _productionStates(
        primary: _parityProductionCity(id: 'city_missing'),
      );
      final missing = _startBoth(missingStates, actorPlayerId: _otherPlayerId);
      _expectRejectedProductionParity(
        missingStates,
        missing,
        reason: 'city_not_found',
      );

      final foreignStates = _productionStates(
        primary: _parityProductionCity(ownerPlayerId: _otherPlayerId),
      );
      final foreign = _startBoth(foreignStates);
      _expectRejectedProductionParity(
        foreignStates,
        foreign,
        reason: 'city_not_controlled',
      );
    });

    test('specialization has exact parity and preserves research identity', () {
      final research = _paritySpecializationResearch();
      final states = _productionStates(
        primary: _parityProductionCity(
          buildings: const {CityBuildingType.workshop},
        ),
        research: research,
      );

      final results = _specializeBoth(states);

      _expectAcceptedProductionParity(states, results);
      expect(
        results.persistent.state.cities.first.specialization,
        CitySpecializationType.industry,
      );
      expect(results.persistent.state.cities, results.domain.state.cities);
      expect(identical(results.persistent.state.research, research), isTrue);
      expect(identical(results.domain.state.research, research), isTrue);
      expect(states.persistent.cities.first.specialization, isNull);
      expect(states.domain.cities.first.specialization, isNull);
    });

    test('specialization rejections preserve full precedence and state', () {
      final unlocked = _paritySpecializationResearch();
      final missingStates = _productionStates(
        primary: _parityProductionCity(id: 'city_missing'),
        research: unlocked,
      );
      _expectRejectedProductionParity(
        missingStates,
        _specializeBoth(missingStates, actorPlayerId: _otherPlayerId),
        reason: 'city_not_found',
      );

      final foreignStates = _productionStates(
        primary: _parityProductionCity(
          ownerPlayerId: _otherPlayerId,
          specialization: CitySpecializationType.industry,
        ),
      );
      _expectRejectedProductionParity(
        foreignStates,
        _specializeBoth(foreignStates),
        reason: 'city_not_controlled',
      );

      final lockedStates = _productionStates(
        primary: _parityProductionCity(
          specialization: CitySpecializationType.industry,
        ),
      );
      _expectRejectedProductionParity(
        lockedStates,
        _specializeBoth(lockedStates),
        reason: 'city_specialization_locked',
      );

      final unchangedStates = _productionStates(
        primary: _parityProductionCity(
          specialization: CitySpecializationType.industry,
        ),
        research: unlocked,
      );
      _expectRejectedProductionParity(
        unchangedStates,
        _specializeBoth(unchangedStates),
        reason: 'city_specialization_unchanged',
      );

      final missingBuildingStates = _productionStates(
        primary: _parityProductionCity(),
        research: unlocked,
      );
      _expectRejectedProductionParity(
        missingBuildingStates,
        _specializeBoth(missingBuildingStates),
        reason: 'city_specialization_missing_building',
      );
    });
  });
}
