part of '../game_hud_test.dart';

void _registerGameHudAiHandoffEntryAndManualScenarios() {
  testWidgets('hotseat entry shows handoff before turn start preparation', (
    tester,
  ) async {
    await _pumpHud(
      tester,
      repository: _FakeGameRepository(),
      showEntryHandoff: true,
    );
    for (var i = 0; i < 5 && find.text('ALICE').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('ALICE'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
  });
  testWidgets('hotseat entry skips handoff for AI players', (tester) async {
    final save = _save.copyWith(players: const [_aiPlayer]);

    await _pumpHud(
      tester,
      repository: _FakeGameRepository(
        snapshot: GameSnapshotFactory.create(save: save),
      ),
      gameSave: save,
      showEntryHandoff: true,
    );

    expect(find.text('AI RANDOM'), findsNothing);
    expect(find.text('CONTINUE'), findsNothing);
  });
  testWidgets('hotseat autopilot ends AI turn and requests human handoff', (
    tester,
  ) async {
    final save = _save.copyWith(
      players: const [_aiPlayer, _player2],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
    );
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: save,
        state: GameClientState(activePlayerId: 'player_1'),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      aiAutopilotEnabled: true,
    );
    await _pumpUntil(tester, () {
      return repository.snapshot.save.playerStates['player_1'] ==
          PlayerTurnState.finished;
    });
    await tester.pump();
    for (var i = 0; i < 5 && find.text('BOB').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(
      repository.snapshot.save.playerStates['player_1'],
      PlayerTurnState.finished,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    final control = container.read(gamePlayerControlControllerProvider);
    expect(control.activePlayerId, 'player_1');

    final state = container.read(gameStateProvider('save')).value;
    expect(state?.activePlayerId, isNot('player_2'));
    expect(find.text('BOB'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);

    await tester.tap(find.text('CONTINUE'));
    await _pumpUntil(
      tester,
      () =>
          container.read(gameStateProvider('save')).value?.activePlayerId ==
          'player_2',
      frames: 8,
    );

    final confirmedControl = container.read(
      gamePlayerControlControllerProvider,
    );
    expect(confirmedControl.activePlayerId, 'player_2');
    expect(confirmedControl.canAct, isTrue);

    final confirmedState = container.read(gameStateProvider('save')).value;
    expect(confirmedState?.activePlayerId, 'player_2');
    expect(confirmedState?.activePlayerCanAct, isTrue);
    expect(find.text('BOB'), findsNothing);
  });
  testWidgets(
    'manual hotseat end turn waits for handoff confirmation before renderer presentation',
    (tester) async {
      final save = _save.copyWith(
        players: const [_player, _player2],
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
            research: ResearchState(
              players: {
                'player_1': PlayerResearchState(
                  activeTechnologyId: TechnologyId.agriculture,
                ),
              },
            ),
          ),
        ),
      );
      final renderer = _SpyGameRenderer(mapData: _makeMap());

      await _pumpHud(
        tester,
        repository: repository,
        gameSave: save,
        renderer: renderer,
      );
      await tester.pump();
      renderer.appliedStates.clear();
      renderer.handledEffects.clear();

      await tester.tap(find.byType(EndTurnButton));
      await _pumpUntil(
        tester,
        () => find.text('BOB').evaluate().isNotEmpty,
        frames: 8,
      );

      expect(find.text('BOB'), findsOneWidget);
      expect(renderer.appliedStates, isEmpty);
      expect(renderer.handledEffects, isEmpty);

      await tester.tap(find.text('CONTINUE'));
      await _pumpUntil(
        tester,
        () => _readGameState(tester)?.activePlayerId == 'player_2',
        frames: 8,
      );

      expect(renderer.appliedStates, isNotEmpty);
      expect(_readGameState(tester)?.activePlayerId, 'player_2');
    },
  );
  testWidgets(
    'auto hotseat end turn waits for handoff confirmation before renderer presentation',
    (tester) async {
      final save = _save.copyWith(
        players: const [_player, _player2],
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
            research: ResearchState(
              players: {
                'player_1': PlayerResearchState(
                  activeTechnologyId: TechnologyId.agriculture,
                ),
              },
            ),
          ),
        ),
      );
      final renderer = _SpyGameRenderer(mapData: _makeMap());

      await _pumpHud(
        tester,
        repository: repository,
        gameSave: save,
        renderer: renderer,
      );
      await tester.pump();
      renderer.appliedStates.clear();
      renderer.handledEffects.clear();

      await _enableAutoTurnFlow(tester);
      await _pumpUntil(
        tester,
        () => find.text('BOB').evaluate().isNotEmpty,
        frames: 8,
      );

      expect(find.text('BOB'), findsOneWidget);
      expect(renderer.appliedStates, isEmpty);
      expect(renderer.handledEffects, isEmpty);

      await tester.tap(find.text('CONTINUE'));
      await _pumpUntil(
        tester,
        () => _readGameState(tester)?.activePlayerId == 'player_2',
        frames: 8,
      );

      expect(renderer.appliedStates, isNotEmpty);
      expect(_readGameState(tester)?.activePlayerId, 'player_2');
    },
  );
  testWidgets(
    'hotseat autopilot chains multiple AI players without exposing AI fog',
    (tester) async {
      final fixture = _createHotseatAiChainFixture();
      final save = fixture.save;
      final renderer = fixture.renderer;
      final repository = fixture.repository;

      await _pumpHud(
        tester,
        repository: repository,
        gameSave: save,
        renderer: renderer,
        aiAutopilotEnabled: true,
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      expect(
        container.read(gamePlayerControlControllerProvider).activePlayerId,
        'player_1',
      );
      expect(
        container.read(gamePlayerControlControllerProvider).canAct,
        isFalse,
      );
      expect(
        container.read(gameStateProvider('save')).value?.activePlayerId,
        'player_1',
      );
      expect(
        container.read(gameStateProvider('save')).value?.activePlayerCanAct,
        isFalse,
      );

      await _waitForHotseatAiChain(tester, container, fixture);

      expect(repository.snapshot.save.playerStates, const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
        'player_3': PlayerTurnState.active,
        'player_4': PlayerTurnState.active,
      });
      expect(repository.snapshot.save.turn, save.turn + 1);
      expect(container.read(gameHandoffProvider)?.playerId, 'player_1');
      await _pumpUntil(
        tester,
        () => find.text('ALICE').evaluate().isNotEmpty,
        frames: 8,
      );
      expect(find.text('ALICE'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);

      var chainedControl = container.read(gamePlayerControlControllerProvider);
      expect(chainedControl.activePlayerId, 'player_1');
      expect(chainedControl.canAct, isFalse);

      var chainedState = container.read(gameStateProvider('save')).value;
      expect(chainedState?.activePlayerId, 'player_1');
      expect(chainedState?.activePlayerCanAct, isFalse);
      expect(
        renderer.appliedStates.map((state) => state.activePlayerId),
        isNot(contains(anyOf('player_2', 'player_3', 'player_4'))),
      );

      await tester.tap(find.text('CONTINUE'));
      await _pumpUntil(tester, () {
        final state = container.read(gameStateProvider('save')).value;
        final control = container.read(gamePlayerControlControllerProvider);
        return (state?.activePlayerCanAct ?? false) && control.canAct;
      }, frames: 8);

      chainedControl = container.read(gamePlayerControlControllerProvider);
      expect(chainedControl.activePlayerId, 'player_1');
      expect(chainedControl.canAct, isTrue);

      chainedState = container.read(gameStateProvider('save')).value;
      expect(chainedState?.activePlayerId, 'player_1');
      expect(chainedState?.activePlayerCanAct, isTrue);
      expect(find.text('ALICE'), findsNothing);
      expect(
        renderer.appliedStates.map((state) => state.activePlayerId),
        isNot(contains(anyOf('player_2', 'player_3', 'player_4'))),
      );
    },
  );
}
