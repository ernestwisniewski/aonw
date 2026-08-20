part of '../game_hud_test.dart';

void _registerGameHudOutcomeScoreProjectionScenarios() {
  testWidgets(
    'top resource strip shows turn, resources and domination status',
    (tester) async {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
      );
      final repository = FakeHudRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: hudSave,
          state: GameClientState(
            activePlayerId: 'player_1',
            cities: [city],
            playerGold: {'player_1': 17},
          ),
        ),
      );

      await pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();

      final goldFinder = find.byKey(const Key('gameHud.resource.gold'));
      final scienceFinder = find.byKey(const Key('gameHud.resource.science'));
      final resourcesFinder = find.byKey(
        const Key('gameHud.resource.resources'),
      );
      final identityFinder = find.byKey(const Key('gameHud.resource.identity'));
      final turnFinder = find.byKey(const Key('gameHud.resource.turn'));
      final victoryFinder = find.byKey(const Key('gameHud.victoryStatus'));

      expect(identityFinder, findsNothing);
      expect(goldFinder, findsOneWidget);
      expect(scienceFinder, findsOneWidget);
      expect(resourcesFinder, findsOneWidget);
      expect(turnFinder, findsOneWidget);
      expect(victoryFinder, findsOneWidget);
      expect(find.text('Alice · T2'), findsNothing);
      expect(find.text('T2'), findsOneWidget);
      expect(find.textContaining('DOM'), findsOneWidget);
      expect(
        find.descendant(of: goldFinder, matching: find.text('17')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: scienceFinder, matching: find.text('+2')),
        findsOneWidget,
      );

      final hudWidth = tester.getSize(find.byType(GameHud)).width;
      final goldRect = tester.getRect(goldFinder);
      final scienceRect = tester.getRect(scienceFinder);
      final resourcesRect = tester.getRect(resourcesFinder);
      final turnRect = tester.getRect(turnFinder);
      final victoryRect = tester.getRect(victoryFinder);

      expect(goldRect.top, lessThan(50));
      expect(scienceRect.top, lessThan(50));
      expect(resourcesRect.top, lessThan(50));
      expect(turnRect.top, lessThan(50));
      expect(victoryRect.top, lessThan(50));
      expect(scienceRect.left, greaterThan(goldRect.right));
      expect(resourcesRect.left, greaterThan(scienceRect.right));
      expect(turnRect.left, greaterThan(resourcesRect.right));
      expect(victoryRect.left, greaterThan(turnRect.right));
      expect((scienceRect.center.dy - goldRect.center.dy).abs(), lessThan(1));
      expect((resourcesRect.center.dy - goldRect.center.dy).abs(), lessThan(1));
      expect((turnRect.center.dy - goldRect.center.dy).abs(), lessThan(1));
      expect((victoryRect.center.dy - goldRect.center.dy).abs(), lessThan(1));
      expect(victoryRect.right, lessThan(hudWidth - 8));
    },
  );
  testWidgets('top resource strip shows score cap and current leader', (
    tester,
  ) async {
    final turnLimit = GameLengthConfig.standard60.turnLimit!;
    final save = hudSave.copyWith(
      turn: turnLimit - 5,
      matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
      players: const [hudPlayer, hudPlayer2],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
    );
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: save,
        state: GameClientState(
          activePlayerId: 'player_1',
          cities: const [city],
          units: [
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 0,
              row: 0,
            ),
            GameUnit.produced(
              id: 'warrior_2',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: 2,
              row: 2,
            ),
          ],
        ),
      ),
    );

    await pumpHud(tester, repository: repository, gameSave: save);
    await tester.pump();

    final victoryFinder = find.byKey(const Key('gameHud.victoryStatus'));

    expect(victoryFinder, findsOneWidget);
    expect(
      find.descendant(
        of: victoryFinder,
        matching: find.textContaining('SCORE 5T'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: victoryFinder,
        matching: find.textContaining('ALICE'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('globalHud.action.objectives')),
        matching: find.text('PTS'),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Tooltip &&
            (widget.message?.contains('lead defense') ?? false),
      ),
      findsWidgets,
    );
  });
  testWidgets(
    'score pressure links the score badge, objectives overview and action marker',
    (tester) async {
      final turnLimit = GameLengthConfig.standard60.turnLimit!;
      final save = hudSave.copyWith(
        turn: turnLimit - 5,
        matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
        players: const [hudPlayer, hudPlayer2],
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.active,
        },
      );
      const activeCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
      );
      const leaderCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Rywal',
        center: CityHex(col: 2, row: 2),
      );
      final repository = FakeHudRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: save,
          state: GameClientState(
            activePlayerId: 'player_1',
            cities: const [activeCity, leaderCity],
            units: [
              GameUnit.produced(
                id: 'warrior_1',
                ownerPlayerId: 'player_1',
                type: GameUnitType.warrior,
                col: 0,
                row: 0,
              ),
              GameUnit.produced(
                id: 'warrior_2',
                ownerPlayerId: 'player_2',
                type: GameUnitType.warrior,
                col: 2,
                row: 2,
              ),
              GameUnit.produced(
                id: 'warrior_3',
                ownerPlayerId: 'player_2',
                type: GameUnitType.warrior,
                col: 2,
                row: 1,
              ),
            ],
          ),
        ),
      );

      await pumpHud(tester, repository: repository, gameSave: save);
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const Key('globalHud.action.objectives')),
          matching: find.text('PTS'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('globalHud.action.objectives')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.text('OBJECTIVES'), findsOneWidget);
      expect(find.text('SCORE PRESSURE'), findsOneWidget);
      expect(find.text('Top priority: Catch the score leader'), findsOneWidget);
      expect(find.textContaining('Score gap'), findsWidgets);
    },
  );
  testWidgets('outcome overlay shows conquest victory and returns to menu', (
    tester,
  ) async {
    var closed = false;
    final save = hudSave.copyWith(
      players: const [hudPlayer, hudPlayer2],
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
          units: [
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 0,
              row: 0,
            ),
          ],
        ),
      ),
    );

    await pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      onClose: () => closed = true,
    );
    await tester.pump();

    expect(find.byKey(const Key('gameHud.outcomeOverlay')), findsOneWidget);
    expect(find.text('VICTORY'), findsOneWidget);
    expect(find.text('CONQUEST'), findsOneWidget);
    expect(find.textContaining('Alice'), findsWidgets);

    await tester.tap(find.byKey(const Key('gameHud.outcome.returnToMenu')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(closed, isTrue);
    expect(repository.savedCamera, isNotNull);
  });
  testWidgets('outcome overlay shows defeat for the active losing player', (
    tester,
  ) async {
    final save = hudSave.copyWith(
      players: const [hudPlayer, hudPlayer2],
      playerStates: const {
        'player_1': PlayerTurnState.finished,
        'player_2': PlayerTurnState.active,
      },
    );
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: save,
        state: GameClientState(
          activePlayerId: 'player_2',
          units: [
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 0,
              row: 0,
            ),
          ],
        ),
      ),
    );

    await pumpHud(tester, repository: repository, gameSave: save);
    await tester.pump();

    expect(find.byKey(const Key('gameHud.outcomeOverlay')), findsOneWidget);
    expect(find.text('DEFEAT'), findsOneWidget);
    expect(find.text('CONQUEST'), findsOneWidget);
    expect(find.textContaining('Alice'), findsWidgets);
  });
  testWidgets(
    'local single-player mode still shows victory without a network match',
    (tester) async {
      final aiPlayer = hudPlayer2.copyWith(
        kind: PlayerKind.ai,
        ai: const AiPlayer(
          strategyId: AiStrategyId.random,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
          seed: 42,
        ),
      );
      final localMode = NewGameFlow.singlePlayer.gameMode;
      final save = hudSave.copyWith(
        gameMode: localMode,
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
            units: [
              GameUnit.produced(
                id: 'warrior_1',
                ownerPlayerId: 'player_1',
                type: GameUnitType.warrior,
                col: 0,
                row: 0,
              ),
            ],
          ),
        ),
      );

      expect(NewGameFlow.singlePlayer.startsLocally, isTrue);
      expect(localMode, GameMode.multiplayer);
      await pumpHud(
        tester,
        repository: repository,
        gameSave: save,
        session: hudSession(hudMap(), gameMode: localMode),
      );
      await tester.pump();

      expect(find.byKey(const Key('gameHud.outcomeOverlay')), findsOneWidget);
      expect(find.text('VICTORY'), findsOneWidget);
      expect(find.text('COMPLETE'), findsNothing);
      expect(find.text('CONQUEST'), findsOneWidget);
    },
  );
}
