part of '../game_hud_test.dart';

void _registerGameHudWorkerActionBlockedActionsScenarios() {
  testWidgets(
    'blocked worker hint explains that the field is already improved',
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

      await pumpHud(tester, repository: repository);
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

      expect(
        find.byKey(const Key('hudModeBanner.selectedWorkerMoveToWork')),
        findsNothing,
      );

      await openHelpEntryById(
        tester,
        HudMinimizedPopupIds.modeBanner('save', 'selectedWorkerMoveToWork'),
      );

      expect(find.text('Worker: find a tile'), findsOneWidget);
      expect(
        find.textContaining('This tile already has an improvement.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('selectionInfo.action.move')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        container.read(gameStateProvider('save')).value?.moveCommandActive,
        isTrue,
      );
    },
  );
  testWidgets('blocked settler hint starts movement toward a better site', (
    tester,
  ) async {
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.settler,
      name: GameUnitType.settler.defaultNameToken,
      col: 1,
      row: 1,
    );
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
          units: [settler],
          cities: const [city],
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
        .dispatchIntent(const SelectUnitCommand('settler_1'));
    await tester.pump(const Duration(milliseconds: 500));
    await cancelMoveTargetingBanner(tester);

    expect(
      find.byKey(const Key('hudModeBanner.selectedSettlerMoveToCitySite')),
      findsNothing,
    );

    await openHelpEntryById(
      tester,
      HudMinimizedPopupIds.modeBanner('save', 'selectedSettlerMoveToCitySite'),
    );

    expect(find.text('Settler: find a site'), findsOneWidget);
    expect(find.textContaining('Move the settler'), findsOneWidget);

    await tester.tap(find.byKey(const Key('selectionInfo.action.move')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      container.read(gameStateProvider('save')).value?.moveCommandActive,
      isTrue,
    );
  });
  testWidgets('skip action can be cancelled to restore movement', (
    tester,
  ) async {
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 1,
      movementPoints: 2,
    );
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: hudSave,
        state: GameClientState(units: [warrior]),
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
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('selectionInfo.action.skip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    var state = container.read(gameStateProvider('save')).value!;
    expect(state.units.single.movementPoints, 0);
    expect(state.pendingAction, isA<PendingUnitTurnSkip>());
    expect(find.byKey(const Key('selectionInfo.action.skip')), findsOneWidget);

    await tester.tap(find.byKey(const Key('selectionInfo.action.skip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    state = container.read(gameStateProvider('save')).value!;
    expect(state.units.single.movementPoints, 2);
    expect(state.pendingAction, isNull);
    expect(find.byKey(const Key('selectionInfo.action.skip')), findsOneWidget);
  });
  testWidgets('heal action can be cancelled', (tester) async {
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 1,
      movementPoints: 2,
    ).copyWithHitPoints(7);
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: hudSave,
        state: GameClientState(units: [warrior]),
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
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('selectionInfo.action.heal')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    var state = container.read(gameStateProvider('save')).value!;
    expect(state.units.single.movementPoints, 0);
    expect(state.units.single.posture, UnitPosture.fortified);
    expect(state.pendingAction, isNull);
    expect(
      find.byKey(const Key('selectionInfo.action.stopHealing')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('selectionInfo.action.stopHealing')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    state = container.read(gameStateProvider('save')).value!;
    expect(state.units.single.posture, UnitPosture.active);
    expect(state.moveCommandActive, isTrue);
    expect(find.byKey(const Key('selectionInfo.action.move')), findsOneWidget);
  });
}
