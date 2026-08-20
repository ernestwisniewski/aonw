part of '../game_hud_test.dart';

void _registerGameHudResourcesMultiplayerResourcePopupsScenarios() {
  testWidgets('top right resource pill opens categorized resources popup', (
    tester,
  ) async {
    final mapData = WorldMap(
      cols: 3,
      rows: 3,
      tiles: [
        for (var row = 0; row < 3; row++)
          for (var col = 0; col < 3; col++)
            WorldTile(
              col: col,
              row: row,
              terrains: const [TerrainType.grassland],
              resources: switch ((col, row)) {
                (1, 1) => const [ResourceType.iron],
                (2, 1) => const [ResourceType.wheat],
                _ => const [],
              },
              height: 0,
            ),
      ],
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Roma',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 2, row: 1)],
    );
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(cities: [city]),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      session: _makeSession(mapData),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('gameHud.resource.resources')));
    await tester.pump();

    expect(find.text('Resources'), findsOneWidget);
    expect(
      find.byKey(const Key('resourceBreakdown.category.bonus')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('resourceBreakdown.category.strategic')),
      findsOneWidget,
    );
    expect(find.text('Bonus'), findsOneWidget);
    expect(find.text('Strategic resources'), findsOneWidget);
    expect(find.text('iron'), findsWidgets);
    expect(find.text('wheat'), findsWidgets);
  });
  testWidgets('top right gold pill shows net economy after unit upkeep', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      buildings: {CityBuildingType.merchantHall},
    );
    final units = [
      GameUnit(
        id: 'settler_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        name: GameUnitType.settler.defaultNameToken,
        col: 0,
        row: 0,
      ),
      GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 1,
      ),
      GameUnit(
        id: 'archer_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.archer,
        name: GameUnitType.archer.defaultNameToken,
        col: 0,
        row: 2,
      ),
      GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 1,
        row: 0,
      ),
      GameUnit(
        id: 'worker_2',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 2,
        row: 0,
      ),
    ];
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(
          activePlayerId: 'player_1',
          cities: const [city],
          units: units,
          playerGold: const {'player_1': 17},
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();

    final goldFinder = find.byKey(const Key('gameHud.resource.gold'));

    expect(
      find.descendant(of: goldFinder, matching: find.text('17')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: goldFinder, matching: find.text('▲ +1')),
      findsOneWidget,
    );
  });
  testWidgets('resource pills open source breakdown popups', (tester) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      buildings: {CityBuildingType.merchantHall},
    );
    final units = [
      GameUnit(
        id: 'settler_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        name: GameUnitType.settler.defaultNameToken,
        col: 0,
        row: 0,
      ),
      GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 1,
      ),
      GameUnit(
        id: 'archer_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.archer,
        name: GameUnitType.archer.defaultNameToken,
        col: 0,
        row: 2,
      ),
      GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 1,
        row: 0,
      ),
      GameUnit(
        id: 'worker_2',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 2,
        row: 0,
      ),
    ];
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(
          activePlayerId: 'player_1',
          cities: const [city],
          units: units,
          playerGold: const {'player_1': 17},
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('gameHud.resource.gold')));
    await tester.pump();

    expect(
      find.byKey(const Key('gameHud.resourceBreakdown.gold')),
      findsOneWidget,
    );
    expect(find.text('City income'), findsOneWidget);
    expect(find.text('Upkeep'), findsOneWidget);
    expect(find.text('City'), findsWidgets);

    await tester.tap(find.byKey(const Key('gameHud.resource.science')));
    await tester.pump();

    expect(
      find.byKey(const Key('gameHud.resourceBreakdown.gold')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('gameHud.resourceBreakdown.science')),
      findsOneWidget,
    );
    expect(find.text('Science / turn'), findsOneWidget);
    expect(find.text('Active research'), findsOneWidget);
  });
  testWidgets('resource breakdown sheet stays above action deck on portrait', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(
          activePlayerId: 'player_1',
          playerGold: {'player_1': 17},
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('gameHud.resource.gold')));
    await tester.pump();

    final sheet = tester.getRect(
      find.byKey(const Key('gameHud.resourceBreakdownSheet.gold')),
    );
    final deck = tester.getRect(find.byKey(const Key('hudActionDeck.surface')));
    expect(sheet.overlaps(deck), isTrue);

    final overlayStack = tester
        .widgetList<Stack>(find.byType(Stack))
        .firstWhere(
          (stack) =>
              stack.children.any((child) => child is HudActionDeckSlot) &&
              stack.children.any((child) => child is HudTopResourceSlot),
        );
    final actionDeckIndex = overlayStack.children.indexWhere(
      (child) => child is HudActionDeckSlot,
    );
    final resourceIndex = overlayStack.children.indexWhere(
      (child) => child is HudTopResourceSlot,
    );

    expect(resourceIndex, greaterThan(actionDeckIndex));
  });
  testWidgets('options panel does not expose a manual save button', (
    tester,
  ) async {
    await _pumpHud(tester, repository: _FakeGameRepository());

    final optionsButton = find.byKey(const Key('gameOptions.optionsButton'));
    final optionsRect = tester.getRect(optionsButton);
    final optionsCenter = optionsRect.center;
    expect(optionsCenter.dx, lessThan(80));
    expect(optionsRect.top, greaterThanOrEqualTo(0));

    await tester.tap(optionsButton);
    await tester.pump();

    expect(find.text('OPTIONS'), findsOneWidget);
    expect(find.text('HEIGHT'), findsOneWidget);
    expect(find.text('SAVE'), findsNothing);
    expect(find.text('MULTIPLAYER'), findsNothing);
  });
  testWidgets('multiplayer options expose resign action', (tester) async {
    final save = _save.copyWith(gameMode: GameMode.multiplayer);
    await _pumpHud(
      tester,
      repository: _FakeGameRepository(),
      gameSave: save,
      networkSession: NetworkSession(
        userId: 'user_1',
        playerId: 'player_1',
        token: AuthToken('jwt-token'),
        matchId: 'save',
        connectionState: _connectedNetworkState,
      ),
    );
    await tester.tap(find.byKey(const Key('gameOptions.optionsButton')));
    await tester.pump();

    expect(find.text('RESIGN'), findsOneWidget);
  });
  testWidgets('multiplayer shows player rail on the right side', (
    tester,
  ) async {
    final save = _save.copyWith(
      gameMode: GameMode.multiplayer,
      players: const [_player, _player2],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.finished,
      },
    );

    await _pumpHud(
      tester,
      repository: _FakeGameRepository(
        snapshot: GameSnapshotFactory.create(save: save),
      ),
      gameSave: save,
      session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
    );
    await tester.pump();

    final railFinder = find.byKey(const Key('multiplayerAvatarsRail'));
    expect(railFinder, findsOneWidget);
    expect(
      find.byKey(const Key('multiplayerAvatarTile.player_1.active')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('multiplayerAvatarTile.player_2.submitted')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('gameOptions.closedContentViewport')),
      findsNothing,
    );

    final railRect = tester.getRect(railFinder);
    final hudWidth = tester.getSize(find.byType(GameHud)).width;
    final menuRect = tester.getRect(find.text('MENU'));
    final optionsRect = tester.getRect(
      find.byKey(const Key('gameOptions.optionsButton')),
    );
    expect(railRect.right, greaterThan(hudWidth - 24));
    expect(railRect.left, greaterThan(menuRect.right));
    expect(railRect.top, greaterThan(menuRect.bottom));
    expect(railRect.top, HudSideMenuMetrics.topOffset);
    expect(optionsRect.top, railRect.top);
  });
}
