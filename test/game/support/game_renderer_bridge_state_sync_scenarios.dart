part of '../game_renderer_keyboard_test.dart';

void _registerRendererStateSyncScenarios() {
  test('applyState publishes renderer state to visual test accessors', () {
    final map = _map(3, 3);
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final preview = UnitMovementPlan(
      unitId: commander.id,
      targetCol: 1,
      targetRow: 0,
      totalCost: 1,
      availableMovementPoints: commander.movementPoints,
      steps: const [
        UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
        UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      ],
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {})
      ..applyState(
        GameClientState(
          units: [commander],
          activePlayerId: 'player_1',
          interaction: InteractionState(
            selection: GameSelection.unit(commander, tile: _tile(map, 0, 0)),
            moveCommandActive: true,
            movePreview: preview,
          ),
        ),
      );

    expect(game.unitsForTesting, [commander]);
    expect(game.viewModelListenable.value.selection?.unit?.id, commander.id);
    expect(game.moveCommandActiveForTesting, isTrue);
    expect(game.movePreviewTargetForTesting, (col: 1, row: 0));
    expect(game.movePreviewCostForTesting, 1);
  });

  test('tile view marks city territory overlay as strategic', () async {
    final map = _map(3, 3);
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 1, row: 0)],
    );
    final game = GameRenderer(
      mapData: map,
      initialViewMode: MapViewMode.graphic,
      onCommand: (_) async {},
    );
    addTearDown(game.disposeRenderer);

    game
      ..onGameResize(Vector2(800, 600))
      ..applyState(GameClientState(cities: [city]));
    await game.onLoad();

    expect(game.cityTerritoryStrategicViewForTesting, isFalse);

    game.viewMode = MapViewMode.tile;

    expect(game.cityTerritoryStrategicViewForTesting, isTrue);
  });

  test('strengthens city territory overlay when zooming out', () async {
    final map = _map(3, 3);
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 1, row: 0)],
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    addTearDown(game.disposeRenderer);

    game
      ..onGameResize(Vector2(800, 600))
      ..applyState(GameClientState(cities: [city]));
    await game.onLoad();

    game.setZoom(1);
    final closeEmphasis = game.cityTerritoryZoomEmphasisForTesting;

    game.setZoom(0.35);

    expect(closeEmphasis, 0);
    expect(game.cityTerritoryZoomEmphasisForTesting, 1);
  });

  test('publishes zoom changes for the performance debug overlay', () async {
    final map = _map(3, 3);
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    addTearDown(game.disposeRenderer);

    game.onGameResize(Vector2(800, 600));
    await game.onLoad();

    game.setZoom(0.75);

    expect(game.zoomListenable.value, closeTo(0.75, 0.0001));
  });

  test('skips marker density sync for tiny same-bucket zoom deltas', () async {
    final map = _map(3, 3);
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    addTearDown(game.disposeRenderer);

    game.onGameResize(Vector2(800, 600));
    await game.onLoad();

    game
      ..setZoom(1.2)
      ..onGameResize(Vector2(800, 600));
    final initialSyncCount = game.markerDensitySyncCountForTesting;
    expect(game.markerDensityLastSyncedZoomForTesting, closeTo(1.2, 0.001));

    game.setZoom(1.19);

    expect(game.markerDensitySyncCountForTesting, initialSyncCount);

    game.setZoom(1.16);

    expect(game.markerDensitySyncCountForTesting, initialSyncCount + 1);
  });

  test('uses fast image rendering while panning the camera', () async {
    final map = _map(3, 3);
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    addTearDown(game.disposeRenderer);

    game.onGameResize(Vector2(800, 600));
    await game.onLoad();

    expect(game.imageLayerPrefersFastRenderingForTesting, isFalse);

    game.panByScreenDelta(Vector2(24, 0));
    expect(game.imageLayerPrefersFastRenderingForTesting, isTrue);

    game
      ..update(0)
      ..update(0.13);

    expect(game.imageLayerPrefersFastRenderingForTesting, isFalse);
  });

  test('queues renderer effects until the Flame world is ready', () async {
    final map = _map(3, 3);
    final game = GameRenderer(
      mapData: map,
      startCameraOffMap: true,
      onCommand: (_) async {},
    );
    addTearDown(game.disposeRenderer);

    await game.handleEffect(const JumpCameraEffect(col: 1, row: 1));
    game.onGameResize(Vector2(800, 600));
    await game.onLoad();

    expect(game.camera.viewfinder.position.x, isNot(-100000));
    expect(game.camera.viewfinder.position.y, isNot(-100000));
  });
}
