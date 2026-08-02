part of '../game_hud_test.dart';

void _registerGameHudNotificationQueueVisibilityScenarios() {
  testWidgets(
    'event notifications show concrete events and skip routine noise',
    (tester) async {
      final state = _notificationMatrixState();
      await _pumpHud(
        tester,
        repository: _FakeGameRepository(),
        autoActionFlowEnabled: false,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      _addPrimaryNotificationBatch(container, state);
      await tester.pump();
      _expectPrimaryNotificationBatch();

      container.read(gameEventNotificationsProvider.notifier).clear();
      await tester.pump();
      container.read(gameEventNotificationsProvider.notifier).addAll(const [
        CityClaimedHexEvent(cityId: 'city_1', col: 2, row: 2),
        WorkerCompletedJobEvent(unitId: 'worker_1'),
        TechnologyResearchedEvent(
          playerId: 'player_1',
          technologyId: TechnologyId.agriculture,
        ),
      ], state);
      await tester.pump();
      expect(find.text('City borders'), findsOneWidget);
      expect(find.text('Work complete'), findsOneWidget);
      expect(find.text('Technology discovered'), findsWidgets);
      expect(find.text('+1 more ↓'), findsOneWidget);
      expect(find.byType(GameEventNotificationCard), findsNWidgets(2));

      container.read(gameEventNotificationsProvider.notifier).clear();
      await tester.pump();
      _addCombatNotificationBatch(container, state);
      await tester.pump();
      _expectCombatNotificationBatch();

      container.read(gameEventNotificationsProvider.notifier).clear();
      await tester.pump();
      container.read(gameEventNotificationsProvider.notifier).addAll(const [
        CityCapturedEvent(
          cityId: 'city_1',
          previousOwnerPlayerId: 'player_2',
          newOwnerPlayerId: 'player_1',
        ),
      ], state);
      await tester.pump();
      expect(find.text('City captured'), findsOneWidget);
    },
  );
  testWidgets('notification queue shows two cards and advances in order', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Roma',
      center: CityHex(col: 1, row: 1),
    );
    final state = GameClientState(cities: [city], activePlayerId: 'player_1');

    await _pumpHud(tester, repository: _FakeGameRepository());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    container.read(gameEventNotificationsProvider.notifier).addAll(const [
      CityFoundedEvent(cityId: 'city_1', ownerPlayerId: 'player_1'),
      CityBuiltBuildingEvent(
        cityId: 'city_1',
        buildingType: CityBuildingType.granary,
      ),
      CityProducedUnitEvent(
        cityId: 'city_1',
        unitType: GameUnitType.worker,
        producedUnitId: 'worker_2',
      ),
      CityClaimedHexEvent(cityId: 'city_1', col: 2, row: 2),
    ], state);
    await tester.pump();

    expect(find.byType(GameEventNotificationCard), findsNWidgets(2));
    expect(find.text('City founded'), findsOneWidget);
    expect(find.text('Construction complete'), findsOneWidget);
    expect(find.text('Unit trained'), findsNothing);
    expect(find.text('+2 more ↓'), findsOneWidget);
    expect(find.text('City borders'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.byType(GameEventNotificationCard), findsNWidgets(2));
    expect(find.text('City founded'), findsNothing);
    expect(find.text('Construction complete'), findsOneWidget);
    expect(find.text('Unit trained'), findsOneWidget);
    expect(find.text('+1 more ↓'), findsOneWidget);
    expect(find.text('City borders'), findsNothing);

    await tester.tap(find.text('+1 more ↓'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ActivityLogPanel), findsOneWidget);
    _expectWarmPanelSurface(
      tester,
      const Key('activityLogPanel.surface'),
      reason: 'activity log panel surface',
    );
    expect(find.text('ACTIVITY LOG'), findsOneWidget);
    expect(find.text('City borders'), findsOneWidget);
  });
  testWidgets('event notifications are painted above HUD controls', (
    tester,
  ) async {
    await _pumpHud(tester, repository: _FakeGameRepository());

    final stack = tester.widget<Stack>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Stack &&
            widget.children.any((child) => child is GameOptionsOverlay) &&
            widget.children.any(
              (child) => child is GameEventNotificationsOverlay,
            ),
      ),
    );
    final optionsIndex = stack.children.indexWhere(
      (child) => child is GameOptionsOverlay,
    );
    final hudIndex = stack.children.indexWhere(
      (child) => child is GameHudOverlayHost,
    );
    final notificationsIndex = stack.children.indexWhere(
      (child) => child is GameEventNotificationsOverlay,
    );

    expect(notificationsIndex, greaterThan(optionsIndex));
    expect(notificationsIndex, greaterThan(hudIndex));
  });
  testWidgets('large HUD panels are painted above side controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpHud(tester, repository: _FakeGameRepository());

    final stack = tester.widget<Stack>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Stack &&
            widget.children.any((child) => child is GameOptionsOverlay) &&
            widget.children.any((child) => child is GameHudOverlayPanelsHost),
      ),
    );
    final optionsIndex = stack.children.indexWhere(
      (child) => child is GameOptionsOverlay,
    );
    final hudIndex = stack.children.indexWhere(
      (child) => child is GameHudOverlayHost,
    );
    final panelsIndex = stack.children.indexWhere(
      (child) => child is GameHudOverlayPanelsHost,
    );

    expect(panelsIndex, greaterThan(optionsIndex));
    expect(panelsIndex, greaterThan(hudIndex));
  });
  testWidgets('event notifications only show the active players own events', (
    tester,
  ) async {
    const ownCity = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Roma',
      center: CityHex(col: 1, row: 1),
    );
    const otherCity = GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_2',
      name: 'Enemy City',
      center: CityHex(col: 2, row: 2),
    );
    final hotseatSave = GameSave(
      id: 'save',
      name: 'Game',
      mapName: 'verdantia',
      mapSource: MapSource.asset,
      turn: 1,
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
      savedAt: DateTime.utc(2026, 4, 16),
      camera: CameraState.zero,
      players: const [_player, _player2],
    );
    final state = GameClientState(
      cities: [ownCity, otherCity],
      activePlayerId: 'player_1',
    );

    await _pumpHud(
      tester,
      repository: _FakeGameRepository(),
      gameSave: hotseatSave,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    container.read(gameEventNotificationsProvider.notifier).addAll(const [
      CityBuiltBuildingEvent(
        cityId: 'city_1',
        buildingType: CityBuildingType.granary,
      ),
      CityBuiltBuildingEvent(
        cityId: 'city_2',
        buildingType: CityBuildingType.barracks,
      ),
      ResearchPointsGainedEvent(playerId: 'player_2', points: 9),
    ], state);
    await tester.pump();

    expect(find.text('Construction complete'), findsOneWidget);
    expect(find.textContaining('Roma'), findsOneWidget);
    expect(find.textContaining('Enemy City'), findsNothing);
    expect(find.text('Science'), findsNothing);
  });
  testWidgets('event notifications fade away one by one automatically', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Roma',
      center: CityHex(col: 1, row: 1),
    );
    final state = GameClientState(cities: [city], activePlayerId: 'player_1');

    await _pumpHud(tester, repository: _FakeGameRepository());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    container.read(gameEventNotificationsProvider.notifier).addAll(const [
      CityBuiltBuildingEvent(
        cityId: 'city_1',
        buildingType: CityBuildingType.granary,
      ),
      TechnologyResearchedEvent(
        playerId: 'player_1',
        technologyId: TechnologyId.agriculture,
      ),
    ], state);
    await tester.pump();

    expect(find.text('Construction complete'), findsOneWidget);
    expect(find.text('Technology discovered'), findsWidgets);
    expect(find.byIcon(Icons.close), findsNothing);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Construction complete'), findsNothing);
    expect(find.text('Technology discovered'), findsWidgets);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Technology discovered'), findsWidgets);
  });
}
