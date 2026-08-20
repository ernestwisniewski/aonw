part of '../game_hud_test.dart';

void _registerGameHudAiHandoffHumanHandbackScenarios() {
  testWidgets('single-player AI handback focuses the human ready unit', (
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
        'player_1': PlayerTurnState.finished,
        'player_2': PlayerTurnState.active,
      },
    );
    final commander = GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
      col: 0,
      row: 0,
    ).copyWith(movementPoints: 0);
    final aiCommander = GameUnit.startingCommander(
      ownerPlayerId: 'player_2',
      col: 2,
      row: 2,
    ).copyWith(movementPoints: 0);
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: save,
        state: GameClientState(
          units: [commander, aiCommander],
          activePlayerId: 'player_1',
          activePlayerCanAct: false,
          submittedPlayerIds: const {'player_1'},
        ),
      ),
    );
    final renderer = HudTestRenderer(mapData: hudMap());

    await pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      session: hudSession(hudMap(), gameMode: GameMode.multiplayer),
      renderer: renderer,
      aiAutopilotEnabled: true,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container.read(gameStateProvider('save').future);
    await tester.pump();

    await pumpUntil(tester, () {
      final state = container.read(gameStateProvider('save')).value;
      return repository.snapshot.save.turn > save.turn &&
          state?.selectedUnitId == commander.id;
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final state = container.read(gameStateProvider('save')).value;
    expect(repository.snapshot.save.turn, save.turn + 1);
    expect(state?.activePlayerId, 'player_1');
    expect(state?.activePlayerCanAct, isTrue);
    expect(state?.selectedUnitId, commander.id);
    expect(state?.moveCommandActive, isTrue);
    expect(
      renderer.handledEffects.whereType<SmoothCameraEffect>().any(
        (effect) => effect.col == commander.col && effect.row == commander.row,
      ),
      isTrue,
    );
  });
  testWidgets('AI handback focuses the human map start when research is next', (
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
        'player_1': PlayerTurnState.finished,
        'player_2': PlayerTurnState.active,
      },
    );
    final aiCommander = GameUnit.startingCommander(
      ownerPlayerId: 'player_2',
      col: 2,
      row: 2,
    ).copyWith(movementPoints: 0);
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: const CityHex(col: 0, row: 0),
      controlledHexes: const [CityHex(col: 0, row: 0)],
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 0,
      ),
    );
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: save,
        state: GameClientState(
          units: [aiCommander],
          cities: [city],
          activePlayerId: 'player_1',
          activePlayerCanAct: false,
          submittedPlayerIds: const {'player_1'},
        ),
      ),
    );
    final renderer = HudTestRenderer(mapData: hudMap());

    await pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      session: hudSession(hudMap(), gameMode: GameMode.multiplayer),
      renderer: renderer,
      aiAutopilotEnabled: true,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container.read(gameStateProvider('save').future);
    await tester.pump();

    await pumpUntil(tester, () {
      final state = container.read(gameStateProvider('save')).value;
      return repository.snapshot.save.turn > save.turn &&
          state?.pendingAction is PendingResearchSelection &&
          (state?.activePlayerCanAct ?? false);
    });
    await tester.pump();

    final state = container.read(gameStateProvider('save')).value;
    expect(repository.snapshot.save.turn, save.turn + 1);
    expect(state?.activePlayerId, 'player_1');
    expect(state?.activePlayerCanAct, isTrue);
    expect(state?.pendingAction, isA<PendingResearchSelection>());
    final smoothEffects = renderer.handledEffects
        .whereType<SmoothCameraEffect>()
        .toList(growable: false);
    expect(smoothEffects, isNotEmpty);
    expect(smoothEffects.last.col, city.center.col);
    expect(smoothEffects.last.row, city.center.row);
    await pumpUntil(
      tester,
      () => find.byType(TechnologyTreePanel).evaluate().isNotEmpty,
      frames: 8,
    );
    expect(find.byType(TechnologyTreePanel), findsOneWidget);

    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TechnologyTreePanel), findsOneWidget);
      expect(
        container.read(gameStateProvider('save')).value?.pendingAction,
        isA<PendingResearchSelection>(),
      );
    }
  });

  testWidgets('AI handback keeps city production open for a calm decision', (
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
        'player_1': PlayerTurnState.finished,
        'player_2': PlayerTurnState.active,
      },
    );
    final aiCommander = GameUnit.startingCommander(
      ownerPlayerId: 'player_2',
      col: 2,
      row: 2,
    ).copyWith(movementPoints: 0);
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 0, row: 0),
      controlledHexes: [CityHex(col: 0, row: 0)],
    );
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: save,
        state: GameClientState(
          units: [aiCommander],
          cities: const [city],
          activePlayerId: 'player_1',
          activePlayerCanAct: false,
          submittedPlayerIds: const {'player_1'},
        ),
      ),
    );

    await pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      session: hudSession(hudMap(), gameMode: GameMode.multiplayer),
      renderer: HudTestRenderer(mapData: hudMap()),
      aiAutopilotEnabled: true,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container.read(gameStateProvider('save').future);
    await tester.pump();

    await pumpUntil(
      tester,
      () =>
          repository.snapshot.save.turn > save.turn &&
          find.byType(CityProductionPanel).evaluate().isNotEmpty,
    );

    expect(find.byType(CityProductionPanel), findsOneWidget);
    expect(
      container.read(gameStateProvider('save')).value?.selection?.city?.id,
      city.id,
    );
    expect(
      container
          .read(gameStateProvider('save'))
          .value
          ?.cities
          .single
          .productionQueue,
      isNull,
    );

    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CityProductionPanel), findsOneWidget);
      expect(
        container.read(gameStateProvider('save')).value?.selection?.city?.id,
        city.id,
      );
    }
  });
}
