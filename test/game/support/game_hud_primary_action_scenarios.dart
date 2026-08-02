part of '../game_hud_test.dart';

void _registerGameHudPrimaryActionScenarios() {
  testWidgets('action button opens non-modal city production panel', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 1, row: 1)],
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
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byType(EndTurnButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CityProductionPanel), findsOneWidget);
    expect(find.byType(CityProductionDialog), findsNothing);
    expect(
      find.descendant(
        of: find.byType(CityProductionPanel),
        matching: find.byKey(const Key('cityProductionHeader.cityName')),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('PRODUCTION'), findsWidgets);
    expect(find.text('Granary'), findsOneWidget);
    final productionScroll = find
        .descendant(
          of: find.byType(CityProductionPanel),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Wealth'),
      220,
      scrollable: productionScroll,
    );
    expect(find.text('CITY PROJECTS'), findsOneWidget);
    expect(find.text('Wealth'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Research'),
      120,
      scrollable: productionScroll,
    );
    expect(find.text('Research'), findsOneWidget);
    expect(find.text('BUILDING'), findsNothing);
    expect(find.text('UNIT'), findsNothing);
  });

  testWidgets(
    'action button opens technology tree after the last map action resolves',
    (tester) async {
      final unit = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 1,
        movementPoints: 1,
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

      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      await tester.tap(find.byType(EndTurnButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        container.read(gameStateProvider('save')).value?.selectedUnitId,
        unit.id,
      );
      expect(find.text('TECHNOLOGY TREE'), findsNothing);

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(SkipUnitTurnCommand(unit.id));
      await _pumpUntil(
        tester,
        () =>
            container
                .read(gameStateProvider('save'))
                .value!
                .units
                .singleWhere((candidate) => candidate.id == unit.id)
                .movementPoints ==
            0,
        frames: 20,
      );

      expect(find.text('TECHNOLOGY TREE'), findsNothing);

      await tester.tap(find.byType(EndTurnButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TECHNOLOGY TREE'), findsOneWidget);

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
          .dispatchIntent(const TileTappedCommand(0, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('TECHNOLOGY TREE'), findsNothing);
      expect(
        container.read(gameStateProvider('save')).value?.selection?.tile,
        isNotNull,
      );

      await tester.tap(find.byType(EndTurnButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TECHNOLOGY TREE'), findsOneWidget);
    },
  );

  testWidgets('next action button focuses unit before missing research', (
    tester,
  ) async {
    final unit = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 1,
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

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await _disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatchIntent(const SelectTileCommand(2, 2));
    await tester.pump();

    expect(find.text('ACTION'), findsOneWidget);
    expect(find.text('Next step: Warrior'), findsNothing);
    expect(find.text('Next step: choose research'), findsNothing);

    await tester.tap(find.byType(EndTurnButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      container.read(gameStateProvider('save')).value?.selectedUnitId,
      'warrior_1',
    );
    expect(find.text('TECHNOLOGY TREE'), findsNothing);

    await tester.tap(find.byType(EndTurnButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TECHNOLOGY TREE'), findsOneWidget);
  });

  testWidgets('Auto action is enabled and auto turn is disabled by default', (
    tester,
  ) async {
    final unit = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 1,
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
    final renderer = _SpyGameRenderer(mapData: _makeMap());

    await _pumpHud(tester, repository: repository, renderer: renderer);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    expect(find.text('ACTION'), findsOneWidget);
    expect(container.read(hudAutoActionFlowProvider), isTrue);
    expect(container.read(hudAutoTurnFlowProvider), isFalse);
    expect(find.byKey(const Key('endTurnButton.autoCheck')), findsNothing);
    expect(find.byKey(const Key('endTurnButton.autoChevron')), findsNothing);
    expect(
      container.read(gameStateProvider('save')).value?.selectedUnitId,
      'warrior_1',
    );
  });

  testWidgets('Auto turn hint opens from help without action buttons', (
    tester,
  ) async {
    final unit = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 1,
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

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump(const Duration(milliseconds: 300));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    expect(find.byKey(const Key('hudAutoTurnHint')), findsNothing);
    expect(container.read(hudAutoTurnFlowProvider), isFalse);

    await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
    await tester.pump();
    await tester.tap(find.text('Auto turn completion'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Auto turn completion'), findsOneWidget);
    expect(find.text('Disabled'), findsOneWidget);
    expect(find.byKey(const Key('hudAutoTurnHint.toggle')), findsNothing);
    expect(container.read(hudAutoTurnFlowProvider), isFalse);

    final hintRect = tester.getRect(find.byKey(const Key('hudAutoTurnHint')));
    final optionsRect = tester.getRect(
      find.byKey(const Key('gameOptions.optionsButton')),
    );
    expect(hintRect.left, greaterThan(optionsRect.right));

    await tester.tap(find.byKey(const Key('hudAutoTurnHint.minimize')));
    await tester.pump();

    final popupId = HudMinimizedPopupIds.autoTurnHint('save');
    expect(find.byKey(const Key('hudAutoTurnHint')), findsNothing);
    expect(
      container.read(hudMinimizedPopupsProvider).hasEntry(popupId),
      isTrue,
    );
    expect(
      find.byKey(const Key('gameOptions.helpPopupsButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('gameOptions.helpPopupsButton.attentionGlow')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('gameOptions.helpPopupsButton')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 3));
    expect(
      find.byKey(const Key('gameOptions.helpPopupsButton.attentionGlow')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
    await tester.pump();
    await tester.tap(find.byKey(Key('gameOptions.helpPopup.$popupId')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('hudAutoTurnHint')), findsOneWidget);
    expect(
      container.read(hudMinimizedPopupsProvider).hasEntry(popupId),
      isFalse,
    );
    expect(
      find.byKey(const Key('gameOptions.helpPopupsButton')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('gameOptions.helpPopupsButton')),
        matching: find.text('1'),
      ),
      findsNothing,
    );
    expect(container.read(hudAutoTurnFlowProvider), isFalse);
  });

  testWidgets(
    'Enabled Auto opens research action without dismissing the prompt',
    (tester) async {
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
      await _enableAutoTurnFlow(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      await _pumpUntil(
        tester,
        () =>
            find.text('TECHNOLOGY TREE').evaluate().isNotEmpty &&
            container.read(gameStateProvider('save')).value?.pendingAction
                is PendingResearchSelection,
        frames: 8,
      );

      expect(find.text('TECHNOLOGY TREE'), findsOneWidget);
      expect(
        container.read(gameStateProvider('save')).value?.pendingAction,
        isA<PendingResearchSelection>(),
      );
      final researchActionKey = hudResearchActionKey(
        save: repository.snapshot.save,
        activePlayerId: 'player_1',
      );
      expect(researchActionKey, isNotNull);
      expect(
        container.read(hudResearchAutoPromptControllerProvider),
        isNot(contains(researchActionKey)),
      );
    },
  );

  _registerSplitHudTests();
}
