part of '../game_hud_test.dart';

void _registerGameHudAiHandoffMultiplayerChainScenarios() {
  testWidgets(
    'local multiplayer AI chain keeps camera and perspective on the human',
    (tester) async {
      final fixture = _createMultiplayerAiChainFixture();
      final save = fixture.save;
      final queuedUnit = fixture.queuedUnit!;
      final renderer = fixture.renderer;
      final repository = fixture.repository;

      await _pumpHud(
        tester,
        repository: repository,
        gameSave: save,
        session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
        renderer: renderer,
        aiAutopilotEnabled: true,
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      await _waitForMultiplayerAiChain(tester, container, fixture);

      expect(repository.snapshot.save.turn, save.turn + 1);
      expect(repository.snapshot.save.playerStates, const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
        'player_3': PlayerTurnState.active,
        'player_4': PlayerTurnState.active,
      });
      final control = container.read(gamePlayerControlControllerProvider);
      expect(control.activePlayerId, 'player_1');
      expect(control.canAct, isTrue);
      final state = container.read(gameStateProvider('save')).value;
      expect(state?.activePlayerId, 'player_1');
      expect(state?.activePlayerCanAct, isTrue);
      expect(
        state?.units.singleWhere((unit) => unit.id == queuedUnit.id).col,
        1,
      );
      expect(
        renderer.handledEffects.whereType<AnimateUnitMoveEffect>().map(
          (effect) => effect.unitId,
        ),
        contains(queuedUnit.id),
      );
      expect(
        renderer.appliedStates.map((state) => state.activePlayerId),
        isNot(contains(anyOf('player_2', 'player_3', 'player_4'))),
      );
    },
  );
  testWidgets('local multiplayer AI can submit before the human ends turn', (
    tester,
  ) async {
    final aiPlayer = _player2.copyWith(
      name: 'AI Bob',
      kind: PlayerKind.ai,
      ai: const AiPlayer(
        strategyId: AiStrategyId.random,
        difficulty: AiDifficulty.normal,
        persona: AiPersona.balanced,
        seed: 42,
      ),
    );
    final save = _save.copyWith(
      gameMode: GameMode.multiplayer,
      players: [_player, aiPlayer],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
    );
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: save,
        state: GameClientState(
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
      aiAutopilotEnabled: true,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container.read(gameStateProvider('save').future);
    await tester.pump();

    await _pumpUntil(tester, () {
      return repository.snapshot.save.playerStates['player_2'] ==
          PlayerTurnState.finished;
    });
    await tester.pump();

    expect(repository.snapshot.save.turn, save.turn);
    expect(repository.snapshot.save.playerStates, const {
      'player_1': PlayerTurnState.active,
      'player_2': PlayerTurnState.finished,
    });
    final control = container.read(gamePlayerControlControllerProvider);
    expect(control.activePlayerId, 'player_1');
    expect(control.canAct, isTrue);
    final state = container.read(gameStateProvider('save')).value;
    expect(state?.activePlayerId, 'player_1');
    expect(state?.activePlayerCanAct, isTrue);
  });
  testWidgets(
    'local multiplayer AI animates visible movement without exposing AI perspective',
    (tester) async {
      final aiPlayer = _player2.copyWith(
        name: 'AI Bob',
        kind: PlayerKind.ai,
        ai: const AiPlayer(
          strategyId: AiStrategyId.random,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
          seed: 7,
        ),
      );
      final save = _save.copyWith(
        gameMode: GameMode.multiplayer,
        players: [_player, aiPlayer],
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.active,
        },
      );
      final humanUnit = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 0,
        row: 0,
      ).copyWith(movementPoints: 0);
      final aiUnit = GameUnit.startingCommander(
        ownerPlayerId: 'player_2',
        col: 1,
        row: 1,
      ).copyWith(movementPoints: 2);
      final renderer = _SpyGameRenderer(mapData: _makeMap());
      final logger = _RecordingGameLogger();
      final eventLog = _FakeEventLog();
      final repository = _FakeGameRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: save,
          state: GameClientState(
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
            units: [humanUnit, aiUnit],
            fogOfWar: FogOfWarState(
              players: {
                'player_1': PlayerFogOfWar(
                  playerId: 'player_1',
                  visibleHexes: {
                    for (var row = 0; row < 3; row++)
                      for (var col = 0; col < 3; col++)
                        HexCoordinate(col: col, row: row),
                  },
                ),
              },
            ),
          ),
        ),
      );

      await _pumpHud(
        tester,
        repository: repository,
        gameSave: save,
        session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
        renderer: renderer,
        eventLog: eventLog,
        logger: logger,
        aiAutopilotEnabled: true,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await container.read(gameStateProvider('save').future);
      await tester.pump();

      await _pumpUntil(tester, () {
        return renderer.handledEffects.whereType<AnimateUnitMoveEffect>().any(
          (effect) => effect.unitId == aiUnit.id,
        );
      }, frames: 10);
      await tester.pump(const Duration(milliseconds: 250));
      await _pumpUntil(tester, () {
        return repository.snapshot.save.playerStates['player_2'] ==
            PlayerTurnState.finished;
      }, frames: 10);
      await tester.pump();

      expect(
        logger.warnings,
        isEmpty,
        reason: logger.warnings
            .map(
              (warning) =>
                  '${warning.tag}: ${warning.message}: ${warning.error}',
            )
            .join('\n'),
      );
      expect(
        eventLog.commands.map((command) => command.command.runtimeType),
        contains(SubmitTurnCommand),
      );
      expect(repository.snapshot.save.turn, save.turn);
      expect(
        repository.snapshot.save.playerStates['player_2'],
        PlayerTurnState.finished,
      );
      expect(
        renderer.handledEffects.whereType<AnimateUnitMoveEffect>().map(
          (effect) => effect.unitId,
        ),
        contains(aiUnit.id),
      );
      expect(
        renderer.appliedStates.map((state) => state.activePlayerId),
        everyElement('player_1'),
      );
      expect(
        renderer.appliedStates.map((state) => state.activePlayerCanAct),
        everyElement(isTrue),
      );
      final state = container.read(gameStateProvider('save')).value;
      expect(state?.activePlayerId, 'player_1');
      expect(state?.activePlayerCanAct, isTrue);
    },
  );
}
