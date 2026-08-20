part of '../game_renderer_keyboard_test.dart';

void _registerRendererTransitionFocusSelectionScenarios() {
  test(
    'keeps the initial active player centered when the viewport arrives late',
    () async {
      final map = kbMap(3, 3);
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 1,
        row: 1,
      );
      final game = GameRenderer(
        mapData: map,
        focusActivePlayerOnFirstState: true,
        initialCamera: CameraState.zero,
        onCommand: (_) async {},
      );
      addTearDown(game.disposeRenderer);
      expect(game.initialCameraFocusReadyListenable.value, isFalse);

      game
        ..applyState(
          GameClientState(units: [commander], activePlayerId: 'player_1'),
        )
        ..onGameResize(Vector2.zero());
      await game.onLoad();
      expect(game.initialCameraFocusReadyListenable.value, isFalse);
      game.onGameResize(Vector2(800, 600));
      expect(game.initialCameraFocusReadyListenable.value, isTrue);

      _expectVectorClose(
        _visibleCenter(game),
        UnitMarkerLayer.worldPositionFor(1, 1),
      );
    },
  );
  final initialFocusMap = kbMap(3, 3);
  final initialFocusCommander = GameUnit.startingCommander(
    ownerPlayerId: 'player_1',
    col: 1,
    row: 1,
  );
  final switchMap = kbMap(3, 3);
  final switchCommander = GameUnit.startingCommander(
    ownerPlayerId: 'player_1',
    col: 0,
    row: 0,
  );
  final switchSettler = GameUnit(
    id: 'settler_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.settler,
    name: GameUnitType.settler.defaultNameToken,
    col: 1,
    row: 0,
  );
  final focusMap = kbMap(3, 3);
  final focusCommander = GameUnit.startingCommander(
    ownerPlayerId: 'player_1',
    col: 1,
    row: 1,
  );
  final noCameraMap = kbMap(3, 3);
  final noCameraCommander = GameUnit.startingCommander(
    ownerPlayerId: 'player_1',
    col: 1,
    row: 1,
  );

  test(
    'applies new-game initial focus after restoring the zero camera',
    () async {
      final game =
          GameRenderer(
            mapData: initialFocusMap,
            focusActivePlayerOnFirstState: true,
            initialCamera: CameraState.zero,
            onCommand: (_) async {},
          )..applyState(
            GameClientState(
              units: [initialFocusCommander],
              activePlayerId: 'player_1',
            ),
          );
      await gameRendererFlameTester.initialize(game);

      expect(game.initialCameraFocusReadyListenable.value, isTrue);
      _expectVectorClose(
        _visibleCenter(game),
        UnitMarkerLayer.worldPositionFor(1, 1),
      );
    },
  );
  test(
    'switches selection from a later unit to an earlier unit without key conflicts',
    () async {
      final game = GameRenderer(mapData: switchMap, onCommand: (_) async {})
        ..applyState(
          GameClientState(
            activePlayerId: 'player_1',
            units: [switchCommander, switchSettler],
            interaction: InteractionState(
              selection: GameSelection.unit(
                switchSettler,
                tile: kbTile(switchMap, 1, 0),
              ),
            ),
          ),
        );
      await gameRendererFlameTester.initialize(game);
      game
        ..update(0)
        ..applyState(
          GameClientState(
            activePlayerId: 'player_1',
            units: [switchCommander, switchSettler],
            interaction: InteractionState(
              selection: GameSelection.unit(
                switchCommander,
                tile: kbTile(switchMap, 0, 0),
              ),
            ),
          ),
        );

      expect(() => game.update(0), returnsNormally);
    },
  );
  test(
    'smoothly focuses newly selected unit at marker center for current zoom',
    () async {
      final game = GameRenderer(mapData: focusMap, onCommand: (_) async {})
        ..applyState(GameClientState(units: [focusCommander]));
      await gameRendererFlameTester.initialize(game);
      game.camera.viewfinder
        ..zoom = 2
        ..position = Vector2(900, 700);
      final start = _visibleCenter(game).clone();
      final target = UnitMarkerLayer.worldPositionFor(1, 1);

      game.applyState(
        GameClientState(
          units: [focusCommander],
          interaction: InteractionState(
            selection: GameSelection.unit(
              focusCommander,
              tile: kbTile(focusMap, 1, 1),
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
  test('can update selection without moving the camera', () async {
    final game = GameRenderer(mapData: noCameraMap, onCommand: (_) async {})
      ..applyState(GameClientState(units: [noCameraCommander]));
    await gameRendererFlameTester.initialize(game);
    game.camera.viewfinder
      ..zoom = 2
      ..position = Vector2(900, 700);
    final start = _visibleCenter(game).clone();

    game.applyStateWithoutCameraFocus(
      GameClientState(
        units: [noCameraCommander],
        interaction: InteractionState(
          selection: GameSelection.unit(
            noCameraCommander,
            tile: kbTile(noCameraMap, 1, 1),
          ),
        ),
      ),
    );

    _expectVectorClose(_visibleCenter(game), start);
  });
}
