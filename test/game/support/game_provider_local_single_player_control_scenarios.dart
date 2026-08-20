part of '../game_providers_test.dart';

void _registerGameProviderLocalSinglePlayerControlScenarios() {
  test('resume derives local single-player planning and resolving phases', () {
    final planningSave = _makeSave(
      players: const [_player1, _localAiPlayer],
      gameMode: GameMode.multiplayer,
    );
    final planningContainer = ProviderContainer(
      overrides: [
        gamePlayerControlSaveProvider.overrideWithValue(planningSave),
      ],
    );
    addTearDown(planningContainer.dispose);

    final planning = planningContainer.read(
      gamePlayerControlControllerProvider,
    );
    expect(planning.phase, LocalSinglePlayerTurnPhase.humanPlanning);
    expect(planning.canInteract, isTrue);

    final resolvingSave = _makeSave(
      players: const [_player1, _localAiPlayer],
      playerStates: const {
        'player_1': PlayerTurnState.finished,
        'ai_1': PlayerTurnState.active,
      },
      gameMode: GameMode.multiplayer,
    );
    final resolvingContainer = ProviderContainer(
      overrides: [
        gamePlayerControlSaveProvider.overrideWithValue(resolvingSave),
      ],
    );
    addTearDown(resolvingContainer.dispose);

    final resolving = resolvingContainer.read(
      gamePlayerControlControllerProvider,
    );
    expect(resolving.phase, LocalSinglePlayerTurnPhase.aiResolving);
    expect(resolving.canAct, isFalse);
    expect(resolving.canInteract, isFalse);
  });

  test(
    'prepare keeps domain control ready but blocks input until release',
    () async {
      final save = _makeSave(
        players: const [_player1, _localAiPlayer],
        gameMode: GameMode.multiplayer,
      );
      final gameRepository = _FakeGameRepository(
        snapshots: {save.id: _makeSnapshot(save: save)},
      );
      final container = ProviderContainer(
        overrides: [
          gamePlayerControlSaveProvider.overrideWithValue(save),
          activeGameSessionProvider.overrideWithValue(
            _makeSession(
              mapData: _makeLandMap(),
              gameMode: GameMode.multiplayer,
            ),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          ..._transportOverrides(),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        gameStateProvider(save.id),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(gameStateProvider(save.id).future);

      final controller = container.read(
        gamePlayerControlControllerProvider.notifier,
      )..beginTurnOpening('player_1');
      var control = container.read(gamePlayerControlControllerProvider);
      expect(control.phase, LocalSinglePlayerTurnPhase.turnOpening);
      expect(control.canInteract, isFalse);

      await controller.prepareHumanTurn('player_1');

      control = container.read(gamePlayerControlControllerProvider);
      expect(control.canAct, isTrue);
      expect(control.phase, LocalSinglePlayerTurnPhase.turnOpening);
      expect(control.canInteract, isFalse);
      expect(
        container.read(gameStateProvider(save.id)).value!.activePlayerCanAct,
        isTrue,
      );

      controller.syncWithSave(save);
      control = container.read(gamePlayerControlControllerProvider);
      expect(control.phase, LocalSinglePlayerTurnPhase.turnOpening);

      await controller.releaseHumanTurn('player_1');
      control = container.read(gamePlayerControlControllerProvider);
      expect(control.phase, LocalSinglePlayerTurnPhase.humanPlanning);
      expect(control.canInteract, isTrue);
    },
  );

  test('release uses the authoritative save loaded during prepare', () async {
    final scopedSave = _makeSave(
      players: const [_player1, _localAiPlayer],
      playerStates: const {
        'player_1': PlayerTurnState.finished,
        'ai_1': PlayerTurnState.active,
      },
      gameMode: GameMode.multiplayer,
    );
    final authoritativeSave = _makeSave(
      turn: 2,
      players: const [_player1, _localAiPlayer],
      gameMode: GameMode.multiplayer,
    );
    final gameRepository = _FakeGameRepository(
      snapshots: {authoritativeSave.id: _makeSnapshot(save: authoritativeSave)},
    );
    final container = ProviderContainer(
      overrides: [
        gamePlayerControlSaveProvider.overrideWithValue(scopedSave),
        activeGameSessionProvider.overrideWithValue(
          _makeSession(mapData: _makeLandMap(), gameMode: GameMode.multiplayer),
        ),
        gameRepositoryProvider.overrideWithValue(gameRepository),
        ..._transportOverrides(),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      gameStateProvider(scopedSave.id),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(gameStateProvider(scopedSave.id).future);

    final controller = container.read(
      gamePlayerControlControllerProvider.notifier,
    )..beginTurnOpening('player_1');
    await controller.prepareHumanTurn('player_1');
    await controller.releaseHumanTurn('player_1');

    final control = container.read(gamePlayerControlControllerProvider);
    expect(control.phase, LocalSinglePlayerTurnPhase.humanPlanning);
    expect(control.canAct, isTrue);
    expect(control.canInteract, isTrue);
  });

  test('release fallback restores input when opening fails early', () async {
    final scopedSave = _makeSave(
      players: const [_player1, _localAiPlayer],
      playerStates: const {
        'player_1': PlayerTurnState.finished,
        'ai_1': PlayerTurnState.active,
      },
      gameMode: GameMode.multiplayer,
    );
    final gameRepository = _FakeGameRepository(
      snapshots: {scopedSave.id: _makeSnapshot(save: scopedSave)},
    );
    final container = ProviderContainer(
      overrides: [
        gamePlayerControlSaveProvider.overrideWithValue(scopedSave),
        activeGameSessionProvider.overrideWithValue(
          _makeSession(mapData: _makeLandMap(), gameMode: GameMode.multiplayer),
        ),
        gameRepositoryProvider.overrideWithValue(gameRepository),
        ..._transportOverrides(),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      gameStateProvider(scopedSave.id),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(gameStateProvider(scopedSave.id).future);

    final controller = container.read(
      gamePlayerControlControllerProvider.notifier,
    )..beginTurnOpening('player_1');
    await controller.releaseHumanTurn('player_1');

    final control = container.read(gamePlayerControlControllerProvider);
    expect(control.phase, LocalSinglePlayerTurnPhase.humanPlanning);
    expect(control.canAct, isTrue);
    expect(control.canInteract, isTrue);
  });

  test('turn-opening lease only lets its owner cancel the barrier', () {
    final save = _makeSave(
      players: const [_player1, _localAiPlayer],
      gameMode: GameMode.multiplayer,
    );
    final container = ProviderContainer(
      overrides: [gamePlayerControlSaveProvider.overrideWithValue(save)],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      gamePlayerControlControllerProvider.notifier,
    );
    const owner1 = TurnOpeningLease(
      saveId: 'save_1',
      sourceTurn: 1,
      executionPlayerId: 'ai_1',
      generation: 1,
    );
    const owner2 = TurnOpeningLease(
      saveId: 'save_1',
      sourceTurn: 1,
      executionPlayerId: 'ai_1',
      generation: 2,
    );

    controller.beginTurnOpening('player_1', lease: owner1);
    expect(controller.cancelTurnOpening(owner1), isTrue);
    expect(
      container.read(gamePlayerControlControllerProvider).phase,
      LocalSinglePlayerTurnPhase.humanPlanning,
    );

    controller
      ..beginTurnOpening('player_1', lease: owner1)
      ..beginTurnOpening('player_1', lease: owner2);
    expect(controller.cancelTurnOpening(owner1), isFalse);
    expect(
      container.read(gamePlayerControlControllerProvider).phase,
      LocalSinglePlayerTurnPhase.turnOpening,
    );
    expect(controller.cancelTurnOpening(owner2), isTrue);
    expect(
      container.read(gamePlayerControlControllerProvider).phase,
      LocalSinglePlayerTurnPhase.humanPlanning,
    );
  });

  test(
    'local single-player end turn blocks duplicate input immediately',
    () async {
      final save = _makeSave(
        players: const [_player1, _localAiPlayer],
        gameMode: GameMode.multiplayer,
      );
      final reloadGate = Completer<void>();
      final saves = {save.id: save};
      final gameRepository = _FakeGameRepository(
        saves: saves,
        loadGate: reloadGate,
      );
      final container = ProviderContainer(
        overrides: [
          gamePlayerControlSaveProvider.overrideWithValue(save),
          activeGameSessionProvider.overrideWithValue(
            _makeSession(
              mapData: _makeLandMap(),
              gameMode: GameMode.multiplayer,
            ),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          ..._transportOverrides(),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        gamePlayerControlControllerProvider.notifier,
      );

      final endTurn = controller.endTurn(save);
      final resolving = container.read(gamePlayerControlControllerProvider);
      expect(resolving.phase, LocalSinglePlayerTurnPhase.aiResolving);
      expect(resolving.canInteract, isFalse);
      expect(await controller.endTurn(save), isNull);

      reloadGate.complete();
      final updated = await endTurn;
      expect(updated, isNotNull);
      final finished = container.read(gamePlayerControlControllerProvider);
      expect(finished.phase, LocalSinglePlayerTurnPhase.aiResolving);
      expect(finished.canAct, isFalse);
      expect(finished.canInteract, isFalse);

      final nextTurnSave = _makeSave(
        turn: 2,
        players: const [_player1, _localAiPlayer],
        gameMode: GameMode.multiplayer,
      );
      controller.syncWithSave(nextTurnSave);
      final published = container.read(gamePlayerControlControllerProvider);
      expect(published.canAct, isTrue);
      expect(published.phase, LocalSinglePlayerTurnPhase.aiResolving);
      expect(published.canInteract, isFalse);

      controller.beginTurnOpening('player_1');
      final opening = container.read(gamePlayerControlControllerProvider);
      expect(opening.phase, LocalSinglePlayerTurnPhase.turnOpening);
      expect(opening.canInteract, isFalse);
    },
  );

  test('failed local single-player end turn restores human input', () async {
    final save = _makeSave(
      players: const [_player1, _localAiPlayer],
      gameMode: GameMode.multiplayer,
    );
    final container = ProviderContainer(
      overrides: [
        gamePlayerControlSaveProvider.overrideWithValue(save),
        activeGameSessionProvider.overrideWithValue(
          _makeSession(mapData: _makeLandMap(), gameMode: GameMode.multiplayer),
        ),
        gameRepositoryProvider.overrideWithValue(
          _FakeGameRepository(throwOnLoad: true),
        ),
        ..._transportOverrides(),
      ],
    );
    addTearDown(container.dispose);

    final updated = await container
        .read(gamePlayerControlControllerProvider.notifier)
        .endTurn(save);

    expect(updated, isNull);
    final control = container.read(gamePlayerControlControllerProvider);
    expect(control.phase, LocalSinglePlayerTurnPhase.humanPlanning);
    expect(control.canAct, isTrue);
    expect(control.canInteract, isTrue);
  });
}
