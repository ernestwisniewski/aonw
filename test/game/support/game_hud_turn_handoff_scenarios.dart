part of '../game_hud_test.dart';

void _registerGameHudTurnHandoffScenarios() {
  testWidgets(
    'hotseat handoff stays visible while confirmation prepares turn',
    (tester) async {
      final repository = _FakeGameRepository();
      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      container
          .read(gameHandoffProvider.notifier)
          .setPending(
            const HandoffData(
              playerId: 'player_1',
              playerName: 'Alice',
              playerColorValue: 0xFF4a7fc4,
              turnNumber: 1,
              freshTurn: true,
            ),
          );
      await _setActivePlayerWaiting(container);
      await tester.pump();
      for (var i = 0; i < 5 && find.text('ALICE').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('ALICE'), findsOneWidget);
      final gate = Completer<void>();
      repository.loadGate = gate;

      await tester.tap(find.text('CONTINUE'));
      await tester.pump();

      expect(find.text('ALICE'), findsOneWidget);
      expect(gate.isCompleted, isFalse);

      gate.complete();
      await _pumpUntil(
        tester,
        () => find.text('ALICE').evaluate().isEmpty,
        frames: 8,
      );
      expect(find.text('ALICE'), findsNothing);
    },
  );

  testWidgets('hotseat handoff prepares turn start after player confirms', (
    tester,
  ) async {
    final save = _save.copyWith(
      turn: 3,
      players: const [_player, _player2],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
    );
    final unit = GameUnit.produced(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      col: 0,
      row: 0,
    );
    final otherUnit = GameUnit.produced(
      id: 'warrior_2',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      col: 2,
      row: 2,
    );
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: save,
        state: GameClientState(
          units: [unit, otherUnit],
          activePlayerId: 'player_2',
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
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container.read(gameStateProvider('save').future);
    final gate = Completer<void>();
    repository.loadGate = gate;
    container
        .read(gameHandoffProvider.notifier)
        .setPending(
          const HandoffData(
            playerId: 'player_1',
            playerName: 'Alice',
            playerColorValue: 0xFF4a7fc4,
            turnNumber: 3,
            freshTurn: true,
          ),
        );
    await _setActivePlayerWaiting(container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(container.read(gameHandoffProvider)?.playerId, 'player_1');
    expect(find.text('ALICE'), findsOneWidget);
    expect(
      container.read(gameStateProvider('save')).value?.selectedUnitId,
      isNull,
    );

    expect(gate.isCompleted, isFalse);

    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    expect(find.text('ALICE'), findsOneWidget);
    expect(gate.isCompleted, isFalse);

    gate.complete();
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 40; i++) {
        final state = container.read(gameStateProvider('save')).value;
        if (state?.selectedUnitId == 'warrior_1') break;
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pump();

    expect(find.text('ALICE'), findsNothing);
    final preparedState = container.read(gameStateProvider('save')).value;
    expect(preparedState?.activePlayerId, 'player_1');
    expect(preparedState?.activePlayerCanAct, isTrue);
    expect(preparedState?.selectedUnitId, 'warrior_1');
    expect(
      renderer.handledEffects.whereType<SmoothCameraEffect>().any(
        (effect) => effect.col == unit.col && effect.row == unit.row,
      ),
      isTrue,
    );
    final smoothCameraEffectCount = renderer.handledEffects
        .whereType<SmoothCameraEffect>()
        .length;

    final state = container.read(gameStateProvider('save')).value;
    expect(state?.activePlayerId, 'player_1');
    expect(state?.activePlayerCanAct, isTrue);
    expect(state?.selectedUnitId, 'warrior_1');
    expect(state?.moveCommandActive, isTrue);
    expect(
      renderer.handledEffects.whereType<SmoothCameraEffect>().length,
      smoothCameraEffectCount,
    );
  });

  testWidgets(
    'hotseat handoff to third human in four-player game waits for confirm before camera focus',
    (tester) async {
      const player3 = Player(
        id: 'player_3',
        name: 'Cora',
        colorValue: 0xFF70a45d,
      );
      const player4 = Player(
        id: 'player_4',
        name: 'Dale',
        colorValue: 0xFFb8854f,
      );
      final save = _save.copyWith(
        turn: 5,
        players: const [_player, _player2, player3, player4],
        playerStates: const {
          'player_1': PlayerTurnState.finished,
          'player_2': PlayerTurnState.finished,
          'player_3': PlayerTurnState.active,
          'player_4': PlayerTurnState.active,
        },
      );
      final previousUnit = GameUnit.produced(
        id: 'warrior_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 0,
        row: 2,
      );
      final thirdPlayerUnit = GameUnit.produced(
        id: 'warrior_3',
        ownerPlayerId: 'player_3',
        type: GameUnitType.warrior,
        col: 2,
        row: 1,
      );
      final fourthPlayerUnit = GameUnit.produced(
        id: 'warrior_4',
        ownerPlayerId: 'player_4',
        type: GameUnitType.warrior,
        col: 1,
        row: 2,
      );
      final repository = _FakeGameRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: save,
          state: GameClientState(
            units: [previousUnit, thirdPlayerUnit, fourthPlayerUnit],
            activePlayerId: 'player_2',
            activePlayerCanAct: false,
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
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await container.read(gameStateProvider('save').future);

      container
          .read(gameHandoffProvider.notifier)
          .setPending(
            const HandoffData(
              playerId: 'player_3',
              playerName: 'Cora',
              playerColorValue: 0xFF70a45d,
              turnNumber: 5,
            ),
          );
      await tester.pump();

      expect(find.text('CORA'), findsOneWidget);
      expect(renderer.handledEffects.whereType<SmoothCameraEffect>(), isEmpty);

      await tester.tap(find.text('CONTINUE'));
      await _pumpUntil(
        tester,
        () =>
            container.read(gameStateProvider('save')).value?.selectedUnitId ==
            thirdPlayerUnit.id,
        frames: 12,
      );

      expect(find.text('CORA'), findsNothing);
      final state = container.read(gameStateProvider('save')).value;
      expect(state?.activePlayerId, 'player_3');
      expect(state?.activePlayerCanAct, isTrue);
      expect(state?.selectedUnitId, thirdPlayerUnit.id);
      expect(
        renderer.handledEffects.whereType<SmoothCameraEffect>().any(
          (effect) =>
              effect.col == thirdPlayerUnit.col &&
              effect.row == thirdPlayerUnit.row,
        ),
        isTrue,
      );
    },
  );

  testWidgets('hotseat start focuses the next actionable object', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
    );
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(cities: [city], activePlayerId: 'player_1'),
      ),
    );

    await _pumpHud(tester, repository: repository, showEntryHandoff: true);
    await tester.pump();

    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    final state = container.read(gameStateProvider('save')).value;
    expect(state?.selection?.city?.id, 'city_1');
  });

  testWidgets('hotseat start prioritizes a movable unit over stale selection', (
    tester,
  ) async {
    final unit = GameUnit.produced(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      col: 0,
      row: 0,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
    );
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(
          units: [unit],
          cities: const [city],
          activePlayerId: 'player_1',
          interaction: InteractionState(
            selection: GameSelection.city(
              city,
              cityYield: TileYield.zero,
              playerColor: 0xFF4a7fc4,
            ),
          ),
        ),
      ),
    );

    await _pumpHud(tester, repository: repository, showEntryHandoff: true);
    await tester.pump();

    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    final state = container.read(gameStateProvider('save')).value;
    expect(state?.selectedUnitId, 'warrior_1');
    expect(state?.moveCommandActive, isTrue);
  });

  testWidgets('hotseat start does not focus a city with queued production', (
    tester,
  ) async {
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: const CityHex(col: 1, row: 1),
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 0,
      ),
    );
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(
          cities: [city],
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

    await _pumpHud(tester, repository: repository, showEntryHandoff: true);
    await tester.pump();

    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    final state = container.read(gameStateProvider('save')).value;
    expect(state?.selection?.city, isNull);
    expect(state?.pendingAction, isNull);
  });
}
