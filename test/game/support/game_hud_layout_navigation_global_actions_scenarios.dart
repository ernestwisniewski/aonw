part of '../game_hud_test.dart';

void _registerGameHudLayoutNavigationGlobalActionsScenarios() {
  testWidgets('deck global research action opens technology tree popup', (
    tester,
  ) async {
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(activePlayerId: 'player_1'),
      ),
    );
    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();

    final researchRect = tester.getRect(
      find.byKey(const Key('globalHud.action.research')),
    );
    final empireFinder = find.byKey(const Key('globalHud.action.empire'));
    final empireRect = tester.getRect(empireFinder);
    final objectivesRect = tester.getRect(
      find.byKey(const Key('globalHud.action.objectives')),
    );

    expect(researchRect.left, lessThan(80));
    expect(objectivesRect.bottom, lessThan(researchRect.top));
    expect(researchRect.bottom, lessThan(empireRect.top));
    expect(empireRect.left, closeTo(researchRect.left, 0.1));

    await tester.tap(find.byKey(const Key('globalHud.action.research')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TECHNOLOGY TREE'), findsOneWidget);
  });
  testWidgets('global objectives action opens objectives panel', (
    tester,
  ) async {
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(activePlayerId: 'player_1'),
      ),
    );
    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();

    expect(find.text('OBJECTIVES'), findsNothing);

    await tester.tap(find.byKey(const Key('globalHud.action.objectives')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('OBJECTIVES'), findsOneWidget);
    expect(
      find.byKey(const Key('gameOptions.objectivesPanelViewport')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const Key('gameOptions.objectivesPanelViewport')))
          .width,
      greaterThan(260),
    );
    expect(find.text('Choose research'), findsOneWidget);
    expect(find.text('Found your first city'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('globalHud.action.objectives')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('gameObjectives.close')), findsNothing);

    await tester.tap(find.byKey(const Key('globalHud.action.objectives')));
    await tester.pump();

    expect(find.text('OBJECTIVES'), findsNothing);
  });
  testWidgets('global action popup stays above the left menu', (tester) async {
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(activePlayerId: 'player_1'),
      ),
    );
    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('globalHud.action.research')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TechnologyTreePanel), findsOneWidget);
    final researchRect = tester.getRect(
      find.byKey(const Key('globalHud.action.research')),
    );

    await tester.tapAt(researchRect.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TechnologyTreePanel), findsOneWidget);
    expect(find.byType(EmpireOverviewPanel), findsNothing);
  });
  testWidgets(
    'left menu keeps objectives and activity log between options and help',
    (tester) async {
      final repository = _FakeGameRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: _save,
          state: GameClientState(activePlayerId: 'player_1'),
        ),
      );
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
      final gameState = container.read(gameStateProvider('save')).value!;
      container
          .read(hudMinimizedPopupsProvider.notifier)
          .minimize(
            HudMinimizedPopupEntry(
              id: HudMinimizedPopupIds.firstTurnTutorial('save'),
              kind: HudMinimizedPopupKind.firstTurnCoachmarks,
              title: 'Tutorial',
              subtitle: 'First-turn guide',
            ),
          );
      container.read(gameEventNotificationsProvider.notifier).addAll(const [
        TechnologyResearchedEvent(
          playerId: 'player_1',
          technologyId: TechnologyId.agriculture,
        ),
      ], gameState);
      await tester.pump();

      final optionsRect = tester.getRect(
        find.byKey(const Key('gameOptions.optionsButton')),
      );
      final objectivesRect = tester.getRect(
        find.byKey(const Key('globalHud.action.objectives')),
      );
      final activityLogRect = tester.getRect(
        find.byKey(const Key('globalHud.action.activityLog')),
      );
      final helpRect = tester.getRect(
        find.byKey(const Key('gameOptions.helpPopupsButton')),
      );
      final researchRect = tester.getRect(
        find.byKey(const Key('globalHud.action.research')),
      );
      final empireRect = tester.getRect(
        find.byKey(const Key('globalHud.action.empire')),
      );

      expect(optionsRect.top, lessThan(helpRect.top));
      expect(helpRect.top, lessThan(objectivesRect.top));
      expect(objectivesRect.top, lessThan(activityLogRect.top));
      expect(activityLogRect.top, lessThan(researchRect.top));
      expect(researchRect.top, lessThan(empireRect.top));
      expect(objectivesRect.center.dx, closeTo(activityLogRect.center.dx, 0.1));
    },
  );
  testWidgets('portrait phone keeps deck and side global actions anchored', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(activePlayerId: 'player_1'),
      ),
    );
    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();

    final deckRect = tester.getRect(find.byType(HudActionDeck));
    final researchRect = tester.getRect(
      find.byKey(const Key('globalHud.action.research')),
    );
    final objectivesRect = tester.getRect(
      find.byKey(const Key('globalHud.action.objectives')),
    );
    final empireRect = tester.getRect(
      find.byKey(const Key('globalHud.action.empire')),
    );

    expect(researchRect.left, lessThan(80));
    expect(objectivesRect.bottom, lessThan(researchRect.top));
    expect(researchRect.bottom, lessThan(empireRect.top));
    expect(empireRect.left, closeTo(researchRect.left, 0.1));

    await tester.tap(find.byKey(const Key('globalHud.action.research')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final panelRect = tester.getRect(find.byType(TechnologyTreePanel));
    expect(find.text('TECHNOLOGY TREE'), findsOneWidget);
    expect(panelRect.bottom, lessThanOrEqualTo(deckRect.top - 2));
  });
  testWidgets('screenshot QA viewports keep baseline HUD anchors stable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final state = _hudQaState();

    for (final scenario in _hudQaScenarios) {
      tester.view.physicalSize = scenario.size;
      final repository = _FakeGameRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: _save,
          state: state,
        ),
      );

      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));

      final viewport = Offset.zero & scenario.size;
      final resourceStrip = tester.getRect(
        find.byKey(const Key('gameHud.resource.strip')),
      );
      final deck = tester.getRect(
        find.byKey(const Key('hudActionDeck.surface')),
      );
      final research = tester.getRect(
        find.byKey(const Key('globalHud.action.research')),
      );
      final objectives = tester.getRect(
        find.byKey(const Key('globalHud.action.objectives')),
      );
      final empire = tester.getRect(
        find.byKey(const Key('globalHud.action.empire')),
      );

      _expectRectInside(
        resourceStrip,
        viewport,
        reason: '${scenario.name} resource strip',
      );
      _expectRectInside(deck, viewport, reason: '${scenario.name} deck');
      _expectRectInside(
        research,
        viewport,
        reason: '${scenario.name} research',
      );
      _expectRectInside(
        objectives,
        viewport,
        reason: '${scenario.name} objectives',
      );
      _expectRectInside(empire, viewport, reason: '${scenario.name} empire');
      expect(
        research.left,
        lessThan(80),
        reason: '${scenario.name} research in left menu',
      );
      expect(
        empire.left,
        lessThan(80),
        reason: '${scenario.name} empire in left menu',
      );
      expect(
        objectives.bottom,
        lessThan(research.top),
        reason: '${scenario.name} objectives in left menu',
      );
      expect(
        research.bottom,
        lessThan(empire.top),
        reason: '${scenario.name} research before empire',
      );
      expect(
        resourceStrip.bottom,
        lessThan(deck.top),
        reason: '${scenario.name} top strip above deck',
      );
      if (scenario.size.width >= 900) {
        expect(
          deck.width,
          lessThanOrEqualTo(HudActionDeck.wideMaxWidth + 1),
          reason: '${scenario.name} desktop deck max width',
        );
      }
      expect(
        find.byKey(const Key('gameHud.resource.identityRow')),
        findsNothing,
        reason: '${scenario.name} identity row removed',
      );
      expect(
        find.byKey(const Key('gameHud.resource.singleRow')),
        findsOneWidget,
        reason: '${scenario.name} single top row',
      );
    }
  });
  testWidgets('screenshot QA portrait technology panel clears action deck', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(activePlayerId: 'player_1'),
      ),
    );
    for (final size in const [Size(678, 1442), Size(840, 1436)]) {
      tester.view.physicalSize = size;

      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();

      final deck = tester.getRect(
        find.byKey(const Key('hudActionDeck.surface')),
      );

      await tester.tap(find.byType(EndTurnButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final viewport = Offset.zero & size;
      final panel = tester.getRect(find.byType(TechnologyTreePanel));

      _expectRectInside(panel, viewport, reason: 'technology panel $size');
      expect(
        panel.bottom,
        lessThanOrEqualTo(deck.top - 2),
        reason: 'technology panel clears deck at $size',
      );
      expect(find.text('TECHNOLOGY TREE'), findsOneWidget);
    }
  });
}
