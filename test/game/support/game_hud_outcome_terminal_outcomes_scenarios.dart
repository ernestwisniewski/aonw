part of '../game_hud_test.dart';

void _registerGameHudOutcomeTerminalOutcomesScenarios() {
  testWidgets(
    'terminal multiplayer outcome uses network player perspective with projected state',
    (tester) async {
      final save = hudSave.copyWith(
        gameMode: GameMode.multiplayer,
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
            playerGold: const {'player_2': 0},
            units: [
              GameUnit.produced(
                id: 'warrior_1',
                ownerPlayerId: 'player_1',
                type: GameUnitType.warrior,
                col: 0,
                row: 0,
              ),
            ],
            fogOfWar: FogOfWarState(
              players: {
                'player_2': PlayerFogOfWar(
                  playerId: 'player_2',
                  visibleHexes: {const HexCoordinate(col: 0, row: 0)},
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
        networkSession: NetworkSession(
          userId: 'user_2',
          playerId: 'player_2',
          token: AuthToken('token'),
          matchId: save.id,
        ),
        multiplayerMatch: terminalMatch(
          outcomeCondition: 'conquest',
          winnerPlayerId: 'player_1',
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('gameHud.outcomeOverlay')), findsOneWidget);
      expect(find.text('DEFEAT'), findsOneWidget);
      expect(find.text('CONQUEST'), findsOneWidget);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.text('VICTORY'), findsNothing);
    },
  );
  testWidgets('remaining player sees victory after authoritative resignation', (
    tester,
  ) async {
    final save = hudSave.copyWith(
      gameMode: GameMode.multiplayer,
      players: const [hudPlayer, hudPlayer2],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.finished,
      },
    );
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: save,
        state: GameClientState(
          activePlayerId: 'player_2',
          playerGold: const {'player_1': 0},
          fogOfWar: FogOfWarState(
            players: {'player_1': PlayerFogOfWar(playerId: 'player_1')},
          ),
        ),
      ),
    );

    await pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      session: hudSession(hudMap(), gameMode: GameMode.multiplayer),
      networkSession: NetworkSession(
        userId: 'user_1',
        playerId: 'player_1',
        token: AuthToken('token'),
        matchId: save.id,
      ),
      multiplayerMatch: terminalMatch(
        outcomeCondition: 'resignation',
        winnerPlayerId: 'player_1',
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('gameHud.outcomeOverlay')), findsOneWidget);
    expect(find.text('VICTORY'), findsOneWidget);
    expect(find.text('RESIGNATION'), findsOneWidget);
    expect(find.textContaining('Alice'), findsWidgets);
  });
  testWidgets('terminal multiplayer draw ignores active-turn perspective', (
    tester,
  ) async {
    final save = hudSave.copyWith(
      gameMode: GameMode.multiplayer,
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
          playerGold: const {'player_2': 0},
          fogOfWar: FogOfWarState(
            players: {'player_2': PlayerFogOfWar(playerId: 'player_2')},
          ),
        ),
      ),
    );

    await pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      session: hudSession(hudMap(), gameMode: GameMode.multiplayer),
      networkSession: NetworkSession(
        userId: 'user_2',
        playerId: 'player_2',
        token: AuthToken('token'),
        matchId: save.id,
      ),
      multiplayerMatch: terminalMatch(
        outcomeCondition: 'draw',
        winnerPlayerId: null,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('gameHud.outcomeOverlay')), findsOneWidget);
    expect(find.text('DRAW'), findsOneWidget);
    expect(find.text('SCORE DRAW'), findsOneWidget);
    expect(find.text('VICTORY'), findsNothing);
    expect(find.text('DEFEAT'), findsNothing);
  });
  testWidgets('outcome overlay shows score draw rows', (tester) async {
    final turnLimit = GameLengthConfig.standard60.turnLimit!;
    final save = hudSave.copyWith(
      gameMode: NewGameFlow.singlePlayer.gameMode,
      turn: turnLimit,
      matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
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
            GameUnit.produced(
              id: 'warrior_2',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: 1,
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
      session: hudSession(
        hudMap(),
        gameMode: NewGameFlow.singlePlayer.gameMode,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('gameHud.outcomeOverlay')), findsOneWidget);
    expect(find.text('DRAW'), findsOneWidget);
    expect(find.text('SCORE DRAW'), findsOneWidget);
    final outcomeOverlay = find.byKey(const Key('gameHud.outcomeOverlay'));
    expect(
      find.descendant(of: outcomeOverlay, matching: find.text('Alice')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: outcomeOverlay, matching: find.text('Bob')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: outcomeOverlay, matching: find.text('15')),
      findsNWidgets(2),
    );
  });
}
