import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentCityProductionResolver', () {
    test('starts building production for controlled city', () {
      final state = PersistentGameState(cities: [_city()]);

      final result = const PersistentCityProductionResolver().startBuilding(
        state: state,
        command: const StartBuildingCommand('city_1', CityBuildingType.granary),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );

      expect(result.accepted, isTrue);
      expect(
        result.state.cities.single.productionQueue,
        CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );
    });

    test('rejects locked building production', () {
      final state = PersistentGameState(cities: [_city()]);

      final result = const PersistentCityProductionResolver().startBuilding(
        state: state,
        command: const StartBuildingCommand(
          'city_1',
          CityBuildingType.workshop,
        ),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'building_not_available');
      expect(result.state, state);
    });

    test('starts unlocked building production', () {
      final state = PersistentGameState(
        cities: [_city()],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.craftsmanship},
            ),
          },
        ),
      );

      final result = const PersistentCityProductionResolver().startBuilding(
        state: state,
        command: const StartBuildingCommand(
          'city_1',
          CityBuildingType.workshop,
        ),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );

      expect(result.accepted, isTrue);
      expect(
        result.state.cities.single.productionQueue?.target,
        const BuildingProductionTarget(CityBuildingType.workshop),
      );
    });

    test(
      'rejects resource building when controlled resource is not revealed',
      () {
        final state = PersistentGameState(
          cities: [_city()],
          research: _researchWith(TechnologyId.machinery),
        );

        final result = const PersistentCityProductionResolver().startBuilding(
          state: state,
          command: const StartBuildingCommand(
            'city_1',
            CityBuildingType.factory,
          ),
          actorPlayerId: 'player_1',
          mapDefinition: _resourceMapDefinition(ResourceType.oil),
        );

        expect(result.accepted, isFalse);
        expect(result.reason, 'building_not_available');
        expect(result.state, state);
      },
    );

    test('starts resource building after reveal research', () {
      final state = PersistentGameState(
        cities: [_city()],
        research: _researchWithAll({
          TechnologyId.machinery,
          TechnologyId.combustion,
        }),
      );

      final result = const PersistentCityProductionResolver().startBuilding(
        state: state,
        command: const StartBuildingCommand('city_1', CityBuildingType.factory),
        actorPlayerId: 'player_1',
        mapDefinition: _resourceMapDefinition(ResourceType.oil),
      );

      expect(result.accepted, isTrue);
      expect(
        result.state.cities.single.productionQueue?.target,
        const BuildingProductionTarget(CityBuildingType.factory),
      );
    });

    test('starts unit production for controlled city', () {
      final state = PersistentGameState(cities: [_city()]);

      final result = const PersistentCityProductionResolver()
          .startUnitProduction(
            state: state,
            command: const StartUnitProductionCommand(
              'city_1',
              GameUnitType.warrior,
            ),
            actorPlayerId: 'player_1',
            mapDefinition: _mapDefinition(),
          );

      expect(result.accepted, isTrue);
      expect(
        result.state.cities.single.productionQueue,
        CityProductionQueue.unit(
          unitType: GameUnitType.warrior,
          investedProduction: 0,
        ),
      );
    });

    test('starts merchant production only after trade is researched', () {
      final lockedState = PersistentGameState(cities: [_city()]);
      final unlockedState = PersistentGameState(
        cities: [_city()],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.trade},
            ),
          },
        ),
      );
      const command = StartUnitProductionCommand(
        'city_1',
        GameUnitType.merchant,
      );

      final lockedResult = const PersistentCityProductionResolver()
          .startUnitProduction(
            state: lockedState,
            command: command,
            actorPlayerId: 'player_1',
            mapDefinition: _mapDefinition(),
          );
      final unlockedResult = const PersistentCityProductionResolver()
          .startUnitProduction(
            state: unlockedState,
            command: command,
            actorPlayerId: 'player_1',
            mapDefinition: _mapDefinition(),
          );

      expect(lockedResult.accepted, isFalse);
      expect(lockedResult.reason, 'unit_production_not_available');
      expect(
        unlockedResult.state.cities.single.productionQueue?.target,
        const UnitProductionTarget(GameUnitType.merchant),
      );
    });

    test('rejects resource-gated unit production without resource', () {
      final state = PersistentGameState(
        cities: [_city()],
        research: _researchWith(TechnologyId.horsebackRiding),
      );

      final result = const PersistentCityProductionResolver()
          .startUnitProduction(
            state: state,
            command: const StartUnitProductionCommand(
              'city_1',
              GameUnitType.cavalry,
            ),
            actorPlayerId: 'player_1',
            mapDefinition: _mapDefinition(),
          );

      expect(result.accepted, isFalse);
      expect(result.reason, 'unit_production_requires_resource');
      expect(result.state, state);
    });

    test('starts resource-gated unit production with controlled resource', () {
      final state = PersistentGameState(
        cities: [_city()],
        research: _researchWithAll({
          TechnologyId.animalHusbandry,
          TechnologyId.horsebackRiding,
        }),
      );

      final result = const PersistentCityProductionResolver()
          .startUnitProduction(
            state: state,
            command: const StartUnitProductionCommand(
              'city_1',
              GameUnitType.cavalry,
            ),
            actorPlayerId: 'player_1',
            mapDefinition: _resourceMapDefinition(ResourceType.horses),
          );

      expect(result.accepted, isTrue);
      expect(
        result.state.cities.single.productionQueue,
        CityProductionQueue.unit(
          unitType: GameUnitType.cavalry,
          investedProduction: 0,
        ),
      );
    });

    test('starts resource-gated unit production with imported resource', () {
      final state = PersistentGameState(
        cities: [_city()],
        research: _researchWith(TechnologyId.horsebackRiding),
        runtimeState: const GameRuntimeState(
          resourceTradeAgreements: [
            ResourceTradeAgreement(
              id: 'trade_1',
              exporterPlayerId: 'player_2',
              importerPlayerId: 'player_1',
              resource: ResourceType.horses,
              goldPerTurn: 3,
              remainingTurns: 8,
            ),
          ],
        ),
      );

      final result = const PersistentCityProductionResolver()
          .startUnitProduction(
            state: state,
            command: const StartUnitProductionCommand(
              'city_1',
              GameUnitType.cavalry,
            ),
            actorPlayerId: 'player_1',
            mapDefinition: _mapDefinition(),
          );

      expect(result.accepted, isTrue);
      expect(
        result.state.cities.single.productionQueue,
        CityProductionQueue.unit(
          unitType: GameUnitType.cavalry,
          investedProduction: 0,
        ),
      );
    });

    test('rejects tank production without revealed oil', () {
      final state = PersistentGameState(
        cities: [_city()],
        research: _researchWithAll({
          TechnologyId.combustion,
          TechnologyId.massProduction,
        }),
      );

      final result = const PersistentCityProductionResolver()
          .startUnitProduction(
            state: state,
            command: const StartUnitProductionCommand(
              'city_1',
              GameUnitType.tank,
            ),
            actorPlayerId: 'player_1',
            mapDefinition: _mapDefinition(),
          );

      expect(result.accepted, isFalse);
      expect(result.reason, 'unit_production_requires_resource');
      expect(result.state, state);
    });

    test('starts tank production with revealed oil', () {
      final state = PersistentGameState(
        cities: [_city()],
        research: _researchWithAll({
          TechnologyId.combustion,
          TechnologyId.massProduction,
        }),
      );

      final result = const PersistentCityProductionResolver()
          .startUnitProduction(
            state: state,
            command: const StartUnitProductionCommand(
              'city_1',
              GameUnitType.tank,
            ),
            actorPlayerId: 'player_1',
            mapDefinition: _resourceMapDefinition(ResourceType.oil),
          );

      expect(result.accepted, isTrue);
      expect(
        result.state.cities.single.productionQueue,
        CityProductionQueue.unit(
          unitType: GameUnitType.tank,
          investedProduction: 0,
        ),
      );
    });

    test('rejects naval unit production without coast spawn hex', () {
      final state = PersistentGameState(
        cities: [_city()],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.cartography},
            ),
          },
        ),
      );

      final result = const PersistentCityProductionResolver()
          .startUnitProduction(
            state: state,
            command: const StartUnitProductionCommand(
              'city_1',
              GameUnitType.scoutShip,
            ),
            actorPlayerId: 'player_1',
            mapDefinition: _mapDefinition(),
          );

      expect(result.accepted, isFalse);
      expect(result.reason, 'unit_production_requires_coast');
      expect(result.state, state);
    });

    test(
      'starts naval unit production with ocean-adjacent coast spawn hex',
      () {
        final state = PersistentGameState(
          cities: [_city()],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                unlockedTechnologyIds: {TechnologyId.cartography},
              ),
            },
          ),
        );

        final result = const PersistentCityProductionResolver()
            .startUnitProduction(
              state: state,
              command: const StartUnitProductionCommand(
                'city_1',
                GameUnitType.scoutShip,
              ),
              actorPlayerId: 'player_1',
              mapDefinition: _coastalMapDefinition(),
            );

        expect(result.accepted, isTrue);
        expect(
          result.state.cities.single.productionQueue,
          CityProductionQueue.unit(
            unitType: GameUnitType.scoutShip,
            investedProduction: 0,
          ),
        );
      },
    );

    test('rejects unit production when food supply is full', () {
      final state = PersistentGameState(
        cities: [_city()],
        units: [
          for (var i = 0; i < 3; i++)
            GameUnit.produced(
              id: 'worker_$i',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              col: i,
              row: 0,
            ),
        ],
      );

      final result = const PersistentCityProductionResolver()
          .startUnitProduction(
            state: state,
            command: const StartUnitProductionCommand(
              'city_1',
              GameUnitType.warrior,
            ),
            actorPlayerId: 'player_1',
            mapDefinition: _mapDefinition(),
          );

      expect(result.accepted, isFalse);
      expect(result.reason, 'unit_supply_limit_reached');
      expect(result.state, state);
    });

    test('allows settlers after two early defenders fit supply', () {
      final state = PersistentGameState(
        cities: [_city()],
        units: [
          for (var i = 0; i < 2; i++)
            GameUnit.produced(
              id: 'warrior_$i',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: i,
              row: 0,
            ),
        ],
      );

      final result = const PersistentCityProductionResolver()
          .startUnitProduction(
            state: state,
            command: const StartUnitProductionCommand(
              'city_1',
              GameUnitType.settler,
            ),
            actorPlayerId: 'player_1',
            mapDefinition: _mapDefinition(),
          );

      expect(result.accepted, isTrue);
      expect(
        result.state.cities.single.productionQueue,
        CityProductionQueue.unit(
          unitType: GameUnitType.settler,
          investedProduction: 0,
        ),
      );
    });

    test('starts city project for controlled city', () {
      final state = PersistentGameState(cities: [_city()]);

      final result = const PersistentCityProductionResolver().startCityProject(
        state: state,
        command: const StartCityProjectCommand(
          'city_1',
          CityProjectType.research,
        ),
        actorPlayerId: 'player_1',
      );

      expect(result.accepted, isTrue);
      expect(
        result.state.cities.single.productionQueue,
        CityProductionQueue.project(projectType: CityProjectType.research),
      );
    });

    test('sets city specialization after specialization technology', () {
      final state = PersistentGameState(
        cities: [
          _city(buildings: {CityBuildingType.workshop}),
        ],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.specialization},
            ),
          },
        ),
      );

      final result = const PersistentCityProductionResolver()
          .setCitySpecialization(
            state: state,
            command: const SetCitySpecializationCommand(
              'city_1',
              CitySpecializationType.industry,
            ),
            actorPlayerId: 'player_1',
          );

      expect(result.accepted, isTrue);
      expect(
        result.state.cities.single.specialization,
        CitySpecializationType.industry,
      );
    });

    test('rejects city specialization without required building', () {
      final state = PersistentGameState(
        cities: [_city()],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.specialization},
            ),
          },
        ),
      );

      final result = const PersistentCityProductionResolver()
          .setCitySpecialization(
            state: state,
            command: const SetCitySpecializationCommand(
              'city_1',
              CitySpecializationType.industry,
            ),
            actorPlayerId: 'player_1',
          );

      expect(result.accepted, isFalse);
      expect(result.reason, 'city_specialization_missing_building');
      expect(result.state, state);
    });

    test('rejects city specialization before technology unlock', () {
      final state = PersistentGameState(cities: [_city()]);

      final result = const PersistentCityProductionResolver()
          .setCitySpecialization(
            state: state,
            command: const SetCitySpecializationCommand(
              'city_1',
              CitySpecializationType.industry,
            ),
            actorPlayerId: 'player_1',
          );

      expect(result.accepted, isFalse);
      expect(result.reason, 'city_specialization_locked');
      expect(result.state, state);
    });

    test('rejects production for another player city', () {
      final state = PersistentGameState(
        cities: [_city(ownerPlayerId: 'player_2')],
      );

      final result = const PersistentCityProductionResolver()
          .startUnitProduction(
            state: state,
            command: const StartUnitProductionCommand(
              'city_1',
              GameUnitType.warrior,
            ),
            actorPlayerId: 'player_1',
            mapDefinition: _mapDefinition(),
          );

      expect(result.accepted, isFalse);
      expect(result.reason, 'city_not_controlled');
    });

    test('rushes building production and emits event', () {
      final granaryCost = CityProductionRules.targetCost(
        const BuildingProductionTarget(CityBuildingType.granary),
      );
      final city = _city().copyWith(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: granaryCost - 1,
        ),
      );
      final state = PersistentGameState(
        cities: [city],
        playerGold: const {'player_1': 2},
      );

      final result = const PersistentCityProductionResolver().rushProduction(
        state: state,
        command: const RushProductionCommand('city_1'),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );

      final updatedCity = result.state.cities.single;
      expect(result.accepted, isTrue);
      expect(updatedCity.buildings, contains(CityBuildingType.granary));
      expect(updatedCity.productionQueue, isNull);
      expect(result.state.playerGold['player_1'], 0);
      expect(result.events.single, isA<CityBuiltBuildingEvent>());
    });

    test('rejects rush production for continuous city projects', () {
      final city = _city().copyWith(
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.wealth,
        ),
      );
      final state = PersistentGameState(
        cities: [city],
        playerGold: const {'player_1': 10},
      );

      final result = const PersistentCityProductionResolver().rushProduction(
        state: state,
        command: const RushProductionCommand('city_1'),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'project_cannot_be_rushed');
      expect(result.state, state);
    });
  });
}

GameCity _city({
  String ownerPlayerId = 'player_1',
  Set<CityBuildingType> buildings = const {},
}) {
  return GameCity(
    id: 'city_1',
    ownerPlayerId: ownerPlayerId,
    name: 'City',
    center: const CityHex(col: 1, row: 1),
    buildings: buildings,
  );
}

ResearchState _researchWith(TechnologyId technologyId) {
  return _researchWithAll({technologyId});
}

ResearchState _researchWithAll(Set<TechnologyId> technologyIds) {
  return ResearchState(
    players: {
      'player_1': PlayerResearchState(unlockedTechnologyIds: technologyIds),
    },
  );
}

MapDefinition _mapDefinition() {
  return MapDefinition(
    cols: 7,
    rows: 7,
    tiles: [
      for (var row = 0; row < 7; row++)
        for (var col = 0; col < 7; col++)
          MapTileDefinition(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

MapDefinition _resourceMapDefinition(ResourceType resource) {
  return MapDefinition(
    cols: 7,
    rows: 7,
    tiles: [
      for (var row = 0; row < 7; row++)
        for (var col = 0; col < 7; col++)
          MapTileDefinition(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: col == 1 && row == 1 ? [resource] : const [],
            height: 0,
          ),
    ],
  );
}

MapDefinition _coastalMapDefinition() {
  return MapDefinition(
    cols: 7,
    rows: 7,
    tiles: [
      for (var row = 0; row < 7; row++)
        for (var col = 0; col < 7; col++)
          MapTileDefinition(
            col: col,
            row: row,
            terrains: col == 2 && row == 1
                ? const [TerrainType.coast]
                : col == 3 && row == 1
                ? const [TerrainType.ocean]
                : const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
