part of '../game_renderer_keyboard_test.dart';

void _registerRendererTransitionMovementScenarios() {
  test('camera effects ignore remembered fog targets', () async {
    final map = kbMap(4, 1);
    final game = GameRenderer(mapData: map, onCommand: (_) async {})
      ..applyState(
        GameClientState(
          activePlayerId: 'player_1',
          fogOfWar: _fog(
            discovered: {const HexCoordinate(col: 3, row: 0)},
            visible: {const HexCoordinate(col: 0, row: 0)},
          ),
        ),
      );
    await gameRendererFlameTester.initialize(game);
    await game.handleEffect(const JumpCameraEffect(col: 0, row: 0));
    final before = _visibleCenter(game).clone();

    await game.handleEffect(const JumpCameraEffect(col: 3, row: 0));

    _expectVectorClose(_visibleCenter(game), before);
  });
  test('smooth camera effect animates toward the target tile', () async {
    final map = kbMap(4, 4);
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    await gameRendererFlameTester.initialize(game);

    final start = _visibleCenter(game).clone();
    final target = UnitMarkerLayer.worldPositionFor(2, 2);
    final future = game.handleEffect(
      const SmoothCameraEffect(col: 2, row: 2, duration: 1),
    );
    await Future<void>.delayed(Duration.zero);

    game.update(0.25);
    final mid = _visibleCenter(game);
    expect((mid - start).length, greaterThan(0));
    expect((mid - target).length, greaterThan(1));
    expect(game.fastCameraRenderingForTesting, isTrue);

    game.update(1);
    await future;

    _expectVectorClose(_visibleCenter(game), target);

    game.update(0.13);

    expect(game.fastCameraRenderingForTesting, isFalse);
  });
  test(
    'combat animation focuses the retained killed attacker marker',
    () async {
      final map = kbMap(4, 4);
      final attacker = GameUnit.produced(
        id: 'attacker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 1,
        row: 1,
      );
      final defender = GameUnit.produced(
        id: 'defender_1',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 2,
        row: 1,
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});

      await gameRendererFlameTester.initializeWithState(
        game,
        GameClientState(units: [attacker, defender]),
      );
      game.camera.viewfinder
        ..zoom = 2
        ..position = Vector2(900, 700);
      final attackPoint = game.unitMarkerPositionForTesting(attacker.id)!;

      final transition = game.applyTransition(
        GameClientState(
          units: [defender],
          interaction: InteractionState(
            selection: GameSelection.unit(defender, tile: kbTile(map, 2, 1)),
          ),
        ),
        const [
          PlayCombatAnimationEffect(
            attackerUnitId: 'attacker_1',
            defenderUnitId: 'defender_1',
            attackerKilled: true,
          ),
        ],
      );
      await Future<void>.delayed(Duration.zero);

      _expectVectorClose(_visibleCenter(game), attackPoint);

      game
        ..update(0.4)
        ..update(0.4);
      await transition;
      expect(game.unitMarkerPositionForTesting(attacker.id), isNull);
    },
  );
  test('unit move effect centers camera on start without tracking', () async {
    final map = kbMap(4, 1);
    final unit = GameUnit.produced(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      col: 0,
      row: 0,
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {});

    await gameRendererFlameTester.initializeWithState(
      game,
      GameClientState(units: [unit]),
    );
    await game.handleEffect(const JumpCameraEffect(col: 3, row: 0));

    final moveFuture = game.handleEffect(
      const AnimateUnitMoveEffect(
        unitId: 'warrior_1',
        fromCol: 0,
        fromRow: 0,
        steps: [
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    game.update(0.32);
    await Future<void>.delayed(Duration.zero);
    expect(game.animatingUnitIdsListenable.value, contains(unit.id));
    final cameraCenterAfterFocus = _visibleCenter(game).clone();

    game.update(0.3);
    final markerPosition = game.unitMarkerPositionForTesting(unit.id)!;
    _expectVectorClose(_visibleCenter(game), cameraCenterAfterFocus);
    expect((_visibleCenter(game) - markerPosition).length, greaterThan(8));

    game
      ..update(0.3)
      ..update(0.6)
      ..update(0.6);
    await Future<void>.delayed(Duration.zero);
    await moveFuture;

    _expectVectorClose(_visibleCenter(game), cameraCenterAfterFocus);
  });
  test('serializes overlapping unit move transitions', () async {
    final map = kbMap(4, 1);
    final unit = GameUnit.produced(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      col: 0,
      row: 0,
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {});

    await gameRendererFlameTester.initializeWithState(
      game,
      GameClientState(units: [unit]),
    );

    var firstCompleted = false;
    var secondCompleted = false;
    final first = game
        .applyTransition(
          GameClientState(units: [unit.copyWith(col: 1, row: 0)]),
          const [
            AnimateUnitMoveEffect(
              unitId: 'warrior_1',
              fromCol: 0,
              fromRow: 0,
              steps: [
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
              ],
            ),
          ],
        )
        .then((_) {
          firstCompleted = true;
        });
    final second = game
        .applyTransition(
          GameClientState(units: [unit.copyWith(col: 2, row: 0)]),
          const [
            AnimateUnitMoveEffect(
              unitId: 'warrior_1',
              fromCol: 1,
              fromRow: 0,
              steps: [
                UnitMovementStep(
                  col: 2,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
              ],
            ),
          ],
        )
        .then((_) {
          secondCompleted = true;
        });
    await Future<void>.delayed(Duration.zero);

    expect(firstCompleted, isFalse);
    expect(secondCompleted, isFalse);

    game
      ..update(0.3)
      ..update(0.4);
    await first.timeout(const Duration(seconds: 1));

    expect(firstCompleted, isTrue);
    expect(secondCompleted, isFalse);
    expect(game.animatingUnitIdsListenable.value, contains(unit.id));

    game.update(0.7);
    await second.timeout(const Duration(seconds: 1));

    expect(secondCompleted, isTrue);
    _expectVectorClose(
      game.unitMarkerPositionForTesting(unit.id)!,
      UnitMarkerLayer.worldPositionFor(2, 0),
    );
  });
  test('hidden unit move effect does not move the camera', () async {
    final map = kbMap(5, 1);
    final hiddenEnemy = GameUnit.produced(
      id: 'enemy_1',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      col: 3,
      row: 0,
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {});

    await gameRendererFlameTester.initializeWithState(
      game,
      GameClientState(units: [hiddenEnemy], activePlayerId: 'player_1'),
    );
    await game.handleEffect(const JumpCameraEffect(col: 0, row: 0));
    final before = _visibleCenter(game).clone();

    await game.handleEffect(
      const AnimateUnitMoveEffect(
        unitId: 'enemy_1',
        fromCol: 3,
        fromRow: 0,
        steps: [
          UnitMovementStep(col: 4, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
      ),
    );

    _expectVectorClose(_visibleCenter(game), before);
  });
  test('animates visible enemy movement before it leaves vision', () async {
    final map = kbMap(3, 1);
    final enemy = GameUnit.produced(
      id: 'enemy_1',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      col: 0,
      row: 0,
    );
    final game = GameRenderer(mapData: map, onCommand: (_) async {});
    final fog = _fog(visible: {const HexCoordinate(col: 0, row: 0)});

    await gameRendererFlameTester.initializeWithState(
      game,
      GameClientState(
        activePlayerId: 'player_1',
        fogOfWar: fog,
        units: [enemy],
      ),
    );

    expect(game.unitMarkerPositionForTesting(enemy.id), isNotNull);

    final transition = game.applyTransition(
      GameClientState(
        activePlayerId: 'player_1',
        fogOfWar: fog,
        units: [enemy.copyWith(col: 1, row: 0)],
      ),
      const [
        AnimateUnitMoveEffect(
          unitId: 'enemy_1',
          fromCol: 0,
          fromRow: 0,
          steps: [
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          ],
        ),
      ],
    );
    await Future<void>.delayed(Duration.zero);

    expect(game.animatingUnitIdsListenable.value, contains(enemy.id));
    _expectVectorClose(
      game.unitMarkerPositionForTesting(enemy.id)!,
      UnitMarkerLayer.worldPositionFor(0, 0),
    );

    game.update(0.7);
    await transition.timeout(const Duration(seconds: 1));

    expect(game.unitMarkerPositionForTesting(enemy.id), isNull);
  });
  test('focuses the active player when the first state is applied', () async {
    final map = kbMap(3, 3);
    final commander = GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
      col: 1,
      row: 1,
    );
    final game = GameRenderer(
      mapData: map,
      focusActivePlayerOnFirstState: true,
      onCommand: (_) async {},
    );

    await gameRendererFlameTester.initializeWithState(
      game,
      GameClientState(units: [commander], activePlayerId: 'player_1'),
    );

    expect(game.camera.viewfinder.position.x, isNot(0));
    expect(game.camera.viewfinder.position.y, isNot(0));
  });
  test('can hand camera follow to a selected replay perspective', () async {
    final map = kbMap(5, 5);
    final playerOneUnit = GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
      col: 0,
      row: 0,
    );
    final playerTwoUnit = GameUnit.startingCommander(
      ownerPlayerId: 'player_2',
      col: 3,
      row: 3,
    );
    final game = GameRenderer(
      mapData: map,
      focusActivePlayerOnFirstState: true,
      onCommand: (_) async {},
    );

    await gameRendererFlameTester.initializeWithState(
      game,
      GameClientState(
        activePlayerId: 'player_1',
        units: [playerOneUnit, playerTwoUnit],
      ),
    );
    _expectVectorClose(
      _visibleCenter(game),
      UnitMarkerLayer.worldPositionFor(0, 0),
    );

    expect(game.followPlayerCamera('player_2', immediate: true), isTrue);
    _expectVectorClose(
      _visibleCenter(game),
      UnitMarkerLayer.worldPositionFor(3, 3),
    );

    final movedPlayerTwoUnit = playerTwoUnit.copyWith(col: 4, row: 4);
    game
      ..applyStateWithoutCameraFocus(
        GameClientState(
          activePlayerId: 'player_2',
          units: [playerOneUnit, movedPlayerTwoUnit],
        ),
      )
      ..update(0.5);

    _expectVectorClose(
      _visibleCenter(game),
      UnitMarkerLayer.worldPositionFor(4, 4),
      tolerance: 12,
    );
  });
}
