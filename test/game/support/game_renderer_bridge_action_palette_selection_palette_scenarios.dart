part of '../game_renderer_keyboard_test.dart';

void _registerRendererActionPaletteSelectionPaletteScenarios() {
  test(
    'tapping the active unit marker dispatches a tile tap without direct focus',
    () async {
      final map = _map(3, 3);
      final commands = <GameIntent>[];
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 1,
        row: 1,
      );
      final game = GameRenderer(
        mapData: map,
        onCommand: (command) async => commands.add(command),
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(
          GameClientState(
            units: [commander],
            interaction: InteractionState(
              selection: GameSelection.unit(commander, tile: _tile(map, 1, 1)),
            ),
          ),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();
      game.camera.viewfinder
        ..zoom = 2
        ..position = Vector2(900, 700);
      final start = _visibleCenter(game).clone();

      game.world.children.whereType<UnitMarker>().single.onTap?.call();
      await Future<void>.delayed(Duration.zero);

      expect(commands, [const TileTappedCommand(1, 1)]);
      _expectVectorClose(_visibleCenter(game), start);

      game.update(1);

      _expectVectorClose(_visibleCenter(game), start);
    },
  );
  test(
    'tapping an enemy marker during attack targeting selects the target',
    () async {
      final map = _map(3, 1);
      final commands = <GameIntent>[];
      final attacker = GameUnit(
        id: 'attacker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 0,
      );
      final defender = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 1,
        row: 0,
      );
      final game = GameRenderer(
        mapData: map,
        onCommand: (command) async => commands.add(command),
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(
          GameClientState(
            activePlayerId: 'player_1',
            units: [attacker, defender],
            fogOfWar: FogOfWarState(
              players: {
                'player_1': PlayerFogOfWar(
                  playerId: 'player_1',
                  visibleHexes: {
                    const HexCoordinate(col: 0, row: 0),
                    const HexCoordinate(col: 1, row: 0),
                  },
                ),
              },
            ),
            interaction: InteractionState(
              selection: GameSelection.unit(attacker, tile: _tile(map, 0, 0)),
              pendingAction: const PendingAttackTargeting(
                ownerPlayerId: 'player_1',
                attackerUnitId: 'attacker_1',
              ),
            ),
          ),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      final defenderPosition = UnitMarkerLayer.worldPositionFor(1, 0);
      final defenderMarker = game.world.children
          .whereType<UnitMarker>()
          .singleWhere(
            (marker) => (marker.position - defenderPosition).length < 0.001,
          );

      defenderMarker.onTap?.call();
      await Future<void>.delayed(Duration.zero);

      expect(commands, [const TileTappedCommand(1, 0)]);
    },
  );
  test(
    'tapping a unit marker during move targeting dispatches a tile tap',
    () async {
      final map = _map(3, 2);
      final commands = <GameIntent>[];
      final commander = GameUnit.produced(
        id: 'commander_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.commander,
        col: 0,
        row: 0,
      );
      final unitOnTarget = GameUnit.produced(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        col: 1,
        row: 0,
      );
      final game = GameRenderer(
        mapData: map,
        onCommand: (command) async => commands.add(command),
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(
          GameClientState(
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
            units: [commander, unitOnTarget],
            fogOfWar: FogOfWarState(
              players: {
                'player_1': PlayerFogOfWar(
                  playerId: 'player_1',
                  visibleHexes: {
                    const HexCoordinate(col: 0, row: 0),
                    const HexCoordinate(col: 1, row: 0),
                  },
                ),
              },
            ),
            interaction: InteractionState(
              selection: GameSelection.unit(commander, tile: _tile(map, 0, 0)),
              moveCommandActive: true,
            ),
          ),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      final targetPosition = UnitMarkerLayer.worldPositionFor(1, 0);
      final marker = game.world.children.whereType<UnitMarker>().singleWhere(
        (marker) => (marker.position - targetPosition).length < 0.001,
      );

      marker.onTap?.call();
      await Future<void>.delayed(Duration.zero);

      expect(commands, [const TileTappedCommand(1, 0)]);
    },
  );
  test(
    'tapping a unit marker during city founding dispatches a tile tap',
    () async {
      final map = _map(3, 2);
      final commands = <GameIntent>[];
      final settler = GameUnit.produced(
        id: 'settler_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        col: 0,
        row: 0,
      );
      final unitOnTarget = GameUnit.produced(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        col: 1,
        row: 0,
      );
      final game = GameRenderer(
        mapData: map,
        onCommand: (command) async => commands.add(command),
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(
          GameClientState(
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
            units: [settler, unitOnTarget],
            fogOfWar: FogOfWarState(
              players: {
                'player_1': PlayerFogOfWar(
                  playerId: 'player_1',
                  visibleHexes: {
                    const HexCoordinate(col: 0, row: 0),
                    const HexCoordinate(col: 1, row: 0),
                  },
                ),
              },
            ),
            interaction: InteractionState(
              selection: GameSelection.unit(settler, tile: _tile(map, 0, 0)),
              cityFoundingDraft: CityFoundingDraft(
                unitId: 'settler_1',
                ownerPlayerId: 'player_1',
                center: const CityHex(col: 0, row: 0),
              ),
            ),
          ),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      final targetPosition = UnitMarkerLayer.worldPositionFor(1, 0);
      final marker = game.world.children.whereType<UnitMarker>().singleWhere(
        (marker) => (marker.position - targetPosition).length < 0.001,
      );

      marker.onTap?.call();
      await Future<void>.delayed(Duration.zero);

      expect(commands, [const TileTappedCommand(1, 0)]);
    },
  );
  test(
    'tapping a city marker during move targeting dispatches a tile tap',
    () async {
      final map = _map(3, 3);
      final commands = <GameIntent>[];
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 1, row: 1),
      );
      final commander = GameUnit.produced(
        id: 'commander_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.commander,
        col: 0,
        row: 0,
      );
      final game = GameRenderer(
        mapData: map,
        onCommand: (command) async => commands.add(command),
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(
          GameClientState(
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
            units: [commander],
            cities: const [city],
            fogOfWar: FogOfWarState(
              players: {
                'player_1': PlayerFogOfWar(
                  playerId: 'player_1',
                  visibleHexes: {
                    const HexCoordinate(col: 0, row: 0),
                    const HexCoordinate(col: 1, row: 1),
                  },
                ),
              },
            ),
            interaction: InteractionState(
              selection: GameSelection.unit(commander, tile: _tile(map, 0, 0)),
              moveCommandActive: true,
            ),
          ),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      game.world.children.whereType<CityMarker>().single.onTap?.call();
      await Future<void>.delayed(Duration.zero);

      expect(commands, [const TileTappedCommand(1, 1)]);
    },
  );
  test(
    'tapping a city marker during worker action selection dispatches a tile tap',
    () async {
      final map = _map(3, 3);
      final commands = <GameIntent>[];
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 1, row: 1),
      );
      final worker = GameUnit.produced(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        col: 0,
        row: 0,
      );
      final game = GameRenderer(
        mapData: map,
        onCommand: (command) async => commands.add(command),
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(
          GameClientState(
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
            units: [worker],
            cities: const [city],
            fogOfWar: FogOfWarState(
              players: {
                'player_1': PlayerFogOfWar(
                  playerId: 'player_1',
                  visibleHexes: {
                    const HexCoordinate(col: 0, row: 0),
                    const HexCoordinate(col: 1, row: 1),
                  },
                ),
              },
            ),
            interaction: InteractionState(
              selection: GameSelection.unit(worker, tile: _tile(map, 0, 0)),
              pendingAction: const PendingWorkerActionSelection(
                ownerPlayerId: 'player_1',
                unitId: 'worker_1',
              ),
            ),
          ),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      game.world.children.whereType<CityMarker>().single.onTap?.call();
      await Future<void>.delayed(Duration.zero);

      expect(commands, [const TileTappedCommand(1, 1)]);
    },
  );
  test('shows worker action palette during worker action selection', () async {
    final map = _map(3, 2);
    final worker = GameUnit.produced(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      col: 1,
      row: 0,
    );
    final game = GameRenderer(
      mapData: map,
      workerActionPaletteOptionsBuilder:
          ({
            required state,
            required worker,
            required pendingAction,
            required mapData,
          }) => const [
            ActionPaletteOption(
              id: 'farm',
              iconAtlasRow: 0,
              iconAtlasColumn: 0,
              label: 'Farm',
              yieldChips: [
                ActionPaletteYieldChip(
                  kind: ActionPaletteYieldKind.food,
                  value: 1,
                ),
              ],
              turns: 2,
              state: ActionPaletteOptionState.available,
              ctaLabel: 'ZBUDUJ',
            ),
          ],
      onCommand: (_) async {},
    );
    addTearDown(game.disposeRenderer);

    game
      ..applyState(
        GameClientState(
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          units: [worker],
          interaction: InteractionState(
            selection: GameSelection.unit(worker, tile: _tile(map, 1, 0)),
            pendingAction: const PendingWorkerActionSelection(
              ownerPlayerId: 'player_1',
              unitId: 'worker_1',
            ),
          ),
        ),
      )
      ..onGameResize(Vector2(800, 600));
    await game.onLoad();

    expect(game.actionPaletteVisibleForTesting, isTrue);
    expect(game.actionPaletteComponentForTesting?.optionsForTesting.length, 1);
    _expectVectorClose(
      game.actionPalettePositionForTesting!,
      UnitMarkerLayer.worldPositionFor(1, 0) + Vector2(0, -82),
    );
  });
}
