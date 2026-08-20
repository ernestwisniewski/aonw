part of '../game_hud_test.dart';

void _registerGameHudAiHandoffMultiplayerChainScenarios() {
  testWidgets(
    'local single-player AI chain keeps camera and perspective on the human',
    (tester) async {
      final fixture = createMultiplayerAiChainFixture();
      final save = fixture.save;
      final queuedUnit = fixture.queuedUnit!;
      final renderer = fixture.renderer;
      final repository = fixture.repository;

      await pumpHud(
        tester,
        repository: repository,
        gameSave: save,
        session: hudSession(hudMap(), gameMode: GameMode.multiplayer),
        renderer: renderer,
        aiAutopilotEnabled: true,
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      await waitForMultiplayerAiChain(tester, container, fixture);

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
      expect(control.canInteract, isTrue);
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
  testWidgets('local single-player AI waits for the human submission', (
    tester,
  ) async {
    final aiPlayer = hudPlayer2.copyWith(
      name: 'AI Bob',
      kind: PlayerKind.ai,
      ai: const AiPlayer(
        strategyId: AiStrategyId.random,
        difficulty: AiDifficulty.normal,
        persona: AiPersona.balanced,
        seed: 42,
      ),
    );
    final save = hudSave.copyWith(
      gameMode: GameMode.multiplayer,
      players: [hudPlayer, aiPlayer],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
    );
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: save,
        state: GameClientState(
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
      ),
    );

    await pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      session: hudSession(hudMap(), gameMode: GameMode.multiplayer),
      aiAutopilotEnabled: true,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container.read(gameStateProvider('save').future);
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 500));

    expect(repository.snapshot.save.turn, save.turn);
    expect(repository.snapshot.save.playerStates, const {
      'player_1': PlayerTurnState.active,
      'player_2': PlayerTurnState.active,
    });

    GameSave? submittedSave;
    var endTurnCompleted = false;
    final endTurn = container
        .read(gamePlayerControlControllerProvider.notifier)
        .endTurn(repository.snapshot.save)
        .then((value) => submittedSave = value)
        .whenComplete(() => endTurnCompleted = true);
    await pumpUntil(tester, () => endTurnCompleted);
    await endTurn;
    expect(submittedSave, isNotNull);

    await pumpHud(
      tester,
      repository: repository,
      gameSave: submittedSave,
      session: hudSession(hudMap(), gameMode: GameMode.multiplayer),
      aiAutopilotEnabled: true,
    );

    await pumpUntil(tester, () {
      return repository.snapshot.save.turn > save.turn;
    });
    await tester.pump();

    expect(repository.snapshot.save.turn, save.turn + 1);
    expect(repository.snapshot.save.playerStates, const {
      'player_1': PlayerTurnState.active,
      'player_2': PlayerTurnState.active,
    });
    final control = container.read(gamePlayerControlControllerProvider);
    expect(control.activePlayerId, 'player_1');
    expect(control.canAct, isTrue);
    expect(control.canInteract, isTrue);
    final state = container.read(gameStateProvider('save')).value;
    expect(state?.activePlayerId, 'player_1');
    expect(state?.activePlayerCanAct, isTrue);
  });

  testWidgets('end turn immediately shows waiting and ignores a second tap', (
    tester,
  ) async {
    final aiPlayer = hudPlayer2.copyWith(
      name: 'AI Bob',
      kind: PlayerKind.ai,
      ai: const AiPlayer(
        strategyId: AiStrategyId.random,
        difficulty: AiDifficulty.normal,
        persona: AiPersona.balanced,
        seed: 42,
      ),
    );
    final save = hudSave.copyWith(
      gameMode: GameMode.multiplayer,
      players: [hudPlayer, aiPlayer],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
    );
    final eventLog = FakeHudEventLog();
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: save,
        state: GameClientState(
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
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

    await pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      session: hudSession(hudMap(), gameMode: GameMode.multiplayer),
      eventLog: eventLog,
      aiAutopilotEnabled: false,
    );
    await tester.pump();

    final loadGate = Completer<void>();
    repository.loadGate = loadGate;
    await tester.tap(find.byType(EndTurnButton));
    await tester.pump();

    expect(find.text('WAITING'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    expect(
      container.read(gamePlayerControlControllerProvider).canInteract,
      isFalse,
    );

    await tester.tap(find.text('WAITING'), warnIfMissed: false);
    await tester.pump();
    loadGate.complete();
    await pumpUntil(
      tester,
      () => eventLog.commands
          .where((entry) => entry.command is SubmitTurnCommand)
          .isNotEmpty,
    );

    expect(
      eventLog.commands.where((entry) => entry.command is SubmitTurnCommand),
      hasLength(1),
    );
  });

  testWidgets(
    'local single-player direct turn advance completes turn opening',
    (tester) async {
      final aiPlayer = hudPlayer2.copyWith(
        name: 'AI Bob',
        kind: PlayerKind.ai,
        ai: const AiPlayer(
          strategyId: AiStrategyId.random,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
          seed: 42,
        ),
      );
      final save = hudSave.copyWith(
        gameMode: GameMode.multiplayer,
        players: [hudPlayer, aiPlayer],
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.finished,
        },
      );
      final repository = FakeHudRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: save,
          state: GameClientState(
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
          ),
        ),
      );

      await pumpHud(
        tester,
        repository: repository,
        gameSave: save,
        session: hudSession(hudMap(), gameMode: GameMode.multiplayer),
        aiAutopilotEnabled: false,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await container.read(gameStateProvider('save').future);
      await tester.pump();

      final animatingUnitIds = ValueNotifier(const <String>{});
      addTearDown(animatingUnitIds.dispose);
      var endTurnCompleted = false;
      final endTurn = container
          .read(hudCommandDispatcherProvider)
          .endTurn(
            animatingUnitIdsListenable: animatingUnitIds,
            gameSave: save,
            activePlayerId: 'player_1',
            readyToEndTurn: true,
            currentState: () => container.read(gameStateProvider('save')).value,
          )
          .whenComplete(() => endTurnCompleted = true);
      await pumpUntil(tester, () => endTurnCompleted);
      await endTurn;

      expect(repository.snapshot.save.turn, save.turn + 1);
      final control = container.read(gamePlayerControlControllerProvider);
      expect(control.activePlayerId, 'player_1');
      expect(control.canAct, isTrue);
      expect(control.canInteract, isTrue);
      final state = container.read(gameStateProvider('save')).value;
      expect(state?.activePlayerId, 'player_1');
      expect(state?.activePlayerCanAct, isTrue);
    },
  );

  testWidgets(
    'local single-player AI animates visible movement after human submission',
    (tester) async {
      final fixture = _visibleAiMovementFixture();
      final save = fixture.save;
      final aiUnit = fixture.aiUnit;
      final renderer = fixture.renderer;
      final logger = fixture.logger;
      final eventLog = fixture.eventLog;
      final repository = fixture.repository;

      await pumpHud(
        tester,
        repository: repository,
        gameSave: save,
        session: hudSession(hudMap(), gameMode: GameMode.multiplayer),
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

      await tester.pump(const Duration(milliseconds: 500));

      expect(
        renderer.handledEffects.whereType<AnimateUnitMoveEffect>(),
        isEmpty,
      );
      expect(
        repository.snapshot.save.playerStates['player_2'],
        PlayerTurnState.active,
      );

      GameSave? submittedSave;
      var endTurnCompleted = false;
      final endTurn = container
          .read(gamePlayerControlControllerProvider.notifier)
          .endTurn(repository.snapshot.save)
          .then((value) => submittedSave = value)
          .whenComplete(() => endTurnCompleted = true);
      await pumpUntil(tester, () => endTurnCompleted);
      await endTurn;
      expect(submittedSave, isNotNull);

      await pumpHud(
        tester,
        repository: repository,
        gameSave: submittedSave,
        session: hudSession(hudMap(), gameMode: GameMode.multiplayer),
        renderer: renderer,
        eventLog: eventLog,
        logger: logger,
        aiAutopilotEnabled: true,
      );

      await pumpUntil(tester, () {
        return renderer.handledEffects.whereType<AnimateUnitMoveEffect>().any(
          (effect) => effect.unitId == aiUnit.id,
        );
      }, frames: 10);
      await tester.pump(const Duration(milliseconds: 250));
      await pumpUntil(tester, () {
        return repository.snapshot.save.turn > save.turn;
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
      expect(repository.snapshot.save.turn, save.turn + 1);
      expect(
        repository.snapshot.save.playerStates['player_2'],
        PlayerTurnState.active,
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
        containsAllInOrder(const [false, true]),
      );
      final state = container.read(gameStateProvider('save')).value;
      expect(state?.activePlayerId, 'player_1');
      expect(state?.activePlayerCanAct, isTrue);
    },
  );
}

({
  GameSave save,
  GameUnit aiUnit,
  HudTestRenderer renderer,
  HudTestLogger logger,
  FakeHudEventLog eventLog,
  FakeHudRepository repository,
})
_visibleAiMovementFixture() {
  final aiPlayer = hudPlayer2.copyWith(
    name: 'AI Bob',
    kind: PlayerKind.ai,
    ai: const AiPlayer(
      strategyId: AiStrategyId.random,
      difficulty: AiDifficulty.normal,
      persona: AiPersona.balanced,
      seed: 7,
    ),
  );
  final save = hudSave.copyWith(
    gameMode: GameMode.multiplayer,
    players: [hudPlayer, aiPlayer],
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
  final renderer = HudTestRenderer(mapData: hudMap());
  final logger = HudTestLogger();
  final eventLog = FakeHudEventLog();
  final repository = FakeHudRepository(
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
  return (
    save: save,
    aiUnit: aiUnit,
    renderer: renderer,
    logger: logger,
    eventLog: eventLog,
    repository: repository,
  );
}
