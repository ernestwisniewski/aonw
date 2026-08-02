part of '../game_hud_test.dart';

void _registerGameHudAutoNavigationPanelRestoreScenarios() {
  testWidgets('closing action-opened technology tree restores map selection', (
    tester,
  ) async {
    final unit = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 1,
      movementPoints: 0,
    );
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: const CityHex(col: 1, row: 1),
      controlledHexes: const [CityHex(col: 1, row: 1)],
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 0,
      ),
    );
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(units: [unit], cities: [city]),
      ),
    );

    await _pumpHud(tester, repository: repository);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    await tester.tap(find.byType(EndTurnButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TECHNOLOGY TREE'), findsOneWidget);
    expect(
      container.read(gameStateProvider('save')).value?.pendingAction,
      isA<PendingResearchSelection>(),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(TechnologyTreePanel),
        matching: find.byTooltip('Close'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TECHNOLOGY TREE'), findsNothing);
    expect(
      container.read(gameStateProvider('save')).value?.pendingAction,
      isNull,
    );

    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatchIntent(const TileTappedCommand(0, 1));
    await tester.pump();

    expect(
      container.read(gameStateProvider('save')).value?.selection?.unit?.id,
      'warrior_1',
    );
  });
  testWidgets(
    'question menu keeps minimized mode banners visible after context changes',
    (tester) async {
      const pendingResearch = PendingResearchSelection(
        ownerPlayerId: 'player_1',
      );
      final repository = _FakeGameRepository(
        snapshot: GameSnapshotFactory.create(
          save: _save,
          pendingAction: pendingResearch,
        ),
      );

      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      final popupId = HudMinimizedPopupIds.modeBanner(
        'save',
        'researchSelection',
      );
      expect(
        find.byKey(const Key('hudModeBanner.researchSelection')),
        findsNothing,
      );
      expect(
        container.read(hudMinimizedPopupsProvider).hasEntry(popupId),
        isFalse,
      );

      await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
      await tester.pump();
      await tester.tap(find.text('Choose research'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const Key('hudModeBanner.researchSelection')),
        findsOneWidget,
      );
      expect(
        container.read(hudMinimizedPopupsProvider).hasEntry(popupId),
        isFalse,
      );

      await tester.tap(find.byKey(const Key('hudModeBanner.minimize')));
      await tester.pump();

      expect(
        find.byKey(const Key('hudModeBanner.researchSelection')),
        findsNothing,
      );
      expect(
        container.read(hudMinimizedPopupsProvider).hasEntry(popupId),
        isTrue,
      );

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatchIntent(const CancelResearchSelectionCommand('player_1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        container.read(gameStateProvider('save')).value?.pendingAction,
        isNull,
      );
      expect(
        find.byKey(const Key('hudModeBanner.researchSelection')),
        findsNothing,
      );
      expect(
        container.read(hudMinimizedPopupsProvider).hasEntry(popupId),
        isTrue,
      );

      expect(
        find.byKey(const Key('gameOptions.helpPopupsButton')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
      await tester.pump();

      expect(find.text('Choose research'), findsOneWidget);

      await tester.tap(find.text('Choose research'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        container.read(gameStateProvider('save')).value?.pendingAction,
        isNull,
      );
      expect(
        find.byKey(const Key('hudModeBanner.researchSelection')),
        findsOneWidget,
      );
      expect(
        container.read(hudMinimizedPopupsProvider).hasEntry(popupId),
        isTrue,
      );
    },
  );
  testWidgets(
    'question menu opens tutorial and auto turn after player finished',
    (tester) async {
      final finishedSave = _save.copyWith(
        playerStates: const {'player_1': PlayerTurnState.finished},
      );
      final repository = _FakeGameRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: finishedSave,
          state: GameClientState(activePlayerId: 'player_1'),
        ),
      );

      await _pumpHud(tester, repository: repository, gameSave: finishedSave);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      expect(
        find.byKey(const Key('gameOptions.helpPopupsButton')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
      await tester.pump();

      expect(find.text('Tutorial'), findsOneWidget);
      expect(find.text('Auto turn completion'), findsOneWidget);

      await tester.tap(find.text('Tutorial'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const Key('firstTurnCoachmarks.overlay')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('firstTurnCoachmarks.minimize')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
      await tester.pump();
      await tester.tap(find.text('Auto turn completion'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('hudAutoTurnHint')), findsOneWidget);
      expect(find.byKey(const Key('hudAutoTurnHint.toggle')), findsNothing);
      expect(container.read(hudAutoTurnFlowProvider), isFalse);
    },
  );
  testWidgets('close button autosaves camera before leaving', (tester) async {
    final repository = _FakeGameRepository();
    var closed = false;

    await _pumpHud(
      tester,
      repository: repository,
      onClose: () => closed = true,
    );

    await tester.tap(find.text('✕'));
    await tester.pump();

    expect(repository.savedCamera, isNotNull);
    expect(closed, isTrue);
  });
}
