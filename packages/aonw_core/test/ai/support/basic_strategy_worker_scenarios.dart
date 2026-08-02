part of '../basic_strategy_test.dart';

void _registerBasicStrategyWorkerScenarios() {
  test('assigns an idle worker standing on an improved city tile', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 0,
          row: 1,
        ),
      ],
      cities: [
        _TestCities.capital.copyWith(
          controlledHexes: const [CityHex(col: 0, row: 1)],
        ),
      ],
      fieldImprovements: const [
        FieldImprovement(
          hex: CityHex(col: 0, row: 1),
          type: FieldImprovementType.farm,
          builtByCityId: 'city_1',
        ),
      ],
      research: _researchWithUnlocked(TechnologyId.agriculture),
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 3,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 3,
      rng: AiRng.fromTurn(turn: 3, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<AssignWorkerToHexCommand>(),
      contains(const AssignWorkerToHexCommand('worker_1')),
    );
    expect(plan.commands.whereType<SelectWorkerImprovementCommand>(), isEmpty);
  });

  test(
    'moves an idle worker off an improved tile to build a new improvement',
    () {
      final mapData = _pastureResourceMap();
      final state = DomainState.snapshot(
        units: [
          _unit(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 1,
          ),
        ],
        cities: [
          _TestCities.capital.copyWith(
            center: const CityHex(col: 0, row: 0),
            controlledHexes: const [
              CityHex(col: 0, row: 1),
              CityHex(col: 1, row: 0),
            ],
          ),
        ],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 0, row: 1),
            type: FieldImprovementType.farm,
            builtByCityId: 'city_1',
          ),
        ],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {
                TechnologyId.agriculture,
                TechnologyId.animalHusbandry,
              },
              activeTechnologyId: TechnologyId.mining,
            ),
          },
        ),
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: _allHexesIn(mapData),
            ),
          },
        ),
      );
      final view = GameView.fromDomainState(
        state,
        forPlayerId: 'player_1',
        turn: 3,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 3,
        rng: AiRng.fromTurn(turn: 3, playerId: 'player_1', baseSeed: 1001),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<MoveUnitCommand>(),
        contains(const MoveUnitCommand('worker_1', 1, 0)),
      );
      expect(plan.commands.whereType<AssignWorkerToHexCommand>(), isEmpty);
    },
  );

  test('starts a farm when an idle worker is on a controlled plains tile', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 0,
          row: 1,
        ),
      ],
      cities: [
        _TestCities.capital.copyWith(
          controlledHexes: const [CityHex(col: 0, row: 1)],
        ),
      ],
      research: _researchWithUnlocked(TechnologyId.agriculture),
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 3,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 3,
      rng: AiRng.fromTurn(turn: 3, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<SelectWorkerImprovementCommand>(),
      contains(
        const SelectWorkerImprovementCommand(
          'worker_1',
          FieldImprovementType.farm,
        ),
      ),
    );
    expect(
      plan.commands.whereType<MoveUnitCommand>().where(
        (command) => command.unitId == 'worker_1',
      ),
      isEmpty,
    );
  });

  test('moves an idle worker from city center toward an improvable tile', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 1,
          row: 1,
        ),
      ],
      cities: [
        _TestCities.capital.copyWith(
          controlledHexes: const [CityHex(col: 0, row: 1)],
        ),
      ],
      research: _researchWithUnlocked(TechnologyId.agriculture),
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 3,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 3,
      rng: AiRng.fromTurn(turn: 3, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<MoveUnitCommand>(),
      contains(const MoveUnitCommand('worker_1', 0, 1)),
    );
    expect(plan.commands.whereType<SelectWorkerImprovementCommand>(), isEmpty);
  });

  test('fallback moves a worker toward a farther improvable tile', () {
    final mapData = _combatPressureMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 0,
          row: 0,
        ),
      ],
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
          controlledHexes: [CityHex(col: 4, row: 0)],
        ),
      ],
      research: _researchWithUnlocked(TechnologyId.agriculture),
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 3,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 3,
      rng: AiRng.fromTurn(turn: 3, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: const StrategicPlan(
        computedAtTurn: 3,
        mode: StrategicMode.consolidate,
        expectations: _testExpectations,
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<MoveUnitCommand>(),
      contains(const MoveUnitCommand('worker_1', 3, 0)),
    );
  });

  test('uses strategic worker target before the local tile fallback', () {
    final mapData = _pastureResourceMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 0,
          row: 1,
        ),
      ],
      cities: [
        _TestCities.capital.copyWith(
          center: const CityHex(col: 0, row: 0),
          controlledHexes: const [
            CityHex(col: 0, row: 1),
            CityHex(col: 1, row: 0),
          ],
        ),
      ],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {
              TechnologyId.agriculture,
              TechnologyId.animalHusbandry,
            },
            activeTechnologyId: TechnologyId.mining,
          ),
        },
      ),
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 3,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final strategicPlan = StrategicPlan(
      computedAtTurn: 3,
      mode: StrategicMode.expand,
      expectations: const EconomyExpectations(
        expectedCityCount: 2,
        expectedWorkerCount: 1,
        expectedMilitaryCount: 1,
        goldReserveTarget: 8,
        minimumSciencePerTurn: 2,
      ),
      workerAssignments: {
        'worker_1': StrategicWorkerAssignment(
          workerId: 'worker_1',
          cityId: 'city_1',
          targets: const [
            StrategicWorkerTarget(
              cityId: 'city_1',
              targetHex: CityHex(col: 1, row: 0),
              improvementType: FieldImprovementType.pasture,
              score: 4000,
              buildTurns: 3,
              existingImprovement: false,
            ),
          ],
        ),
      },
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 3,
      rng: AiRng.fromTurn(turn: 3, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: strategicPlan,
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<MoveUnitCommand>(),
      contains(const MoveUnitCommand('worker_1', 1, 0)),
    );
    expect(
      plan.commands.whereType<SelectWorkerImprovementCommand>().where(
        (command) => command.unitId == 'worker_1',
      ),
      isEmpty,
    );
  });

  test('skips worker actions for a busy worker', () {
    final mapData = _foundingScenarioMap();
    final worker =
        _unit(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 0,
          row: 1,
        ).copyWithWorkerJob(
          const WorkerJob(
            targetHex: CityHex(col: 0, row: 1),
            improvementType: FieldImprovementType.farm,
            remainingTurns: 1,
            totalTurns: 2,
          ),
        );
    final state = DomainState.snapshot(
      units: [worker],
      cities: [
        _TestCities.capital.copyWith(
          controlledHexes: const [CityHex(col: 0, row: 1)],
        ),
      ],
      research: _researchWithUnlocked(TechnologyId.agriculture),
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 3,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 3,
      rng: AiRng.fromTurn(turn: 3, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(plan.commands.whereType<AssignWorkerToHexCommand>(), isEmpty);
    expect(plan.commands.whereType<SelectWorkerImprovementCommand>(), isEmpty);
    expect(
      plan.commands.whereType<MoveUnitCommand>().where(
        (command) => command.unitId == 'worker_1',
      ),
      isEmpty,
    );
  });
}
