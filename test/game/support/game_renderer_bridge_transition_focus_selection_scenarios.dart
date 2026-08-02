part of '../game_renderer_keyboard_test.dart';

void _registerRendererTransitionFocusSelectionScenarios() {
  test(
    'keeps the initial active player centered when the viewport arrives late',
    () async {
      final map = _map(3, 3);
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
  test(
    'applies new-game initial focus after restoring the zero camera',
    () async {
      final map = _map(3, 3);
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
      game
        ..applyState(
          GameClientState(units: [commander], activePlayerId: 'player_1'),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

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
      final map = _map(3, 3);
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 0,
        row: 0,
      );
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        name: GameUnitType.settler.defaultNameToken,
        col: 1,
        row: 0,
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..applyState(
          GameClientState(
            activePlayerId: 'player_1',
            units: [commander, settler],
            interaction: InteractionState(
              selection: GameSelection.unit(settler, tile: _tile(map, 1, 0)),
            ),
          ),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();
      game
        ..update(0)
        ..applyState(
          GameClientState(
            activePlayerId: 'player_1',
            units: [commander, settler],
            interaction: InteractionState(
              selection: GameSelection.unit(commander, tile: _tile(map, 0, 0)),
            ),
          ),
        );

      expect(() => game.update(0), returnsNormally);
    },
  );
  test(
    'smoothly focuses newly selected unit at marker center for current zoom',
    () async {
      final map = _map(3, 3);
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 1,
        row: 1,
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..applyState(GameClientState(units: [commander]))
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();
      game.camera.viewfinder
        ..zoom = 2
        ..position = Vector2(900, 700);
      final start = _visibleCenter(game).clone();
      final target = UnitMarkerLayer.worldPositionFor(1, 1);

      game.applyState(
        GameClientState(
          units: [commander],
          interaction: InteractionState(
            selection: GameSelection.unit(commander, tile: _tile(map, 1, 1)),
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
    final map = _map(3, 3);
    final commander = GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
      col: 1,
      row: 1,
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    addTearDown(game.disposeRenderer);

    game
      ..applyState(GameClientState(units: [commander]))
      ..onGameResize(Vector2(800, 600));
    await game.onLoad();
    game.camera.viewfinder
      ..zoom = 2
      ..position = Vector2(900, 700);
    final start = _visibleCenter(game).clone();

    game.applyStateWithoutCameraFocus(
      GameClientState(
        units: [commander],
        interaction: InteractionState(
          selection: GameSelection.unit(commander, tile: _tile(map, 1, 1)),
        ),
      ),
    );

    _expectVectorClose(_visibleCenter(game), start);
  });
}
