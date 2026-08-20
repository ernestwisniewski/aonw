part of '../game_hud_test.dart';

void _registerGameHudWorkerActionImprovementsScenarios() {
  testWidgets(
    'worker improve action selects and confirms from the bottom sheet',
    (tester) async {
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 1,
        row: 0,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.agriculture},
          ),
        },
      );
      final repository = FakeHudRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: hudSave,
          state: GameClientState(
            units: [worker],
            cities: [city],
            research: research,
          ),
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
          .dispatchIntent(const SelectUnitCommand('worker_1'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byKey(const Key('selectionInfo.action.improve')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('selectionInfo.action.work')), findsNothing);
      expect(find.text('Work fields'), findsNothing);

      await tester.tap(find.byKey(const Key('selectionInfo.action.improve')));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        container.read(gameStateProvider('save')).value?.pendingAction,
        isA<PendingWorkerActionSelection>(),
      );
      expect(find.byType(SelectionDetailSheet), findsOneWidget);
      expect(find.text('Tile improvement'), findsOneWidget);
      expect(find.text('Choose improvement'), findsAtLeastNWidgets(1));
      expect(
        find.byKey(const Key('selectionInfo.workerBuild.option.farm')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('selectionInfo.workerBuild.confirm')),
        findsOneWidget,
      );
      expect(find.text('Work fields'), findsNothing);

      await tester.tap(
        find.byKey(const Key('selectionInfo.workerBuild.option.farm')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final selectedAction =
          container.read(gameStateProvider('save')).value?.pendingAction
              as PendingWorkerActionSelection?;
      expect(selectedAction?.improvementType, FieldImprovementType.farm);
      expect(find.text('Selected: Farm'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('selectionInfo.workerBuild.confirm')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final updatedWorker = container
          .read(gameStateProvider('save'))
          .value
          ?.units
          .singleWhere((unit) => unit.id == 'worker_1');
      expect(
        updatedWorker?.workerJob?.improvementType,
        FieldImprovementType.farm,
      );
    },
  );
  testWidgets('portrait worker improve action opens selection sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      name: GameUnitType.worker.defaultNameToken,
      col: 1,
      row: 0,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 1, row: 0)],
    );
    final research = ResearchState(
      players: {
        'player_1': PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.agriculture},
        ),
      },
    );
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: hudSave,
        state: GameClientState(
          activePlayerId: 'player_1',
          units: [worker],
          cities: const [city],
          research: research,
        ),
      ),
    );

    await pumpHud(tester, repository: repository, autoActionFlowEnabled: false);
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatchIntent(const SelectUnitCommand('worker_1'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('selectionInfo.action.improve')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      container.read(gameStateProvider('save')).value?.pendingAction,
      isA<PendingWorkerActionSelection>(),
    );
    expect(find.byType(SelectionDetailSheet), findsOneWidget);
    expect(find.text('Tile improvement'), findsOneWidget);
    expect(
      find.byKey(const Key('selectionInfo.workerBuild.option.farm')),
      findsOneWidget,
    );
    expect(find.text('Work fields'), findsNothing);
    expect(
      find.byKey(const Key('selectionInfo.action.cancel')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('selectionInfo.action.work')), findsNothing);
  });
  testWidgets('worker work toolbar action is not exposed for ready fields', (
    tester,
  ) async {
    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      name: GameUnitType.worker.defaultNameToken,
      col: 1,
      row: 0,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 1, row: 0)],
    );
    const farm = FieldImprovement(
      hex: CityHex(col: 1, row: 0),
      type: FieldImprovementType.farm,
      builtByCityId: 'city_1',
    );
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: hudSave,
        state: GameClientState(
          activePlayerId: 'player_1',
          units: [worker],
          cities: const [city],
          fieldImprovements: const [farm],
        ),
      ),
    );

    await pumpHud(tester, repository: repository, autoActionFlowEnabled: false);
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatchIntent(const SelectUnitCommand('worker_1'));
    await tester.pump(const Duration(milliseconds: 500));

    final selectedWorker = container
        .read(gameStateProvider('save'))
        .value
        ?.units
        .singleWhere((unit) => unit.id == 'worker_1');
    expect(selectedWorker?.workerAssignment, isNull);
    expect(
      find.byKey(const Key('selectionInfo.action.improve')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('selectionInfo.action.work')), findsNothing);
    expect(find.text('Field ready to work'), findsNothing);
    expect(find.text('Work fields'), findsNothing);
  });
  testWidgets('worker build popup cancel clears pending selection', (
    tester,
  ) async {
    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      name: GameUnitType.worker.defaultNameToken,
      col: 1,
      row: 0,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 1, row: 0)],
    );
    final research = ResearchState(
      players: {
        'player_1': PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.agriculture},
        ),
      },
    );
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: hudSave,
        state: GameClientState(
          units: [worker],
          cities: [city],
          research: research,
        ),
      ),
    );

    await pumpHud(tester, repository: repository, autoActionFlowEnabled: false);
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatchIntent(const SelectUnitCommand('worker_1'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('selectionInfo.action.improve')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      container.read(gameStateProvider('save')).value?.pendingAction,
      isA<PendingWorkerActionSelection>(),
    );
    expect(find.byType(SelectionDetailSheet), findsOneWidget);
    expect(
      find.byKey(const Key('selectionInfo.workerBuild.cancel')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('selectionInfo.workerBuild.cancel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      container.read(gameStateProvider('save')).value?.pendingAction,
      isNull,
    );
    expect(find.byKey(const Key('hudModeBanner.workerAction')), findsNothing);
  });
  testWidgets(
    'selected worker action hint restores from help and starts improvement',
    (tester) async {
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 1,
        row: 0,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.agriculture},
          ),
        },
      );
      final repository = FakeHudRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: hudSave,
          state: GameClientState(
            activePlayerId: 'player_1',
            units: [worker],
            cities: const [city],
            research: research,
          ),
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
          .dispatchIntent(const SelectUnitCommand('worker_1'));
      await tester.pump(const Duration(milliseconds: 500));
      await cancelMoveTargetingBanner(tester);

      final popupId = HudMinimizedPopupIds.modeBanner(
        'save',
        'selectedWorkerAction',
      );
      expect(
        find.byKey(const Key('hudModeBanner.selectedWorkerAction')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('gameOptions.helpPopupsButton')),
        findsOneWidget,
      );

      await openHelpEntryById(tester, popupId);

      expect(
        find.byKey(const Key('hudModeBanner.selectedWorkerAction')),
        findsOneWidget,
      );
      expect(
        container.read(hudMinimizedPopupsProvider).hasEntry(popupId),
        false,
      );

      await tester.tap(find.byKey(const Key('selectionInfo.action.improve')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        container.read(gameStateProvider('save')).value?.pendingAction,
        isA<PendingWorkerActionSelection>(),
      );
      expect(find.byKey(const Key('hudModeBanner.workerAction')), findsNothing);
    },
  );
}
