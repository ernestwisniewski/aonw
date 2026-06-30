import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentTurnEconomyProcessor', () {
    test(
      'runs city, research, worker, and fog phases for submitted players',
      () {
        final worker = GameUnit(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          name: 'Worker',
          col: 1,
          row: 0,
          workerJob: const WorkerJob(
            targetHex: CityHex(col: 1, row: 0),
            improvementType: FieldImprovementType.farm,
            remainingTurns: 1,
            totalTurns: 1,
          ),
        );
        final producingCity = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City 1',
          center: const CityHex(col: 0, row: 0),
          controlledHexes: const [CityHex(col: 1, row: 0)],
          productionQueue: CityProductionQueue.unit(
            unitType: GameUnitType.warrior,
            investedProduction:
                CityProductionRules.unitProductionCost(GameUnitType.warrior) -
                1,
          ),
        );
        const researchCity = GameCity(
          id: 'city_2',
          ownerPlayerId: 'player_2',
          name: 'City 2',
          center: CityHex(col: 2, row: 2),
        );
        final state = PersistentGameState(
          units: [worker],
          cities: [producingCity, researchCity],
          research: ResearchState(
            players: {
              'player_2': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
                progressByTechnologyId: const {TechnologyId.agriculture: 4},
              ),
            },
          ),
        );

        final result = PersistentTurnEconomyProcessor.advanceForPlayers(
          state: state,
          playerIds: const ['player_2', 'player_1', 'player_1'],
          mapData: _mapData(),
        );

        expect(result.state.cities.first.productionQueue, isNull);
        expect(
          result.state.units.map((unit) => unit.type),
          contains(GameUnitType.warrior),
        );
        expect(
          result.state.units.any((unit) => unit.id == 'worker_1'),
          isFalse,
        );
        expect(
          result.state.fieldImprovements.single.type,
          FieldImprovementType.farm,
        );
        expect(
          result.state.research
              .forPlayer('player_2')
              .hasUnlocked(TechnologyId.agriculture),
          isTrue,
        );
        expect(
          result.state.fogOfWar.isVisible(
            'player_1',
            const HexCoordinate(col: 0, row: 0),
          ),
          isTrue,
        );
        expect(result.events.map((event) => event.runtimeType), [
          CityProducedUnitEvent,
          ResearchPointsGainedEvent,
          WorkerCompletedJobEvent,
          ResearchPointsGainedEvent,
          TechnologyResearchedEvent,
        ]);
      },
    );

    test('subtracts unit upkeep from city gold income', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City 1',
        center: CityHex(col: 1, row: 1),
        buildings: {CityBuildingType.merchantHall},
      );
      final units = [
        GameUnit(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          name: GameUnitType.settler.defaultNameToken,
          col: 0,
          row: 0,
        ),
        GameUnit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: GameUnitType.warrior.defaultNameToken,
          col: 0,
          row: 1,
        ),
        GameUnit(
          id: 'archer_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.archer,
          name: GameUnitType.archer.defaultNameToken,
          col: 0,
          row: 2,
        ),
        GameUnit(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          name: GameUnitType.worker.defaultNameToken,
          col: 1,
          row: 0,
        ),
        GameUnit(
          id: 'worker_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          name: GameUnitType.worker.defaultNameToken,
          col: 2,
          row: 0,
        ),
      ];
      final state = PersistentGameState(
        units: units,
        cities: const [city],
        playerGold: const {'player_1': 3},
      );

      final result = PersistentTurnEconomyProcessor.advanceForPlayers(
        state: state,
        playerIds: const ['player_1'],
        mapData: _mapData(),
      );

      expect(result.state.playerGold['player_1'], 4);
    });

    test('slowly regenerates damaged city HP for submitted players', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City 1',
        center: CityHex(col: 1, row: 1),
        hitPoints: 10,
      );

      final result = PersistentTurnEconomyProcessor.advanceForPlayers(
        state: const PersistentGameState(cities: [city]),
        playerIds: const ['player_1'],
        mapData: _mapData(),
      );

      expect(result.state.cities.single.hitPoints, 11);
    });

    test('does not regenerate a city attacked before economy processing', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City 1',
        center: CityHex(col: 1, row: 1),
        hitPoints: 10,
      );

      final result = PersistentTurnEconomyProcessor.advanceForPlayers(
        state: const PersistentGameState(cities: [city]),
        playerIds: const ['player_1'],
        mapData: _mapData(),
        priorEvents: [
          CombatResolvedEvent(
            attackerUnitId: 'attacker_1',
            defenderUnitId: 'city_1',
            outcome: CombatOutcome(
              attackerUnitId: 'attacker_1',
              defenderUnitId: 'city_1',
              attackerHpAfter: 10,
              defenderHpAfter: 10,
              attackerKilled: false,
              defenderKilled: false,
            ),
          ),
        ],
      );

      expect(result.state.cities.single.hitPoints, 10);
    });

    test('adds research project science to active research progress', () {
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City 1',
        center: const CityHex(col: 1, row: 1),
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.research,
        ),
      );
      final state = PersistentGameState(
        cities: [city],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );

      final result = PersistentTurnEconomyProcessor.advanceForPlayers(
        state: state,
        playerIds: const ['player_1'],
        mapData: _mapData(),
      );

      expect(result.scienceGained.total, 1);
      expect(
        result.state.research
            .forPlayer('player_1')
            .progressFor(TechnologyId.agriculture),
        3,
      );
      expect(
        result.state.cities.single.productionQueue,
        CityProductionQueue.project(projectType: CityProjectType.research),
      );
    });

    test('advances artifact excavation jobs for submitted players', () {
      final unit = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        name: GameUnitType.scout.defaultNameToken,
        col: 1,
        row: 1,
        excavatingArtifactId: 'artifact_1',
      );
      const artifact = WorldArtifact(
        id: 'artifact_1',
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.excavation(
          unitId: 'scout_1',
          col: 1,
          row: 1,
          remainingTurns: 1,
        ),
      );

      final result = PersistentTurnEconomyProcessor.advanceForPlayers(
        state: PersistentGameState(units: [unit], artifacts: const [artifact]),
        playerIds: const ['player_1'],
        mapData: _mapData(),
      );

      expect(result.state.units.single.excavatingArtifactId, isNull);
      expect(result.state.units.single.carriedArtifactId, 'artifact_1');
      expect(result.state.artifacts.single.location.isCarried, isTrue);
    });

    test('advances map objective holds after economy phases', () {
      const objective = MapObjectiveDefinition(
        id: 'pass_1',
        type: MapObjectiveType.strategicPass,
        hex: CityHex(col: 1, row: 0),
        requiredHoldTurns: 2,
        victoryPoints: 3,
        goldPerTurn: 4,
      );
      final state = PersistentGameState(
        playerGold: const {'player_1': 10},
        units: [
          GameUnit.startingWarrior(ownerPlayerId: 'player_1', col: 1, row: 0),
        ],
        runtimeState: const GameRuntimeState(
          mapObjectiveHoldStatesByObjectiveId: {
            'pass_1': MapObjectiveHoldState(
              objectiveId: 'pass_1',
              playerId: 'player_1',
              holdTurns: 1,
            ),
          },
        ),
      );

      final result = PersistentTurnEconomyProcessor.advanceForPlayers(
        state: state,
        playerIds: const ['player_1'],
        mapData: _mapData(),
        mapObjectives: const [objective],
      );

      final hold = result
          .state
          .runtimeState
          .mapObjectiveHoldStatesByObjectiveId['pass_1'];
      expect(hold, isNotNull);
      expect(hold!.playerId, 'player_1');
      expect(hold.holdTurns, 2);
      expect(result.state.playerGold['player_1'], 14);
      expect(
        result.events,
        contains(
          isA<MapObjectiveSecuredEvent>()
              .having((event) => event.playerId, 'playerId', 'player_1')
              .having((event) => event.objectiveId, 'objectiveId', 'pass_1')
              .having((event) => event.holdTurns, 'holdTurns', 2)
              .having((event) => event.victoryPoints, 'victoryPoints', 3)
              .having((event) => event.goldPerTurn, 'goldPerTurn', 4),
        ),
      );
    });

    test('does not repeat secured map objective events after completion', () {
      const objective = MapObjectiveDefinition(
        id: 'pass_1',
        type: MapObjectiveType.strategicPass,
        hex: CityHex(col: 1, row: 0),
        requiredHoldTurns: 2,
        victoryPoints: 3,
        goldPerTurn: 4,
      );
      final state = PersistentGameState(
        playerGold: const {'player_1': 10},
        units: [
          GameUnit.startingWarrior(ownerPlayerId: 'player_1', col: 1, row: 0),
        ],
        runtimeState: const GameRuntimeState(
          mapObjectiveHoldStatesByObjectiveId: {
            'pass_1': MapObjectiveHoldState(
              objectiveId: 'pass_1',
              playerId: 'player_1',
              holdTurns: 2,
            ),
          },
        ),
      );

      final result = PersistentTurnEconomyProcessor.advanceForPlayers(
        state: state,
        playerIds: const ['player_1'],
        mapData: _mapData(),
        mapObjectives: const [objective],
      );

      expect(result.state.playerGold['player_1'], 14);
      expect(result.events.whereType<MapObjectiveSecuredEvent>(), isEmpty);
    });

    test('waits for required map objective hold before paying gold', () {
      const objective = MapObjectiveDefinition(
        id: 'holy_1',
        type: MapObjectiveType.holySite,
        hex: CityHex(col: 1, row: 0),
        requiredHoldTurns: 2,
        goldPerTurn: 4,
      );
      final state = PersistentGameState(
        playerGold: const {'player_1': 10},
        units: [
          GameUnit.startingWarrior(ownerPlayerId: 'player_1', col: 1, row: 0),
        ],
      );

      final result = PersistentTurnEconomyProcessor.advanceForPlayers(
        state: state,
        playerIds: const ['player_1'],
        mapData: _mapData(),
        mapObjectives: const [objective],
      );

      final hold = result
          .state
          .runtimeState
          .mapObjectiveHoldStatesByObjectiveId['holy_1'];
      expect(hold, isNotNull);
      expect(hold!.holdTurns, 1);
      expect(result.state.playerGold['player_1'], 10);
    });

    test(
      'pays and advances resource trade agreements once per importer turn',
      () {
        const state = PersistentGameState(
          playerGold: {'player_1': 10, 'player_2': 4},
          runtimeState: GameRuntimeState(
            resourceTradeAgreements: [
              ResourceTradeAgreement(
                id: 'trade_1',
                exporterPlayerId: 'player_2',
                importerPlayerId: 'player_1',
                resource: ResourceType.horses,
                goldPerTurn: 3,
                remainingTurns: 2,
              ),
            ],
          ),
        );

        final result = PersistentTurnEconomyProcessor.advanceForPlayers(
          state: state,
          playerIds: const ['player_1', 'player_2'],
          mapData: _mapData(),
        );

        expect(result.state.playerGold['player_1'], 7);
        expect(result.state.playerGold['player_2'], 7);
        expect(result.state.runtimeState.resourceTradeAgreements, [
          const ResourceTradeAgreement(
            id: 'trade_1',
            exporterPlayerId: 'player_2',
            importerPlayerId: 'player_1',
            resource: ResourceType.horses,
            goldPerTurn: 3,
            remainingTurns: 1,
          ),
        ]);
      },
    );

    test('adds a friendly relation bonus to resource trade income', () {
      final state = PersistentGameState(
        playerGold: const {'player_1': 10, 'player_2': 4},
        runtimeState: GameRuntimeState(
          diplomacy: DiplomacyState.empty.setStatus(
            'player_1',
            'player_2',
            DiplomaticRelationStatus.friendly,
          ),
          resourceTradeAgreements: const [
            ResourceTradeAgreement(
              id: 'trade_1',
              exporterPlayerId: 'player_2',
              importerPlayerId: 'player_1',
              resource: ResourceType.horses,
              goldPerTurn: 3,
              remainingTurns: 2,
            ),
          ],
        ),
      );

      final result = PersistentTurnEconomyProcessor.advanceForPlayers(
        state: state,
        playerIds: const ['player_1'],
        mapData: _mapData(),
      );

      expect(result.state.playerGold['player_1'], 7);
      expect(
        result.state.playerGold['player_2'],
        4 + 3 + DiplomaticRelationBenefits.friendlyResourceTradeGoldBonus,
      );
      expect(
        result.state.runtimeState.resourceTradeAgreements.single.remainingTurns,
        1,
      );
    });

    test('does not add friendly income bonus to free resource trades', () {
      final state = PersistentGameState(
        playerGold: const {'player_1': 10, 'player_2': 4},
        runtimeState: GameRuntimeState(
          diplomacy: DiplomacyState.empty.setStatus(
            'player_1',
            'player_2',
            DiplomaticRelationStatus.friendly,
          ),
          resourceTradeAgreements: const [
            ResourceTradeAgreement(
              id: 'trade_1',
              exporterPlayerId: 'player_2',
              importerPlayerId: 'player_1',
              resource: ResourceType.horses,
              goldPerTurn: 0,
              remainingTurns: 2,
            ),
          ],
        ),
      );

      final result = PersistentTurnEconomyProcessor.advanceForPlayers(
        state: state,
        playerIds: const ['player_1'],
        mapData: _mapData(),
      );

      expect(result.state.playerGold, state.playerGold);
      expect(
        result.state.runtimeState.resourceTradeAgreements.single.remainingTurns,
        1,
      );
    });

    test('expires resource trade agreement when importer cannot pay', () {
      const state = PersistentGameState(
        playerGold: {'player_1': 2, 'player_2': 4},
        runtimeState: GameRuntimeState(
          resourceTradeAgreements: [
            ResourceTradeAgreement(
              id: 'trade_1',
              exporterPlayerId: 'player_2',
              importerPlayerId: 'player_1',
              resource: ResourceType.iron,
              goldPerTurn: 3,
              remainingTurns: 4,
            ),
          ],
        ),
      );

      final result = PersistentTurnEconomyProcessor.advanceForPlayers(
        state: state,
        playerIds: const ['player_1'],
        mapData: _mapData(),
      );

      expect(result.state.playerGold, {'player_1': 2, 'player_2': 4});
      expect(result.state.runtimeState.resourceTradeAgreements, isEmpty);
    });
  });
}

MapData _mapData() {
  return MapData(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
