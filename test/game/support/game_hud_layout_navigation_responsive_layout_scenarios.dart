part of '../game_hud_test.dart';

void _registerGameHudLayoutNavigationResponsiveLayoutScenarios() {
  testWidgets('screenshot QA portrait panels use warm mobile sheets', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 1, row: 1)],
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 1,
      row: 1,
      movementPoints: 0,
    );
    final activeResearch = ResearchState(
      players: {
        'player_1': PlayerResearchState(
          activeTechnologyId: TechnologyId.mining,
        ),
      },
    );

    Future<void> verifyPanel({
      required Size size,
      required String name,
      required FakeHudRepository repository,
      required Future<void> Function() openPanel,
      required Type panelType,
      required Key surfaceKey,
    }) async {
      tester.view.physicalSize = size;
      await pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final deck = tester.getRect(
        find.byKey(const Key('hudActionDeck.surface')),
      );

      await openPanel();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final viewport = Offset.zero & size;
      final panel = tester.getRect(find.byType(panelType));
      final surface = tester.getRect(find.byKey(surfaceKey));
      final mobileSheet = tester.getRect(
        find.byKey(const Key('hudOverlayPanelSlot.mobileSheet')),
      );

      expectRectInside(panel, viewport, reason: '$name panel in viewport');
      expectRectInside(surface, viewport, reason: '$name surface in viewport');
      expectRectContains(
        panel.inflate(1),
        surface,
        reason: '$name surface follows panel',
      );
      expect(
        panel.bottom,
        lessThanOrEqualTo(deck.top - 2),
        reason: '$name clears action deck',
      );
      expect(
        mobileSheet.width,
        greaterThanOrEqualTo(size.width - 32),
        reason: '$name uses near-full-width mobile sheet',
      );
      _expectWarmPanelSurface(tester, surfaceKey, reason: name);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    for (final size in const [
      Size(390, 844),
      Size(678, 1442),
      Size(840, 1436),
    ]) {
      await verifyPanel(
        size: size,
        name: 'technology $size',
        repository: FakeHudRepository(
          snapshot: GameSnapshotFactory.fromClientState(
            save: hudSave,
            state: GameClientState(activePlayerId: 'player_1'),
          ),
        ),
        openPanel: () =>
            tester.tap(find.byKey(const Key('globalHud.action.research'))),
        panelType: TechnologyTreePanel,
        surfaceKey: const Key('technologyTreePanel.surface'),
      );

      await verifyPanel(
        size: size,
        name: 'empire $size',
        repository: FakeHudRepository(
          snapshot: GameSnapshotFactory.fromClientState(
            save: hudSave,
            state: GameClientState(
              activePlayerId: 'player_1',
              units: [warrior],
              cities: [
                city.copyWith(
                  productionQueue: CityProductionQueue.building(
                    buildingType: CityBuildingType.granary,
                    investedProduction: 0,
                  ),
                ),
              ],
              research: activeResearch,
            ),
          ),
        ),
        openPanel: () =>
            tester.tap(find.byKey(const Key('globalHud.action.empire'))),
        panelType: EmpireOverviewPanel,
        surfaceKey: const Key('empireOverviewPanel.surface'),
      );

      await verifyPanel(
        size: size,
        name: 'production $size',
        repository: FakeHudRepository(
          snapshot: GameSnapshotFactory.fromClientState(
            save: hudSave,
            state: GameClientState(
              activePlayerId: 'player_1',
              cities: const [city],
              research: activeResearch,
              interaction: InteractionState(
                selection: GameSelection.city(
                  city,
                  cityYield: const TileYield(
                    food: 10,
                    production: 35,
                    gold: 0,
                    defense: 0,
                  ),
                  playerColor: hudPlayer.colorValue,
                ),
              ),
            ),
          ),
        ),
        openPanel: () => tester.tap(find.byType(EndTurnButton)),
        panelType: CityProductionPanel,
        surfaceKey: const Key('cityProductionPanel.surface'),
      );
    }
  });
  testWidgets(
    'portrait phone anchors action icons above the selection infobar',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 1,
      );
      final repository = FakeHudRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: hudSave,
          state: GameClientState(activePlayerId: 'player_1', units: [warrior]),
        ),
      );

      await pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatchIntent(const SelectUnitCommand('warrior_1'));
      await tester.pump(const Duration(milliseconds: 240));

      final deckRect = tester.getRect(find.byType(HudActionDeck));
      final contextRect = tester.getRect(
        find.byKey(const Key('hudActionDeck.line.context')),
      );
      final actionLineRect = tester.getRect(
        find.byKey(const Key('hudActionDeck.line.actions')),
      );
      final commandLineRect = tester.getRect(
        find.byKey(const Key('hudActionDeck.line.commands')),
      );
      final selectionSurfaceRect = tester.getRect(
        find.byKey(const Key('hudActionDeck.selectionSurface')),
      );
      final actionRects = [
        for (
          var i = 0;
          i < tester.widgetList(find.byType(SelectionCommandChip)).length;
          i++
        )
          tester.getRect(find.byType(SelectionCommandChip).at(i)),
      ];
      final researchRect = tester.getRect(
        find.byKey(const Key('globalHud.action.research')),
      );
      final actionsLeft = actionRects
          .map((rect) => rect.left)
          .reduce((a, b) => a < b ? a : b);
      final actionsRight = actionRects
          .map((rect) => rect.right)
          .reduce((a, b) => a > b ? a : b);
      final actionsCenter = (actionsLeft + actionsRight) / 2;

      expect(find.byType(SelectionActionBar), findsNothing);
      expect(find.byType(SelectionActionChip), findsNothing);
      expect(actionLineRect.top, greaterThanOrEqualTo(deckRect.top));
      expect(actionLineRect.bottom, lessThan(selectionSurfaceRect.top));
      expect(selectionSurfaceRect.contains(contextRect.center), isTrue);
      expect(commandLineRect.top, greaterThan(selectionSurfaceRect.bottom));
      expect(researchRect.left, lessThan(80));
      expect((actionsCenter - deckRect.center.dx).abs(), lessThanOrEqualTo(36));
    },
  );
  testWidgets(
    'landscape phone keeps action icons above compact bottom infobar',
    (tester) async {
      tester.view.physicalSize = const Size(740, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 1,
      );
      final repository = FakeHudRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: hudSave,
          state: GameClientState(activePlayerId: 'player_1', units: [warrior]),
        ),
      );

      await pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await disableAutoTurnFlow(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatchIntent(const SelectUnitCommand('warrior_1'));
      await tester.pump(const Duration(milliseconds: 240));

      final deckRect = tester.getRect(find.byType(HudActionDeck));
      final contextRect = tester.getRect(
        find.byKey(const Key('hudActionDeck.line.context')),
      );
      final actionLineRect = tester.getRect(
        find.byKey(const Key('hudActionDeck.line.actions')),
      );
      final commandLineRect = tester.getRect(
        find.byKey(const Key('hudActionDeck.line.commands')),
      );
      final compactSurfaceRect = tester.getRect(
        find.byKey(const Key('hudActionDeck.compactSurface')),
      );
      final researchRect = tester.getRect(
        find.byKey(const Key('globalHud.action.research')),
      );
      final optionsRect = tester.getRect(
        find.byKey(const Key('gameOptions.optionsButton')),
      );
      final actionRects = [
        for (
          var i = 0;
          i < tester.widgetList(find.byType(SelectionCommandChip)).length;
          i++
        )
          tester.getRect(find.byType(SelectionCommandChip).at(i)),
      ];
      final actionsLeft = actionRects
          .map((rect) => rect.left)
          .reduce((a, b) => a < b ? a : b);
      final actionsRight = actionRects
          .map((rect) => rect.right)
          .reduce((a, b) => a > b ? a : b);
      final actionsCenter = (actionsLeft + actionsRight) / 2;

      expect(find.byType(SelectionActionBar), findsNothing);
      expect(find.byType(SelectionActionChip), findsNothing);
      expect(actionLineRect.top, greaterThanOrEqualTo(deckRect.top));
      expect(actionLineRect.bottom, lessThanOrEqualTo(compactSurfaceRect.top));
      expect(commandLineRect.left, greaterThan(contextRect.left));
      expect(
        (commandLineRect.center.dy - contextRect.center.dy).abs(),
        lessThanOrEqualTo(1),
      );
      expect(compactSurfaceRect.contains(contextRect.center), isTrue);
      expect(compactSurfaceRect.contains(commandLineRect.center), isTrue);
      expect(deckRect.height, lessThan(140));
      expect(
        compactSurfaceRect.left,
        greaterThanOrEqualTo(optionsRect.right + 8),
      );
      expect(researchRect.left, lessThan(80));
      expect((actionsCenter - deckRect.center.dx).abs(), lessThanOrEqualTo(36));
      expect(find.byType(EndTurnButton), findsOneWidget);
    },
  );
  testWidgets('tablet opens selection details as a modal sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 1,
    );
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: hudSave,
        state: GameClientState(activePlayerId: 'player_1', units: [warrior]),
      ),
    );

    await pumpHud(tester, repository: repository, autoActionFlowEnabled: false);
    await tester.pump();
    await disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatchIntent(const SelectUnitCommand('warrior_1'));
    await tester.pump(const Duration(milliseconds: 240));

    await tester.tap(find.byKey(const Key('hudActionDeck.context.terrain')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final detailRect = tester.getRect(
      find.byKey(const Key('selectionInfo.detailSheet.surface')),
    );
    final deckRect = tester.getRect(find.byType(HudActionDeck));

    expect(find.byType(SelectionActionBar), findsNothing);
    expect(detailRect.width, greaterThan(600));
    expect(detailRect.bottom, greaterThan(deckRect.top));
  });
}
