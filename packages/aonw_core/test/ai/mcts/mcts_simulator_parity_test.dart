import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('TracingMctsSimulator movement parity', () {
    test('applies reachable movement like PersistentMoveUnitResolver', () {
      final unit = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final state = PersistentGameState(units: [unit], fogOfWar: _visibleFog());
      const command = MoveUnitCommand('warrior_1', 1, 0);

      final persistent = _resolvePersistent(state, command);
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isTrue);
      _expectSameMovementState(
        _unitById(simulated.ownUnits, 'warrior_1'),
        _unitById(persistent.state.units, 'warrior_1'),
      );
    });

    test('applies partial movement and queued path like resolver', () {
      final unit = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      ).copyWith(movementPoints: 1);
      final state = PersistentGameState(units: [unit], fogOfWar: _visibleFog());
      const command = MoveUnitCommand('warrior_1', 2, 0);

      final persistent = _resolvePersistent(state, command);
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isTrue);
      _expectSameMovementState(
        _unitById(simulated.ownUnits, 'warrior_1'),
        _unitById(persistent.state.units, 'warrior_1'),
      );
      expect(_unitById(simulated.ownUnits, 'warrior_1').queuedPath, isNotNull);
    });

    test('applies partial movement through rough passable terrain', () {
      final unit = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final state = PersistentGameState(units: [unit], fogOfWar: _visibleFog());
      const command = MoveUnitCommand('warrior_1', 2, 0);
      final mapDefinition = _highCostMapDefinition();
      final mapData = _highCostMapData();

      final persistent = _resolvePersistent(
        state,
        command,
        mapDefinition: mapDefinition,
      );
      final simulated = _simulate(state, command, mapData: mapData);

      expect(persistent.accepted, isTrue);
      _expectSameMovementState(
        _unitById(simulated.ownUnits, 'warrior_1'),
        _unitById(persistent.state.units, 'warrior_1'),
      );
      expect(_unitById(simulated.ownUnits, 'warrior_1').col, 1);
      expect(_unitById(simulated.ownUnits, 'warrior_1').movementPoints, 0);
      expect(_unitById(simulated.ownUnits, 'warrior_1').queuedPath, isNotNull);
    });

    test('leaves unit in place when resolver rejects occupied target', () {
      final unit = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final blocker = GameUnit.produced(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 1,
        row: 0,
      );
      final state = PersistentGameState(
        units: [unit, blocker],
        fogOfWar: _visibleFog(),
      );
      const command = MoveUnitCommand('warrior_1', 1, 0);

      final persistent = _resolvePersistent(state, command);
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isFalse);
      expect(_unitById(simulated.ownUnits, 'warrior_1'), unit);
    });

    test('approaches visible opponent-occupied target like resolver', () {
      final unit = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final blocker = GameUnit.produced(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 2,
        row: 0,
      );
      final state = PersistentGameState(
        units: [unit, blocker],
        fogOfWar: _visibleFog(),
      );
      const command = MoveUnitCommand('warrior_1', 2, 0);

      final persistent = _resolvePersistent(state, command);
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isTrue);
      _expectSameMovementState(
        _unitById(simulated.ownUnits, 'warrior_1'),
        _unitById(persistent.state.units, 'warrior_1'),
      );
    });

    test('queues approach movement toward a distant occupied target', () {
      final unit = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      ).copyWith(movementPoints: 0);
      final blocker = GameUnit.produced(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 2,
        row: 0,
      );
      final state = PersistentGameState(
        units: [unit, blocker],
        fogOfWar: _visibleFog(),
      );
      const command = MoveUnitCommand('warrior_1', 2, 0);

      final persistent = _resolvePersistent(state, command);
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isTrue);
      _expectSameMovementState(
        _unitById(simulated.ownUnits, 'warrior_1'),
        _unitById(persistent.state.units, 'warrior_1'),
      );
      expect(
        _unitById(simulated.ownUnits, 'warrior_1').queuedPath?.targetCol,
        1,
      );
    });
  });

  group('TracingMctsSimulator unit action parity', () {
    test('cancels fortification like PersistentUnitActionResolver', () {
      final unit = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
        movementPoints: 0,
        posture: UnitPosture.fortified,
      );
      const command = CancelUnitActionCommand('warrior_1');
      final state = PersistentGameState(units: [unit]);

      final persistent = _resolvePersistentUnitAction(state, command);
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isTrue);
      expect(
        _unitById(simulated.ownUnits, 'warrior_1').toJson(),
        _unitById(persistent.state.units, 'warrior_1').toJson(),
      );
    });
  });

  group('TracingMctsSimulator city founding parity', () {
    test('schedules city founding like PersistentCityFoundingResolver', () {
      final settler = GameUnit.produced(
        id: 'settler_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        col: 0,
        row: 0,
      );
      final state = PersistentGameState(
        units: [settler],
        fogOfWar: _visibleFog(),
      );
      const command = FoundCityCommand(
        'settler_1',
        controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 2, row: 0)],
      );

      final persistent = _resolvePersistentFounding(state, command);
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isTrue);
      expect(
        _unitById(simulated.ownUnits, 'settler_1'),
        _unitById(persistent.state.units, 'settler_1'),
      );
      expect(simulated.ownCities, isEmpty);
    });

    test('leaves state unchanged when founding payload is invalid', () {
      final settler = GameUnit.produced(
        id: 'settler_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        col: 0,
        row: 0,
      );
      final state = PersistentGameState(
        units: [settler],
        fogOfWar: _visibleFog(),
      );
      const command = FoundCityCommand(
        'settler_1',
        controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 1, row: 0)],
      );

      final persistent = _resolvePersistentFounding(state, command);
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isFalse);
      expect(_unitById(simulated.ownUnits, 'settler_1'), settler);
      expect(simulated.ownCities, persistent.state.cities);
    });
  });

  group('TracingMctsSimulator combat parity', () {
    test('resolves lethal attack like PersistentTurnCombatResolver', () {
      final attacker = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final defender = GameUnit.produced(
        id: 'settler_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.settler,
        col: 1,
        row: 0,
      );
      final state = PersistentGameState(
        units: [attacker, defender],
        fogOfWar: _visibleFog(),
      );
      const command = AttackHexCommand('warrior_1', 1, 0);

      final persistent = _resolvePersistentCombat(state, command);
      final simulated = _simulate(state, command);

      _expectSameCombatUnit(
        _maybeUnitById(simulated.ownUnits, 'warrior_1'),
        _maybeUnitById(persistent.state.units, 'warrior_1'),
      );
      _expectSameCombatUnit(
        _maybeUnitById(simulated.visibleEnemyUnits, 'settler_2'),
        _maybeUnitById(persistent.state.units, 'settler_2'),
      );
    });

    test('leaves state unchanged when attacker cannot attack', () {
      final attacker = GameUnit.produced(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        col: 0,
        row: 0,
      );
      final defender = GameUnit.produced(
        id: 'settler_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.settler,
        col: 1,
        row: 0,
      );
      final state = PersistentGameState(
        units: [attacker, defender],
        fogOfWar: _visibleFog(),
      );
      const command = AttackHexCommand('worker_1', 1, 0);

      final persistent = _resolvePersistentCombat(state, command);
      final simulated = _simulate(state, command);

      _expectSameCombatUnit(
        _maybeUnitById(simulated.ownUnits, 'worker_1'),
        _maybeUnitById(persistent.state.units, 'worker_1'),
      );
      _expectSameCombatUnit(
        _maybeUnitById(simulated.visibleEnemyUnits, 'settler_2'),
        _maybeUnitById(persistent.state.units, 'settler_2'),
      );
      expect(persistent.events, isEmpty);
    });

    test('leaves friendly unit attack unchanged', () {
      final attacker = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final defender = GameUnit.produced(
        id: 'settler_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.settler,
        col: 1,
        row: 0,
      );
      final state = PersistentGameState(
        units: [attacker, defender],
        fogOfWar: _visibleFog(),
        runtimeState: GameRuntimeState(
          diplomacy: DiplomacyState.empty.setStatus(
            'player_1',
            'player_2',
            DiplomaticRelationStatus.friendly,
          ),
        ),
      );

      final simulated = _simulate(
        state,
        const AttackHexCommand('warrior_1', 1, 0),
      );

      expect(_unitById(simulated.ownUnits, 'warrior_1'), attacker);
      expect(_unitById(simulated.visibleEnemyUnits, 'settler_2'), defender);
    });

    test('does not capture enemy city when defender dies on center', () {
      final attacker = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final defender = GameUnit.produced(
        id: 'settler_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.settler,
        col: 1,
        row: 0,
      );
      final state = PersistentGameState(
        units: [attacker, defender],
        cities: [_city(ownerPlayerId: 'player_2')],
        fogOfWar: _visibleFog(),
      );
      const command = AttackHexCommand('warrior_1', 1, 0);

      final persistent = _resolvePersistentCombat(state, command);
      final simulated = _simulate(state, command);

      expect(
        _cityById(simulated.rememberedEnemyCities, 'city_1'),
        _cityById(persistent.state.cities, 'city_1'),
      );
      expect(simulated.ownCities, isEmpty);
    });

    test('leaves friendly city attack unchanged', () {
      final attacker = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final city = _city(ownerPlayerId: 'player_2').copyWithHitPoints(1);
      final state = PersistentGameState(
        units: [attacker],
        cities: [city],
        fogOfWar: _visibleFog(),
        runtimeState: GameRuntimeState(
          diplomacy: DiplomacyState.empty.setStatus(
            'player_1',
            'player_2',
            DiplomaticRelationStatus.friendly,
          ),
        ),
      );

      final simulated = _simulate(
        state,
        const AttackHexCommand(
          'warrior_1',
          1,
          0,
          cityConquestAction: CityConquestAction.capture,
        ),
      );

      expect(_unitById(simulated.ownUnits, 'warrior_1'), attacker);
      expect(_cityById(simulated.rememberedEnemyCities, 'city_1'), city);
      expect(simulated.ownCities, isEmpty);
    });

    test('captures remembered enemy city when attacking city center', () {
      final attacker = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final city = _city(ownerPlayerId: 'player_2').copyWithHitPoints(1);
      final state = PersistentGameState(
        units: [attacker],
        cities: [city],
        fogOfWar: _visibleFog(),
      );
      const command = AttackHexCommand(
        'warrior_1',
        1,
        0,
        cityConquestAction: CityConquestAction.capture,
      );

      final persistent = _resolvePersistentCombat(state, command);
      final simulated = _simulate(state, command);

      expect(
        _cityById(simulated.ownCities, 'city_1'),
        _cityById(persistent.state.cities, 'city_1'),
      );
      expect(simulated.rememberedEnemyCities, isEmpty);
    });

    test('leaves city attack blocked by own unit unchanged', () {
      final attacker = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final blocker = GameUnit.produced(
        id: 'warrior_2',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 1,
        row: 0,
      );
      final city = _city(ownerPlayerId: 'player_2').copyWithHitPoints(1);
      final state = PersistentGameState(
        units: [attacker, blocker],
        cities: [city],
        fogOfWar: _visibleFog(),
      );
      const command = AttackHexCommand(
        'warrior_1',
        1,
        0,
        cityConquestAction: CityConquestAction.capture,
      );

      final persistent = _resolvePersistentCombat(state, command);
      final simulated = _simulate(state, command);

      expect(persistent.events, isEmpty);
      expect(_unitById(simulated.ownUnits, 'warrior_1'), attacker);
      expect(_unitById(simulated.ownUnits, 'warrior_2'), blocker);
      expect(_cityById(simulated.rememberedEnemyCities, 'city_1'), city);
    });
  });

  group('TracingMctsSimulator city production parity', () {
    test(
      'starts building production like PersistentCityProductionResolver',
      () {
        final state = PersistentGameState(cities: [_city()]);
        const command = StartBuildingCommand(
          'city_1',
          CityBuildingType.granary,
        );

        final persistent = const PersistentCityProductionResolver()
            .startBuilding(
              state: state,
              command: command,
              actorPlayerId: 'player_1',
              mapDefinition: _mapDefinition(),
            );
        final simulated = _simulate(state, command);

        expect(persistent.accepted, isTrue);
        expect(
          _cityById(simulated.ownCities, 'city_1').productionQueue,
          _cityById(persistent.state.cities, 'city_1').productionQueue,
        );
      },
    );

    test('leaves city unchanged when building is locked', () {
      final state = PersistentGameState(cities: [_city()]);
      const command = StartBuildingCommand('city_1', CityBuildingType.workshop);

      final persistent = const PersistentCityProductionResolver().startBuilding(
        state: state,
        command: command,
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isFalse);
      expect(_cityById(simulated.ownCities, 'city_1'), _city());
    });

    test('starts unit production like PersistentCityProductionResolver', () {
      final state = PersistentGameState(cities: [_city()]);
      const command = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );

      final persistent = const PersistentCityProductionResolver()
          .startUnitProduction(
            state: state,
            command: command,
            actorPlayerId: 'player_1',
            mapDefinition: _mapDefinition(),
          );
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isTrue);
      expect(
        _cityById(simulated.ownCities, 'city_1').productionQueue,
        _cityById(persistent.state.cities, 'city_1').productionQueue,
      );
    });

    test('starts city project like PersistentCityProductionResolver', () {
      final state = PersistentGameState(cities: [_city()]);
      const command = StartCityProjectCommand(
        'city_1',
        CityProjectType.research,
      );

      final persistent = const PersistentCityProductionResolver()
          .startCityProject(
            state: state,
            command: command,
            actorPlayerId: 'player_1',
          );
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isTrue);
      expect(
        _cityById(simulated.ownCities, 'city_1').productionQueue,
        _cityById(persistent.state.cities, 'city_1').productionQueue,
      );
    });

    test('uses overflow rollover when starting fresh production', () {
      final city = _city().copyWith(productionOverflow: 12);
      final state = PersistentGameState(cities: [city]);
      const command = StartBuildingCommand('city_1', CityBuildingType.granary);

      final persistent = const PersistentCityProductionResolver().startBuilding(
        state: state,
        command: command,
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isTrue);
      expect(
        _cityById(simulated.ownCities, 'city_1'),
        _cityById(persistent.state.cities, 'city_1'),
      );
    });

    test('sets city specialization like PersistentCityProductionResolver', () {
      final state = PersistentGameState(
        cities: [
          _city(buildings: {CityBuildingType.workshop}),
        ],
        research: _researchWithSpecialization(),
      );
      const command = SetCitySpecializationCommand(
        'city_1',
        CitySpecializationType.industry,
      );

      final persistent = const PersistentCityProductionResolver()
          .setCitySpecialization(
            state: state,
            command: command,
            actorPlayerId: 'player_1',
          );
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isTrue);
      expect(
        _cityById(simulated.ownCities, 'city_1'),
        _cityById(persistent.state.cities, 'city_1'),
      );
    });

    test('leaves city unchanged when specialization is locked', () {
      final state = PersistentGameState(cities: [_city()]);
      const command = SetCitySpecializationCommand(
        'city_1',
        CitySpecializationType.industry,
      );

      final persistent = const PersistentCityProductionResolver()
          .setCitySpecialization(
            state: state,
            command: command,
            actorPlayerId: 'player_1',
          );
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isFalse);
      expect(_cityById(simulated.ownCities, 'city_1'), _city());
    });
  });

  group('TracingMctsSimulator research selection parity', () {
    test('selects technology like PersistentResearchCommandResolver', () {
      const command = SelectTechnologyCommand(
        'player_1',
        TechnologyId.agriculture,
      );
      final state = PersistentGameState(
        cities: [_city()],
        fogOfWar: _visibleFog(),
      );

      final persistent = _resolvePersistentResearch(state, command);
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isTrue);
      expect(
        simulated.view.ownResearch.toJson(),
        persistent.state.research.forPlayer('player_1').toJson(),
      );
    });

    test('leaves research unchanged when technology is unavailable', () {
      const command = SelectTechnologyCommand(
        'player_1',
        TechnologyId.specialization,
      );
      final state = PersistentGameState(
        cities: [_city()],
        fogOfWar: _visibleFog(),
      );

      final persistent = _resolvePersistentResearch(state, command);
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isFalse);
      expect(
        simulated.view.ownResearch.toJson(),
        persistent.state.research.forPlayer('player_1').toJson(),
      );
    });
  });

  group('TracingMctsSimulator worker parity', () {
    test('starts worker improvement like PersistentWorkerCommandResolver', () {
      final state = PersistentGameState(
        units: [_worker()],
        cities: [
          _city(controlledHexes: const [CityHex(col: 2, row: 0)]),
        ],
        fogOfWar: _visibleFog(),
        research: _researchWith(TechnologyId.agriculture),
      );
      const command = SelectWorkerImprovementCommand(
        'worker_1',
        FieldImprovementType.farm,
      );

      final persistent = _resolvePersistentWorkerImprovement(state, command);
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isTrue);
      expect(
        _unitById(simulated.ownUnits, 'worker_1'),
        _unitById(persistent.state.units, 'worker_1'),
      );
    });

    test('assigns worker like PersistentWorkerCommandResolver', () {
      final state = PersistentGameState(
        units: [_worker()],
        cities: [
          _city(controlledHexes: const [CityHex(col: 2, row: 0)]),
        ],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 2, row: 0),
            type: FieldImprovementType.farm,
            builtByCityId: 'city_1',
          ),
        ],
        fogOfWar: _visibleFog(),
      );
      const command = AssignWorkerToHexCommand('worker_1');

      final persistent = _resolvePersistentWorkerAssignment(state, command);
      final simulated = _simulate(state, command);

      expect(persistent.accepted, isTrue);
      expect(
        _unitById(simulated.ownUnits, 'worker_1'),
        _unitById(persistent.state.units, 'worker_1'),
      );
    });
  });

  group('TracingMctsSimulator advanceTurn parity', () {
    test('advances city economy and research like processor', () {
      const granaryTarget = BuildingProductionTarget(CityBuildingType.granary);
      final granaryCost = CityProductionRules.targetCost(granaryTarget);
      final city = _city().copyWith(
        buildings: {CityBuildingType.merchantHall},
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: granaryCost - 1,
        ),
      );
      final state = PersistentGameState(
        playerGold: const {'player_1': 3},
        cities: [city],
        fogOfWar: _visibleFog(),
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );

      final persistent = _advancePersistentEconomy(state);
      final simulated = _advanceSimulatedTurn(state);

      expect(simulated.view.turn, 2);
      expect(
        _cityById(simulated.ownCities, 'city_1'),
        _cityById(persistent.state.cities, 'city_1'),
      );
      expect(simulated.view.ownGold, persistent.state.playerGold['player_1']);
      expect(
        simulated.view.ownResearch.toJson(),
        persistent.state.research.forPlayer('player_1').toJson(),
      );
    });

    test('advances worker jobs like processor', () {
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: 'Worker',
        col: 2,
        row: 0,
        workerJob: const WorkerJob(
          targetHex: CityHex(col: 2, row: 0),
          improvementType: FieldImprovementType.farm,
          remainingTurns: 1,
          totalTurns: 1,
        ),
      );
      final state = PersistentGameState(
        units: [worker],
        cities: [
          _city(controlledHexes: const [CityHex(col: 2, row: 0)]),
        ],
        fogOfWar: _visibleFog(),
      );

      final persistent = _advancePersistentEconomy(state);
      final simulated = _advanceSimulatedTurn(state);
      final simulatedWorker = _maybeUnitById(simulated.ownUnits, 'worker_1');
      final persistentWorker = _maybeUnitById(
        persistent.state.units,
        'worker_1',
      );

      expect(simulatedWorker, persistentWorker);
      expect(
        simulated.view.ownImprovements.map(
          (improvement) => improvement.toJson(),
        ),
        persistent.state.fieldImprovements.map(
          (improvement) => improvement.toJson(),
        ),
      );
    });

    test('lets visible opponents answer with BasicStrategy before economy', () {
      final settler = GameUnit.produced(
        id: 'settler_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        col: 0,
        row: 0,
      );
      final warrior = GameUnit.produced(
        id: 'warrior_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 1,
        row: 0,
      );
      final state = PersistentGameState(
        units: [settler, warrior],
        fogOfWar: _visibleFog(),
      );

      final simulated = _advanceSimulatedTurn(state);

      expect(_maybeUnitById(simulated.ownUnits, 'settler_1'), isNull);
    });

    test('can skip opponent strategy plans for fast UI rollouts', () {
      final settler = GameUnit.produced(
        id: 'settler_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        col: 0,
        row: 0,
      );
      final warrior = GameUnit.produced(
        id: 'warrior_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 1,
        row: 0,
      );
      final state = PersistentGameState(
        units: [settler, warrior],
        fogOfWar: _visibleFog(),
      );

      final simulated = _advanceSimulatedTurn(
        state,
        simulator: const TracingMctsSimulator(simulateOpponentPlans: false),
      );

      expect(_maybeUnitById(simulated.ownUnits, 'settler_1'), isNotNull);
    });

    test('can skip turn economy for fast UI rollouts', () {
      const granaryTarget = BuildingProductionTarget(CityBuildingType.granary);
      final granaryCost = CityProductionRules.targetCost(granaryTarget);
      final city = _city().copyWith(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: granaryCost - 1,
        ),
      );
      final state = PersistentGameState(
        cities: [city],
        fogOfWar: _visibleFog(),
      );

      final simulated = _advanceSimulatedTurn(
        state,
        simulator: const TracingMctsSimulator(simulateTurnEconomy: false),
      );

      expect(simulated.view.turn, 1);
      expect(_cityById(simulated.ownCities, 'city_1'), city);
    });
  });
}

PersistentMoveUnitResult _resolvePersistent(
  PersistentGameState state,
  MoveUnitCommand command, {
  MapDefinition? mapDefinition,
}) {
  return const PersistentMoveUnitResolver().resolve(
    state: state,
    command: command,
    actorPlayerId: 'player_1',
    mapDefinition: mapDefinition ?? _mapDefinition(),
  );
}

PersistentUnitActionResult _resolvePersistentUnitAction(
  PersistentGameState state,
  CancelUnitActionCommand command,
) {
  return const PersistentUnitActionResolver().cancelUnitAction(
    state: state,
    command: command,
    actorPlayerId: 'player_1',
  );
}

PersistentCityFoundingResult _resolvePersistentFounding(
  PersistentGameState state,
  FoundCityCommand command,
) {
  return const PersistentCityFoundingResolver().foundCity(
    state: state,
    command: command,
    actorPlayerId: 'player_1',
    mapDefinition: _mapDefinition(),
    cityRuleset: GameRuleset.defaults.city,
  );
}

PersistentTurnCombatResult _resolvePersistentCombat(
  PersistentGameState state,
  AttackHexCommand command,
) {
  final withIntent = state.copyWith(
    runtimeState: state.runtimeState.copyWith(
      intendedAttacks: [
        IntendedAttack(
          attackerUnitId: command.attackerUnitId,
          defenderCol: command.defenderCol,
          defenderRow: command.defenderRow,
          declaredAtTick: 1,
          declaringPlayerId: 'player_1',
          cityConquestAction: command.cityConquestAction,
        ),
      ],
    ),
  );
  return PersistentTurnCombatResolver.resolve(
    turn: 1,
    state: withIntent,
    mapDefinition: _mapDefinition(),
    ruleset: GameRuleset.defaults,
  );
}

PersistentResearchCommandResult _resolvePersistentResearch(
  PersistentGameState state,
  SelectTechnologyCommand command,
) {
  return const PersistentResearchCommandResolver().selectTechnology(
    state: state,
    command: command,
    actorPlayerId: 'player_1',
    mapDefinition: _mapDefinition(),
    ruleset: GameRuleset.defaults.technology,
  );
}

PersistentWorkerCommandResult _resolvePersistentWorkerImprovement(
  PersistentGameState state,
  SelectWorkerImprovementCommand command,
) {
  return const PersistentWorkerCommandResolver().selectWorkerImprovement(
    state: state,
    command: command,
    actorPlayerId: 'player_1',
    mapDefinition: _mapDefinition(),
    cityRuleset: GameRuleset.defaults.city,
    technologyRuleset: GameRuleset.defaults.technology,
  );
}

PersistentWorkerCommandResult _resolvePersistentWorkerAssignment(
  PersistentGameState state,
  AssignWorkerToHexCommand command,
) {
  return const PersistentWorkerCommandResolver().assignWorkerToHex(
    state: state,
    command: command,
    actorPlayerId: 'player_1',
    mapDefinition: _mapDefinition(),
  );
}

PersistentTurnEconomyResult _advancePersistentEconomy(
  PersistentGameState state,
) {
  return PersistentTurnEconomyProcessor.advanceForPlayers(
    state: state,
    playerIds: const ['player_1'],
    mapData: _mapData(),
    ruleset: GameRuleset.defaults,
  );
}

SimulatedState _simulate(
  PersistentGameState state,
  GameCommand command, {
  MapData? mapData,
}) {
  final actualMapData = mapData ?? _mapData();
  final view = GameView.fromPersistentState(
    state,
    forPlayerId: 'player_1',
    turn: 1,
    mapData: actualMapData,
    ruleset: GameRuleset.defaults,
  );
  return const TracingMctsSimulator().applyAction(
    SimulatedState.fromView(view, maxPlanningDepth: 4),
    CommandMctsAction(command),
  );
}

SimulatedState _advanceSimulatedTurn(
  PersistentGameState state, {
  TracingMctsSimulator simulator = const TracingMctsSimulator(),
}) {
  final view = GameView.fromPersistentState(
    state,
    forPlayerId: 'player_1',
    turn: 1,
    mapData: _mapData(),
    ruleset: GameRuleset.defaults,
  );
  return simulator.advanceTurn(
    SimulatedState.fromView(view, maxPlanningDepth: 4),
  );
}

GameUnit? _maybeUnitById(List<GameUnit> units, String id) {
  for (final unit in units) {
    if (unit.id == id) return unit;
  }
  return null;
}

GameUnit _unitById(List<GameUnit> units, String id) {
  return units.singleWhere((unit) => unit.id == id);
}

GameCity _cityById(List<GameCity> cities, String id) {
  return cities.singleWhere((city) => city.id == id);
}

void _expectSameMovementState(GameUnit actual, GameUnit expected) {
  expect(actual.col, expected.col);
  expect(actual.row, expected.row);
  expect(actual.movementPoints, expected.movementPoints);
  expect(actual.queuedPath?.toJson(), expected.queuedPath?.toJson());
}

void _expectSameCombatUnit(GameUnit? actual, GameUnit? expected) {
  expect(actual?.toJson(), expected?.toJson());
}

GameCity _city({
  String ownerPlayerId = 'player_1',
  List<CityHex> controlledHexes = const [],
  Set<CityBuildingType> buildings = const {},
}) {
  return GameCity(
    id: 'city_1',
    ownerPlayerId: ownerPlayerId,
    name: 'City',
    center: const CityHex(col: 1, row: 0),
    controlledHexes: controlledHexes,
    buildings: buildings,
  );
}

GameUnit _worker() {
  return GameUnit(
    id: 'worker_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.worker,
    name: 'Worker',
    col: 2,
    row: 0,
  );
}

ResearchState _researchWithSpecialization() {
  return ResearchState(
    players: {
      'player_1': PlayerResearchState(
        unlockedTechnologyIds: {TechnologyId.specialization},
      ),
    },
  );
}

ResearchState _researchWith(TechnologyId technologyId) {
  return ResearchState(
    players: {
      'player_1': PlayerResearchState(unlockedTechnologyIds: {technologyId}),
    },
  );
}

FogOfWarState _visibleFog() {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        visibleHexes: {
          const HexCoordinate(col: 0, row: 0),
          const HexCoordinate(col: 1, row: 0),
          const HexCoordinate(col: 2, row: 0),
        },
      ),
    },
  );
}

MapDefinition _mapDefinition() {
  return MapDefinition(
    cols: 3,
    rows: 1,
    tiles: [
      for (var col = 0; col < 3; col++)
        MapTileDefinition(
          col: col,
          row: 0,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
    ],
  );
}

MapData _mapData() {
  return MapData(
    cols: 3,
    rows: 1,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 2,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}

MapDefinition _highCostMapDefinition() {
  return MapDefinition(
    cols: 3,
    rows: 1,
    tiles: [
      MapTileDefinition(
        col: 0,
        row: 0,
        terrains: const [TerrainType.plains],
        resources: const [],
        height: 0,
      ),
      MapTileDefinition(
        col: 1,
        row: 0,
        terrains: const [
          TerrainType.snow,
          TerrainType.forest,
          TerrainType.tundra,
        ],
        resources: const [],
        height: 0,
      ),
      MapTileDefinition(
        col: 2,
        row: 0,
        terrains: const [TerrainType.plains],
        resources: const [],
        height: 0,
      ),
    ],
  );
}

MapData _highCostMapData() {
  return MapData(
    cols: 3,
    rows: 1,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 0,
        terrains: [TerrainType.snow, TerrainType.forest, TerrainType.tundra],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 2,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}
