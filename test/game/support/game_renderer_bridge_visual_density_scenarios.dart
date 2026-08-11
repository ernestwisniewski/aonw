part of '../game_renderer_keyboard_test.dart';

void _registerRendererVisualDensityScenarios() {
  test(
    'smoothly focuses newly selected city at city marker center for current zoom',
    () async {
      final map = _map(3, 3);
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 1, row: 1),
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..applyState(GameClientState(cities: [city]))
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();
      game.camera.viewfinder
        ..zoom = 1.6
        ..position = Vector2(900, 700);
      final start = _visibleCenter(game).clone();
      final target = CityMarkerLayer.worldPositionFor(1, 1);

      game.applyState(
        GameClientState(
          cities: const [city],
          interaction: InteractionState(
            selection: GameSelection.city(
              city,
              cityYield: const TileYield(
                food: 0,
                production: 0,
                gold: 0,
                defense: 0,
              ),
              playerColor: 0xFF0000FF,
            ),
          ),
        ),
      );

      _expectVectorClose(_visibleCenter(game), start);

      game.update(0.16);
      final mid = _visibleCenter(game);
      expect((mid - start).length, greaterThan(0));
      expect((mid - target).length, greaterThan(1));

      game.update(1);

      _expectVectorClose(_visibleCenter(game), target);
    },
  );

  test('keeps persistent city labels visible when zoomed far out', () async {
    final map = _map(3, 3);
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Capital',
      center: CityHex(col: 1, row: 1),
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    addTearDown(game.disposeRenderer);

    game
      ..applyState(GameClientState(cities: [city]))
      ..onGameResize(Vector2(800, 600));
    await game.onLoad();

    expect(game.cityMarkerPaintsLabelForTesting(city.id), isTrue);

    game.setZoom(0.4);

    expect(game.cityMarkerPaintsLabelForTesting(city.id), isTrue);

    game.applyState(
      GameClientState(
        cities: const [city],
        interaction: InteractionState(
          selection: GameSelection.city(
            city,
            cityYield: const TileYield(
              food: 0,
              production: 0,
              gold: 0,
              defense: 0,
            ),
            playerColor: 0xFF0000FF,
          ),
        ),
      ),
    );

    expect(game.cityMarkerPaintsLabelForTesting(city.id), isTrue);
  });

  test('hides peripheral unit marker details when zoomed far out', () async {
    final map = _map(3, 3);
    final warrior = GameUnit(
      id: 'unit_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 1,
      row: 1,
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    addTearDown(game.disposeRenderer);

    game
      ..applyState(GameClientState(units: [warrior]))
      ..onGameResize(Vector2(800, 600));
    await game.onLoad();

    game.setZoom(game.unitMarkerDetailsMinZoomForTesting + 0.01);

    expect(game.unitMarkerShowsPeripheralDetailsForTesting(warrior.id), isTrue);

    game.setZoom(game.unitMarkerDetailsMinZoomForTesting - 0.01);

    expect(
      game.unitMarkerShowsPeripheralDetailsForTesting(warrior.id),
      isFalse,
    );
    expect(game.unitMarkerShowsOwnerColorForTesting(warrior.id), isTrue);
    expect(game.unitMarkerShowsHealthBarForTesting(warrior.id), isTrue);
    expect(game.unitMarkerShowsTypeBadgeForTesting(warrior.id), isTrue);
    expect(game.unitMarkerShowsStateBadgeForTesting(warrior.id), isTrue);

    game.setZoom(0.52);

    expect(
      game.unitMarkerShowsPeripheralDetailsForTesting(warrior.id),
      isFalse,
    );
    expect(game.unitMarkerShowsOwnerColorForTesting(warrior.id), isTrue);
    expect(game.unitMarkerShowsHealthBarForTesting(warrior.id), isTrue);
    expect(game.unitMarkerShowsTypeBadgeForTesting(warrior.id), isTrue);
    expect(game.unitMarkerShowsStateBadgeForTesting(warrior.id), isFalse);
  });

  test('keeps city labels visible below very far zoom', () async {
    final map = _map(3, 3);
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Capital',
      center: CityHex(col: 1, row: 1),
    );
    final warrior = GameUnit(
      id: 'unit_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 2,
      row: 1,
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    addTearDown(game.disposeRenderer);

    game
      ..applyState(GameClientState(cities: [city], units: [warrior]))
      ..onGameResize(Vector2(800, 600));
    await game.onLoad();

    game.setZoom(0.34);

    expect(game.cityMarkerPaintsLabelForTesting(city.id), isTrue);
    expect(game.unitMarkerPositionForTesting(warrior.id), isNotNull);
    expect(game.cityMarkerWorldScaleForTesting(city.id), greaterThan(1.0));
    expect(game.unitMarkerWorldScaleForTesting(warrior.id), greaterThan(1.0));
    expect(game.unitMarkerSpriteScaleForTesting(warrior.id), lessThan(1.0));
    expect(game.unitMarkerTacticalViewEmphasisForTesting(warrior.id), 1);
    expect(game.unitMarkerAnimateIdleForTesting(warrior.id), isFalse);
    expect(game.unitMarkerAnimatesSpriteForTesting(warrior.id), isFalse);
    expect(game.unitMarkerShowsHealthBarForTesting(warrior.id), isTrue);
    expect(game.unitMarkerShowsTypeBadgeForTesting(warrior.id), isTrue);
    expect(
      game.unitMarkerShowsPeripheralDetailsForTesting(warrior.id),
      isFalse,
    );
  });

  test('recomputes marker density when viewport class changes', () async {
    final map = _map(3, 3);
    final warrior = GameUnit(
      id: 'unit_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 1,
      row: 1,
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    addTearDown(game.disposeRenderer);

    game
      ..applyState(GameClientState(units: [warrior]))
      ..onGameResize(Vector2(678, 1442));
    await game.onLoad();

    expect(game.compactMarkerDensityForTesting, isTrue);
    expect(game.unitMarkerDetailsMinZoomForTesting, 0.82);

    game.setZoom(0.75);

    expect(
      game.unitMarkerShowsPeripheralDetailsForTesting(warrior.id),
      isFalse,
    );

    game.onGameResize(Vector2(840, 1436));

    expect(game.compactMarkerDensityForTesting, isFalse);
    expect(game.unitMarkerDetailsMinZoomForTesting, 0.72);
    expect(game.unitMarkerShowsPeripheralDetailsForTesting(warrior.id), isTrue);
  });

  test('adds production particles only for active player cities', () async {
    final map = _map(3, 3);
    final playerCity = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Capital',
      center: const CityHex(col: 1, row: 1),
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 0,
      ),
    );
    final enemyCity = GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_2',
      name: 'Antium',
      center: const CityHex(col: 2, row: 1),
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 0,
      ),
    );
    final knownCitiesFog = FogOfWarState(
      players: {
        'player_1': PlayerFogOfWar(
          playerId: 'player_1',
          discoveredHexes: {
            const HexCoordinate(col: 1, row: 1),
            const HexCoordinate(col: 2, row: 1),
          },
        ),
      },
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    addTearDown(game.disposeRenderer);

    game
      ..applyState(
        GameClientState(
          activePlayerId: 'player_1',
          cities: [playerCity, enemyCity],
          fogOfWar: knownCitiesFog,
        ),
      )
      ..onGameResize(Vector2(800, 600));
    await game.onLoad();

    expect(game.cityProductionParticleEmitterCountForTesting, 1);
    expect(
      game.cityProductionParticleEmitterReduceMotionForTesting(playerCity.id),
      isFalse,
    );

    game.setZoom(0.54);

    expect(game.cityProductionParticleEmitterCountForTesting, 0);

    game.setZoom(0.56);

    expect(game.cityProductionParticleEmitterCountForTesting, 0);

    game
      ..update(0)
      ..update(0.13);

    expect(game.cityProductionParticleEmitterCountForTesting, 1);

    game.applyState(
      GameClientState(
        activePlayerId: 'player_1',
        cities: [playerCity, enemyCity],
        fogOfWar: knownCitiesFog,
        interaction: const InteractionState(
          pendingAction: PendingAttackTargeting(
            ownerPlayerId: 'player_1',
            attackerUnitId: 'unit_1',
          ),
        ),
      ),
    );

    expect(game.cityProductionParticleEmitterCountForTesting, 0);

    game.applyState(
      GameClientState(
        activePlayerId: 'player_1',
        cities: [playerCity, enemyCity],
        fogOfWar: knownCitiesFog,
      ),
    );

    expect(game.cityProductionParticleEmitterCountForTesting, 1);

    game.reduceMotion = true;

    expect(
      game.cityProductionParticleEmitterReduceMotionForTesting(playerCity.id),
      isTrue,
    );

    game.applyState(
      GameClientState(
        activePlayerId: 'player_1',
        cities: [playerCity.copyWith(productionQueue: null), enemyCity],
        fogOfWar: knownCitiesFog,
      ),
    );

    expect(game.cityProductionParticleEmitterCountForTesting, 0);
  });
}
