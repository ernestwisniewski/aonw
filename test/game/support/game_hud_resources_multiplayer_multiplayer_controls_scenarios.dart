part of '../game_hud_test.dart';

void _registerGameHudResourcesMultiplayerMultiplayerControlsScenarios() {
  testWidgets(
    'multiplayer does not open player status sheet after submitting turn',
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
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await pumpUntil(
        tester,
        () => container.read(gameStateProvider('save')).value != null,
        frames: 8,
      );

      await tester.tap(find.byType(EndTurnButton));
      await tester.pump();

      expect(
        repository.snapshot.save.playerStates['player_1'],
        PlayerTurnState.finished,
      );
      expect(
        find.byKey(const Key('multiplayerAvatarsRail.sheet')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('multiplayerStatusStats.panel')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('multiplayerAvatarTile.player_2.waiting')),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'multiplayer portrait keeps compact player rail higher on right',
    (tester) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
      });

      final save = hudSave.copyWith(
        gameMode: GameMode.multiplayer,
        players: const [hudPlayer, hudPlayer2],
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.finished,
        },
      );

      await pumpHud(
        tester,
        repository: FakeHudRepository(
          snapshot: GameSnapshotFactory.create(save: save),
        ),
        gameSave: save,
        session: hudSession(hudMap(), gameMode: GameMode.multiplayer),
      );
      await tester.pump();

      final railFinder = find.byKey(const Key('multiplayerAvatarsRail'));
      expect(railFinder, findsOneWidget);
      expect(
        find.byKey(const Key('multiplayerCompactAvatarTile.player_1.active')),
        findsOneWidget,
      );

      final railRect = tester.getRect(railFinder);
      final optionsRect = tester.getRect(
        find.byKey(const Key('gameOptions.optionsButton')),
      );
      final hudWidth = tester.getSize(find.byType(GameHud)).width;
      expect(railRect.top, HudSideMenuMetrics.compactTopOffset);
      expect(optionsRect.top, railRect.top);
      expect(railRect.right, greaterThan(hudWidth - 12));
    },
  );
  testWidgets('hotseat keeps avatars in the options closed content', (
    tester,
  ) async {
    final save = hudSave.copyWith(
      players: const [hudPlayer, hudPlayer2],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
    );

    await pumpHud(
      tester,
      repository: FakeHudRepository(
        snapshot: GameSnapshotFactory.create(save: save),
      ),
      gameSave: save,
    );
    await tester.pump();

    expect(find.byKey(const Key('multiplayerAvatarsRail')), findsNothing);
    expect(
      find.byKey(const Key('gameOptions.closedContentViewport')),
      findsOneWidget,
    );
  });
  testWidgets('multiplayer HUD keeps the network session player in control', (
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
          playerColors: const {'player_1': 0xFF4a7fc4, 'player_2': 0xFFc45050},
          playerGold: const {'player_2': 0},
          units: [
            GameUnit.produced(
              id: 'settler_2',
              ownerPlayerId: 'player_2',
              type: GameUnitType.settler,
              col: 1,
              row: 1,
            ),
          ],
          fogOfWar: FogOfWarState(
            players: {
              'player_2': PlayerFogOfWar(
                playerId: 'player_2',
                visibleHexes: {const HexCoordinate(col: 1, row: 1)},
              ),
            },
          ),
        ),
      ),
    );
    final mapData = hudMap();

    await pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      session: hudSession(mapData, gameMode: GameMode.multiplayer),
      networkSession: NetworkSession(
        userId: 'user-2',
        playerId: 'player_2',
        token: AuthToken('token'),
        matchId: save.id,
        connectionState: hudNetworkConnected,
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await pumpUntil(
      tester,
      () =>
          container.read(gamePlayerControlControllerProvider).activePlayerId ==
          'player_2',
    );

    expect(
      container.read(gamePlayerControlControllerProvider).activePlayerId,
      'player_2',
    );
    expect(
      container.read(gameStateProvider(save.id)).value?.activePlayerId,
      'player_2',
    );

    await tester.tap(find.byKey(const Key('globalHud.action.research')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(TechnologyTreePanel), findsOneWidget);
    container
        .read(hudCommandDispatcherProvider)
        .closeTechnologyPanel(
          activePlayerId: 'player_2',
          state: container.read(gameStateProvider(save.id)).value,
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatchIntent(const SelectUnitCommand('settler_2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final selectedState = container.read(gameStateProvider(save.id)).value;
    expect(selectedState, isNotNull);
    expect(selectedState!.selectedUnitId, 'settler_2');
    expect(selectedState.canControlUnit(selectedState.selectedUnit!), isTrue);
    expect(find.byKey(const Key('selectionInfo.action.move')), findsOneWidget);
    container.read(hudCommandDispatcherProvider).startCityFounding();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      container.read(gameStateProvider(save.id)).value?.cityFoundingDraft,
      isNotNull,
    );

    container.read(hudCommandDispatcherProvider).cancelCityFounding();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      container.read(gameStateProvider(save.id)).value?.cityFoundingDraft,
      isNull,
    );

    await tester.tap(find.byKey(const Key('selectionInfo.action.move')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      container.read(gameStateProvider(save.id)).value?.moveCommandActive,
      isTrue,
    );
  });
}
