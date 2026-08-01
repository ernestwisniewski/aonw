part of 'turn_reducer_test.dart';

WorldMap _map(int cols, int rows) => WorldMap(
  cols: cols,
  rows: rows,
  tiles: [
    for (int row = 0; row < rows; row++)
      for (int col = 0; col < cols; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

void _registerTurnStartActionFeedbackTests(WorldMap Function() mapData) {
  test(
    'focusTurnStartAction emits production bubbles without focusing active city queues',
    () {
      final cityRuleset = CityRulesets.standard.copyWith(
        units: {
          ...CityRulesets.standard.units,
          GameUnitType.worker: const UnitProductionDefinition(
            type: GameUnitType.worker,
            productionCost: 5,
          ),
        },
      );
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 1, row: 1),
        population: 1,
        productionQueue: CityProductionQueue.unit(
          unitType: GameUnitType.worker,
          investedProduction: 1,
        ),
      );
      final state = GameClientState(
        cities: [city],
        activePlayerId: 'player_1',
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );

      final result = TurnReducer.focusTurnStartAction(
        state,
        'player_1',
        mapData(),
        ruleset: GameRuleset.defaults.copyWith(city: cityRuleset),
      );

      expect(result.state, state);
      expect(result.uiEffects.whereType<JumpCameraEffect>(), isEmpty);
      final effect = result.uiEffects
          .whereType<ShowCityProductionBubbleEffect>()
          .single;
      expect(effect.target, const UnitProductionTarget(GameUnitType.worker));
      expect(effect.col, 1);
      expect(effect.row, 1);
      expect(effect.turnsRemaining, 6);
      expect(effect.delay, const Duration(milliseconds: 120));
    },
  );

  test('production bubbles use cached unrest production', () {
    final cityRuleset = CityRulesets.standard.copyWith(
      cityCenterYield: const TileYield(
        food: 2,
        production: 8,
        gold: 0,
        defense: 0,
      ),
    );
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: const CityHex(col: 1, row: 1),
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.workshop,
        investedProduction: 0,
      ),
    );
    final state = GameClientState(
      cities: [city],
      activePlayerId: 'player_1',
      playerStabilityNet: const {'player_1': -4},
    );

    final result = TurnReducer.focusTurnStartAction(
      state,
      'player_1',
      mapData(),
      ruleset: GameRuleset.defaults.copyWith(city: cityRuleset),
    );

    final effect = result.uiEffects
        .whereType<ShowCityProductionBubbleEffect>()
        .single;
    expect(effect.turnsRemaining, 4);
  });

  test('wonder production bubbles use the supplied wonder cost', () {
    final standardDefinition = WonderRuleset.standard.definitionFor(
      WonderType.greatLibrary,
    );
    final wonderRuleset = WonderRuleset(
      wonders: {
        ...WonderRuleset.standard.wonders,
        WonderType.greatLibrary: WonderDefinition(
          type: WonderType.greatLibrary,
          productionCost: 10,
          unlockTech: standardDefinition.unlockTech,
          requirements: standardDefinition.requirements,
          standingEffects: standardDefinition.standingEffects,
          completionEffects: standardDefinition.completionEffects,
        ),
      },
    );
    final cityRuleset = CityRulesets.standard.copyWith(
      cityCenterYield: const TileYield(
        food: 2,
        production: 5,
        gold: 0,
        defense: 0,
      ),
    );
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: const CityHex(col: 1, row: 1),
      productionQueue: CityProductionQueue.wonder(
        wonderType: WonderType.greatLibrary,
        investedProduction: 0,
      ),
    );

    final result = TurnReducer.focusTurnStartAction(
      GameClientState(cities: [city], activePlayerId: 'player_1'),
      'player_1',
      mapData(),
      ruleset: GameRuleset.defaults.copyWith(
        city: cityRuleset,
        wonders: wonderRuleset,
      ),
    );

    final effect = result.uiEffects
        .whereType<ShowCityProductionBubbleEffect>()
        .single;
    expect(effect.turnsRemaining, 3);
  });

  test(
    'focusTurnStartAction keeps exhausted selected unit when only city queues report progress',
    () {
      final unit = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 1,
        row: 1,
      ).copyWith(movementPoints: 0);
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 3, row: 3),
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.wealth,
        ),
      );
      final currentMap = mapData();
      final state = GameClientState(
        units: [unit],
        cities: [city],
        activePlayerId: 'player_1',
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
        interaction: InteractionState(
          selection: GameSelection.unit(
            unit,
            tile: currentMap.tileAt(unit.col, unit.row),
          ),
        ),
      );

      final result = TurnReducer.focusTurnStartAction(
        state,
        'player_1',
        currentMap,
      );

      expect(result.state.selection?.unit?.id, unit.id);
      expect(result.uiEffects.whereType<JumpCameraEffect>(), isEmpty);
      expect(
        result.uiEffects.whereType<ShowCityProductionBubbleEffect>(),
        hasLength(1),
      );
    },
  );

  test('focusTurnStartAction keeps camera focus before production bubble', () {
    final unit = GameUnit.produced(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      col: 1,
      row: 1,
    );
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: const CityHex(col: 3, row: 3),
      productionQueue: CityProductionQueue.project(
        projectType: CityProjectType.wealth,
      ),
    );
    final state = GameClientState(
      units: [unit],
      cities: [city],
      activePlayerId: 'player_1',
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      ),
    );

    final result = TurnReducer.focusTurnStartAction(
      state,
      'player_1',
      mapData(),
    );

    expect(result.uiEffects[0], isA<JumpCameraEffect>());
    expect(result.uiEffects[1], isA<ShowCityProductionBubbleEffect>());
  });

  test(
    'focusTurnStartAction keeps research pending without jumping to production city',
    () {
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 3, row: 3),
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.wealth,
        ),
      );
      final state = GameClientState(cities: [city], activePlayerId: 'player_1');

      final result = TurnReducer.focusTurnStartAction(
        state,
        'player_1',
        mapData(),
      );

      expect(
        result.state.pendingAction,
        const PendingResearchSelection(ownerPlayerId: 'player_1'),
      );
      expect(result.uiEffects.whereType<JumpCameraEffect>(), isEmpty);
      expect(
        result.uiEffects.whereType<ShowCityProductionBubbleEffect>(),
        hasLength(1),
      );
    },
  );
}
