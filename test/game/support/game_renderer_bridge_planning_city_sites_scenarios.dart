part of '../game_renderer_keyboard_test.dart';

void _registerRendererPlanningCitySitesScenarios() {
  test(
    'tapping the active city icon recenters even without selection change',
    () async {
      final map = _map(3, 3);
      final commands = <GameIntent>[];
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 1, row: 1),
      );
      final game = GameRenderer(
        mapData: map,
        onCommand: (command) async => commands.add(command),
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(
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
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();
      game.camera.viewfinder
        ..zoom = 1.6
        ..position = Vector2(900, 700);
      final start = _visibleCenter(game).clone();
      final target = CityMarkerLayer.worldPositionFor(1, 1);

      game.world.children.whereType<CityMarker>().single.onTap?.call();
      await Future<void>.delayed(Duration.zero);

      expect(commands, [CityTappedCommand(city.id)]);
      _expectVectorClose(_visibleCenter(game), start);

      game.update(1);

      _expectVectorClose(_visibleCenter(game), target);
    },
  );
  test('quick double tapping a city opens its description detail', () async {
    final map = _map(3, 3);
    final commands = <GameIntent>[];
    final descriptionRequests = <String>[];
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Capital',
      center: CityHex(col: 1, row: 1),
    );
    final game = GameRenderer(
      mapData: map,
      onCommand: (command) async => commands.add(command),
      onCityDescriptionRequested: (city) => descriptionRequests.add(city.id),
    );
    addTearDown(game.disposeRenderer);

    game
      ..applyState(GameClientState(cities: [city]))
      ..onGameResize(Vector2(800, 600));
    await game.onLoad();

    final marker = game.world.children.whereType<CityMarker>().single;
    marker.onTap?.call();
    marker.onTap?.call();
    await Future<void>.delayed(Duration.zero);

    expect(commands, [CityTappedCommand(city.id), SelectCityCommand(city.id)]);
    expect(descriptionRequests, [city.id]);
  });
  test(
    'combat animation retains killed defender marker until completion',
    () async {
      final map = _map(2, 1);
      final attacker = GameUnit(
        id: 'attacker',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final defender = GameUnit(
        id: 'defender',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 1,
        row: 0,
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..applyState(GameClientState(units: [attacker, defender]))
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();
      game.update(0);

      final future = game.applyTransition(
        GameClientState(units: [attacker.copyWith(movementPoints: 0)]),
        const [
          PlayCombatAnimationEffect(
            attackerUnitId: 'attacker',
            defenderUnitId: 'defender',
            defenderKilled: true,
          ),
        ],
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        game.animatingUnitIdsListenable.value,
        containsAll(['attacker', 'defender']),
      );
      expect(
        game.unitMarkerActionForTesting('attacker'),
        UnitSpriteAction.attack,
      );

      game.update(0.4);
      expect(game.unitMarkerActionForTesting('defender'), UnitSpriteAction.die);

      game.update(0.4);
      await future;
      expect(
        game.animatingUnitIdsListenable.value,
        isNot(contains('defender')),
      );
      expect(game.unitMarkerActionForTesting('defender'), isNull);
      expect(
        game.unitMarkerActionForTesting('attacker'),
        UnitSpriteAction.idle,
      );
    },
  );
  test('syncs city-site planning markers from current game state', () async {
    final map = WorldMap(
      cols: 4,
      rows: 2,
      tiles: [
        for (int r = 0; r < 2; r++)
          for (int c = 0; c < 4; c++)
            WorldTile(
              col: c,
              row: r,
              terrains: c == 2 && r == 1
                  ? const [TerrainType.ocean]
                  : const [TerrainType.grassland],
              resources: const [],
              height: 0,
            ),
      ],
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      controlledHexes: [CityHex(col: 1, row: 0)],
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    addTearDown(game.disposeRenderer);

    game
      ..applyState(GameClientState(cities: [city]))
      ..onGameResize(Vector2(800, 600));
    await game.onLoad();

    final center = game.tileMarkersForTesting(0, 0);
    final owned = game.tileMarkersForTesting(1, 0);
    final growthCandidate = game.tileMarkersForTesting(0, 1);
    final ocean = game.tileMarkersForTesting(2, 1);
    final territoryCandidate = game.tileMarkersForTesting(3, 1);

    expect(center.hasAny, isFalse);
    expect(owned.canFoundCity, isFalse);
    expect(owned.canGrowCity, isFalse);
    expect(growthCandidate.canFoundCity, isFalse);
    expect(growthCandidate.canGrowCity, isTrue);
    expect(ocean.canFoundCity, isFalse);
    expect(ocean.canGrowCity, isTrue);
    expect(territoryCandidate.canFoundCity, isTrue);
    expect(territoryCandidate.canGrowCity, isTrue);
  });
  test('selected settler forces city-site markers visible', () async {
    final map = _map(3, 2);
    final settler = GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
      col: 0,
      row: 0,
      army: const [ArmyTroop(type: TroopType.settler, count: 1)],
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    addTearDown(game.disposeRenderer);

    game
      ..applyState(
        GameClientState(
          units: [settler],
          interaction: InteractionState(selection: GameSelection.unit(settler)),
        ),
      )
      ..onGameResize(Vector2(800, 600));
    await game.onLoad();

    final candidate = game.tileMarkersForTesting(1, 0);

    expect(candidate.canFoundCity, isTrue);
    expect(candidate.forceShowCitySite, isTrue);

    game.applyState(GameClientState(units: [settler]));

    expect(game.tileMarkersForTesting(1, 0).forceShowCitySite, isFalse);
  });
  test('selected settler highlights best city-site markers', () async {
    final map = WorldMap(
      cols: 5,
      rows: 1,
      tiles: [
        WorldTile(
          col: 0,
          row: 0,
          terrains: [TerrainType.tundra],
          resources: [],
          height: 0,
        ),
        WorldTile(
          col: 1,
          row: 0,
          terrains: [TerrainType.grassland],
          resources: [ResourceType.wheat],
          height: 0,
        ),
        WorldTile(
          col: 2,
          row: 0,
          terrains: [TerrainType.hills],
          resources: [ResourceType.iron],
          height: 0,
        ),
        WorldTile(
          col: 3,
          row: 0,
          terrains: [TerrainType.grassland],
          resources: [ResourceType.deer],
          height: 0,
        ),
        WorldTile(
          col: 4,
          row: 0,
          terrains: [TerrainType.plains],
          resources: [ResourceType.rice],
          height: 0,
        ),
      ],
    );
    final settler = GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
      col: 2,
      row: 0,
      army: const [ArmyTroop(type: TroopType.settler, count: 1)],
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    addTearDown(game.disposeRenderer);
    final visibleHexes = {
      for (final tile in map.tiles) HexCoordinate.fromTile(tile),
    };
    final fogOfWar = FogOfWarState.empty.updatePlayer(
      PlayerFogOfWar(playerId: 'player_1', visibleHexes: visibleHexes),
    );

    game
      ..applyState(
        GameClientState(
          activePlayerId: 'player_1',
          fogOfWar: fogOfWar,
          units: [settler],
          interaction: InteractionState(
            selection: GameSelection.unit(settler, tile: _tile(map, 2, 0)),
          ),
        ),
      )
      ..onGameResize(Vector2(800, 600));
    await game.onLoad();

    final actualRecommended = {
      for (final tile in map.tiles)
        if (game.tileMarkersForTesting(tile.col, tile.row).recommendedCitySite)
          (tile.col, tile.row),
    };

    expect(actualRecommended, hasLength(4));
    expect(actualRecommended, containsAll({(1, 0), (2, 0), (3, 0), (4, 0)}));
    for (final (col, row) in actualRecommended) {
      final marker = game.tileMarkersForTesting(col, row);
      expect(marker.canFoundCity, isTrue);
      expect(marker.forceShowCitySite, isTrue);
    }

    game.applyState(
      GameClientState(activePlayerId: 'player_1', units: [settler]),
    );

    expect(game.tileMarkersForTesting(1, 0).recommendedCitySite, isFalse);
    expect(game.tileMarkersForTesting(1, 0).forceShowCitySite, isFalse);
  });
  test(
    'selected settler recommends city sites with nearby resources',
    () async {
      final map = WorldMap(
        cols: 9,
        rows: 4,
        tiles: [
          for (int row = 0; row < 4; row++)
            for (int col = 0; col < 9; col++)
              WorldTile(
                col: col,
                row: row,
                terrains: const [TerrainType.plains],
                resources: switch ((col, row)) {
                  (4, 0) => const [ResourceType.wheat],
                  (5, 1) => const [ResourceType.iron],
                  (4, 2) => const [ResourceType.deer],
                  _ => const [],
                },
                height: 0,
              ),
        ],
      );
      final settler = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 3,
        row: 1,
        army: const [ArmyTroop(type: TroopType.settler, count: 1)],
      );
      const ownCity = GameCity(
        id: 'city_player_1_0_1',
        ownerPlayerId: 'player_1',
        name: 'Home',
        center: CityHex(col: 0, row: 1),
      );
      const enemyCity = GameCity(
        id: 'city_player_2_8_2',
        ownerPlayerId: 'player_2',
        name: 'Enemy',
        center: CityHex(col: 8, row: 2),
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);
      final visibleHexes = {
        for (final tile in map.tiles) HexCoordinate.fromTile(tile),
      };
      final fogOfWar = FogOfWarState.empty.updatePlayer(
        PlayerFogOfWar(playerId: 'player_1', visibleHexes: visibleHexes),
      );

      game
        ..applyState(
          GameClientState(
            activePlayerId: 'player_1',
            fogOfWar: fogOfWar,
            units: [settler],
            cities: [ownCity, enemyCity],
            interaction: InteractionState(
              selection: GameSelection.unit(settler, tile: _tile(map, 3, 1)),
            ),
          ),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      final recommended = {
        for (final tile in map.tiles)
          if (game
              .tileMarkersForTesting(tile.col, tile.row)
              .recommendedCitySite)
            (tile.col, tile.row),
      };

      expect(recommended, contains((4, 0)));
      expect(recommended, contains((5, 1)));
      expect(recommended.length, greaterThan(3));
      expect(game.tileMarkersForTesting(8, 2).canFoundCity, isFalse);
    },
  );
}
