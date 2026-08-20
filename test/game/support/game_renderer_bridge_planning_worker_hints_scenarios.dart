part of '../game_renderer_keyboard_test.dart';

void _registerRendererPlanningWorkerHintsScenarios() {
  test(
    'syncs attack target markers while attack targeting is active',
    () async {
      final map = kbMap(4, 1);
      final attacker = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final defender = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 1,
        row: 0,
      );
      final distantEnemy = GameUnit(
        id: 'enemy_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: 'Distant enemy',
        col: 3,
        row: 0,
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      await gameRendererFlameTester.initializeWithState(
        game,
        GameClientState(
          activePlayerId: 'player_1',
          units: [attacker, defender, distantEnemy],
          fogOfWar: FogOfWarState(
            players: {
              'player_1': PlayerFogOfWar(
                playerId: 'player_1',
                visibleHexes: {
                  for (var col = 0; col < 4; col++)
                    HexCoordinate(col: col, row: 0),
                },
              ),
            },
          ),
          interaction: InteractionState(
            selection: GameSelection.unit(attacker),
            pendingAction: const PendingAttackTargeting(
              ownerPlayerId: 'player_1',
              attackerUnitId: 'warrior_1',
            ),
          ),
        ),
      );

      expect(game.tileMarkersForTesting(1, 0).canAttackTarget, isTrue);
      expect(game.tileMarkersForTesting(3, 0).hasAny, isFalse);
      expect(game.threatOverlayHexesForTesting, isEmpty);
      expect(game.isUnitMarkerAttackTargetForTesting(defender.id), isFalse);
      expect(game.unitMarkerHasAttackTargetTintForTesting('enemy_1'), isFalse);
      expect(game.isUnitMarkerAttackTargetForTesting(distantEnemy.id), isFalse);

      game.applyState(
        GameClientState(
          activePlayerId: 'player_1',
          units: [attacker, defender, distantEnemy],
          fogOfWar: FogOfWarState(
            players: {
              'player_1': PlayerFogOfWar(
                playerId: 'player_1',
                visibleHexes: {
                  for (var col = 0; col < 4; col++)
                    HexCoordinate(col: col, row: 0),
                },
              ),
            },
          ),
          interaction: InteractionState(
            selection: GameSelection.unit(attacker),
          ),
        ),
      );

      expect(game.tileMarkersForTesting(1, 0).canAttackTarget, isFalse);
      expect(game.threatOverlayHexesForTesting, isEmpty);
      expect(game.isUnitMarkerAttackTargetForTesting(defender.id), isFalse);
    },
  );
  test('syncs worker improvement hints for selected worker', () async {
    final map = WorldMap(
      cols: 3,
      rows: 2,
      tiles: [
        for (int r = 0; r < 2; r++)
          for (int c = 0; c < 3; c++)
            WorldTile(
              col: c,
              row: r,
              terrains: c == 0 && r == 1
                  ? const [TerrainType.hills]
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
      controlledHexes: [
        CityHex(col: 1, row: 0),
        CityHex(col: 2, row: 0),
        CityHex(col: 0, row: 1),
      ],
    );
    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      name: GameUnitType.worker.defaultNameToken,
      col: 1,
      row: 0,
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    await gameRendererFlameTester.initializeWithState(
      game,
      GameClientState(
        units: [worker],
        cities: const [city],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 1, row: 0),
            type: FieldImprovementType.farm,
            builtByCityId: 'city_1',
          ),
        ],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.agriculture},
            ),
          },
        ),
        interaction: InteractionState(selection: GameSelection.unit(worker)),
      ),
    );

    expect(game.tileMarkersForTesting(1, 0).workerBuildBlocked, isTrue);
    expect(game.tileMarkersForTesting(1, 0).workerBuildAvailable, isFalse);
    expect(
      game.tileMarkersForTesting(1, 0).workerImprovementCandidate,
      isFalse,
    );
    expect(game.tileMarkersForTesting(2, 0).canImproveNow, isTrue);
    expect(game.tileMarkersForTesting(2, 0).workerBuildAvailable, isFalse);
    expect(game.tileMarkersForTesting(2, 0).workerBuildBlocked, isFalse);
    expect(game.tileMarkersForTesting(2, 0).workerImprovementCandidate, isTrue);
    expect(game.tileMarkersForTesting(0, 1).canImproveAfterTechnology, isTrue);
    expect(game.tileMarkersForTesting(0, 1).workerBuildBlocked, isFalse);
    expect(
      game.tileMarkersForTesting(0, 1).workerImprovementCandidate,
      isFalse,
    );
    expect(game.tileMarkersForTesting(1, 1).workerBuildAvailable, isFalse);
    expect(game.tileMarkersForTesting(1, 1).workerBuildBlocked, isFalse);
    final fullWorkerBuildMarkers = [
      for (final tile in map.tiles)
        if (game.tileMarkersForTesting(tile.col, tile.row) case final marker
            when marker.workerBuildAvailable || marker.workerBuildBlocked)
          (tile.col, tile.row),
    ];
    expect(fullWorkerBuildMarkers, [(1, 0)]);
    expect(
      _overlayKindFor(game, const CityHex(col: 1, row: 0)),
      CityManagementOverlayHexKind.workerImprovementExisting,
    );
    expect(_overlayFor(game, const CityHex(col: 1, row: 0))?.label, '3F');
    expect(
      _overlayFor(game, const CityHex(col: 1, row: 0))?.tileYield,
      const TileYield(food: 3, production: 0, gold: 0, defense: 0),
    );
    expect(
      _overlayKindFor(game, const CityHex(col: 2, row: 0)),
      CityManagementOverlayHexKind.workerImprovementMissingInCity,
    );
    expect(_overlayFor(game, const CityHex(col: 2, row: 0))?.label, '3F');
    expect(
      _overlayFor(game, const CityHex(col: 2, row: 0))?.tileYield,
      const TileYield(food: 3, production: 0, gold: 0, defense: 0),
    );
    expect(_overlayKindFor(game, const CityHex(col: 1, row: 1)), isNull);
    expect(
      _overlayKindFor(game, const CityHex(col: 0, row: 1)),
      CityManagementOverlayHexKind.workerImprovementMissingInCity,
    );
    expect(_overlayFor(game, const CityHex(col: 0, row: 1))?.label, '2P');
    expect(
      _overlayFor(game, const CityHex(col: 0, row: 1))?.tileYield,
      const TileYield(food: 0, production: 2, gold: 0, defense: 0),
    );
  });
  test('marks current worker hex green when a build can start there', () async {
    final map = WorldMap(
      cols: 3,
      rows: 1,
      tiles: [
        for (int c = 0; c < 3; c++)
          WorldTile(
            col: c,
            row: 0,
            terrains: const [TerrainType.grassland],
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
      controlledHexes: [CityHex(col: 2, row: 0)],
    );
    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      name: GameUnitType.worker.defaultNameToken,
      col: 2,
      row: 0,
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    await gameRendererFlameTester.initializeWithState(
      game,
      GameClientState(
        units: [worker],
        cities: const [city],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.agriculture},
            ),
          },
        ),
        interaction: InteractionState(selection: GameSelection.unit(worker)),
      ),
    );

    expect(game.tileMarkersForTesting(2, 0).workerBuildAvailable, isTrue);
    expect(game.tileMarkersForTesting(2, 0).workerBuildBlocked, isFalse);
    expect(
      game.tileMarkersForTesting(2, 0).workerImprovementCandidate,
      isFalse,
    );
  });
  test(
    'tap movement animates and then allows the selected unit tile to cycle',
    () async {
      final map = kbMap(3, 3);
      final reducer = GameStateReducer(mapData: map);
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 0,
        row: 0,
      );
      var state = GameClientState(units: [commander]);
      late final GameRenderer game;
      game = GameRenderer(
        mapData: map,
        onCommand: (command) async {
          final transition = resolveWithEffects(reducer, state, command);
          state = transition.state;
          game.applyState(state);
          await game.handleEffects(transition.uiEffects.rendererEffects);
        },
      );
      await gameRendererFlameTester.initializeWithState(game, state);
      await Future<void>.delayed(Duration.zero);
      game.update(0);
      await game.handleTileTappedForTesting(kbTile(map, 0, 0));
      expect(state.selection?.type, GameSelectionType.unit);
      expect(state.moveCommandActive, isTrue);

      await game.handleTileTappedForTesting(kbTile(map, 1, 0));
      expect(state.movePreview?.targetCol, 1);
      expect(state.movePreview?.targetRow, 0);

      final moveFuture = game.handleTileTappedForTesting(kbTile(map, 1, 0));
      await Future<void>.delayed(Duration.zero);
      game.update(0.32);
      await Future<void>.delayed(Duration.zero);
      expect(game.animatingUnitIdsListenable.value, contains(commander.id));

      game
        ..update(0.3)
        ..update(0.4);
      await moveFuture;
      expect(
        game.animatingUnitIdsListenable.value,
        isNot(contains(commander.id)),
      );
      expect(state.units.single.col, 1);
      expect(state.moveCommandActive, isTrue);

      await game.handleTileTappedForTesting(kbTile(map, 1, 0));
      expect(state.selection?.type, GameSelectionType.tile);
      expect(state.moveCommandActive, isFalse);

      await game.handleTileTappedForTesting(kbTile(map, 1, 0));
      expect(state.selection?.type, GameSelectionType.unit);
    },
  );
}
