part of '../game_hud_test.dart';

void _registerGameHudInspectionScenarios() {
  testWidgets('army detail is inactive on initial render', (tester) async {
    await pumpHud(tester, repository: FakeHudRepository());

    // The army detail sheet should only appear after the Army action is tapped.
    expect(find.text('Warriors'), findsNothing);
  });

  testWidgets('map inspection shows tile details without game selection', (
    tester,
  ) async {
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: hudSave,
        state: GameClientState(activePlayerId: 'player_1'),
      ),
    );

    await pumpHud(tester, repository: repository, autoActionFlowEnabled: false);
    await tester.pump();
    await disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    container
        .read(mapInspectionControllerProvider.notifier)
        .inspectTile(hudMap().tileAt(1, 1)!);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byKey(const Key('selectionInfo.detail.description')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('hudActionDeck.context.terrain')),
      findsOneWidget,
    );
    expect(find.byType(SelectionActionChip), findsNothing);
    expect(find.byType(SelectionCommandChip), findsNothing);
    expect(container.read(gameStateProvider('save')).value?.selection, isNull);

    container.read(mapInspectionControllerProvider.notifier).clear();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('selectionInfo.detail.description')),
      findsNothing,
    );
    expect(container.read(mapInspectionControllerProvider).active, isFalse);
  });

  testWidgets('anchored map inspection shows compact hex menu', (tester) async {
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: hudSave,
        state: GameClientState(activePlayerId: 'player_1'),
      ),
    );

    await pumpHud(tester, repository: repository, autoActionFlowEnabled: false);
    await tester.pump();
    await disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    container
        .read(mapInspectionControllerProvider.notifier)
        .inspectTile(hudMap().tileAt(1, 1)!, anchor: const Offset(180, 120));
    await tester.pump();

    expect(
      find.byKey(const Key('hudMapInspectionMenu.positioned')),
      findsOneWidget,
    );
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Terrain'), findsOneWidget);
    expect(find.text('Resources'), findsOneWidget);
    expect(find.text('Possible improvements'), findsOneWidget);
    expect(
      find.byKey(const Key('hudMapInspectionMenu.improvement.farm')),
      findsOneWidget,
    );
    final lockedTechnology = tester.widget<Text>(
      find.byKey(const Key('hudMapInspectionMenu.improvement.farm.technology')),
    );
    expect(lockedTechnology.data, '(Agriculture)');
    expect(lockedTechnology.style?.color, GameUiTheme.danger);
    expect(find.byType(SelectionDetailSheet), findsNothing);

    await tester.tap(find.byKey(const Key('hudMapInspectionMenu.close')));
    await tester.pump();

    expect(container.read(mapInspectionControllerProvider).active, isFalse);
    expect(
      find.byKey(const Key('hudMapInspectionMenu.positioned')),
      findsNothing,
    );
  });

  testWidgets('anchored map inspection shows map objective details', (
    tester,
  ) async {
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: hudSave,
        state: GameClientState(activePlayerId: 'player_1'),
      ),
    );

    await pumpHud(tester, repository: repository, autoActionFlowEnabled: false);
    await tester.pump();
    await disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    const objective = MapObjectiveProgress(
      definition: MapObjectiveDefinition(
        id: 'pass_1',
        type: MapObjectiveType.strategicPass,
        hex: HexCoord(col: 1, row: 1),
        requiredHoldTurns: 3,
        victoryPoints: 2,
        goldPerTurn: 1,
      ),
      controllingPlayerId: 'player_1',
      holdTurns: 2,
    );
    container
        .read(mapInspectionControllerProvider.notifier)
        .inspectObjective(objective, anchor: const Offset(180, 120));
    await tester.pump();

    expect(find.text('Map objective'), findsWidgets);
    expect(find.text('Strategic pass'), findsWidgets);
    expect(find.text('Holding 2/3'), findsOneWidget);
    expect(find.text('+2 VP'), findsOneWidget);
    expect(find.text('+1 gold/turn'), findsOneWidget);
    expect(find.text('Terrain'), findsNothing);
  });

  testWidgets(
    'objective inspection keeps a dedicated popup over selected hex',
    (tester) async {
      final map = hudMap();
      final repository = FakeHudRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: hudSave,
          state: GameClientState(
            activePlayerId: 'player_1',
            interaction: InteractionState(
              selection: GameSelection.tile(map.tileAt(1, 1)!),
            ),
          ),
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

      const objective = MapObjectiveProgress(
        definition: MapObjectiveDefinition(
          id: 'pass_1',
          type: MapObjectiveType.strategicPass,
          hex: HexCoord(col: 1, row: 1),
          requiredHoldTurns: 3,
          victoryPoints: 2,
        ),
        controllingPlayerId: 'player_1',
        holdTurns: 2,
      );
      container
          .read(mapInspectionControllerProvider.notifier)
          .inspectObjective(objective, anchor: const Offset(180, 120));
      await tester.pump();

      expect(
        find.byKey(const Key('hudMapInspectionMenu.objectivePopover')),
        findsOneWidget,
      );
      expect(find.text('Strategic pass'), findsWidgets);
      expect(find.text('Holding 2/3'), findsOneWidget);
      expect(find.text('Terrain'), findsNothing);
      expect(find.text('Possible improvements'), findsNothing);
    },
  );

  testWidgets(
    'anchored map inspection marks unlocked improvement technology green',
    (tester) async {
      final repository = FakeHudRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: hudSave,
          state: GameClientState(
            activePlayerId: 'player_1',
            research: ResearchState(
              players: {
                'player_1': PlayerResearchState(
                  unlockedTechnologyIds: {TechnologyId.agriculture},
                ),
              },
            ),
          ),
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

      container
          .read(mapInspectionControllerProvider.notifier)
          .inspectTile(hudMap().tileAt(1, 1)!, anchor: const Offset(180, 120));
      await tester.pump();

      final unlockedTechnology = tester.widget<Text>(
        find.byKey(
          const Key('hudMapInspectionMenu.improvement.farm.technology'),
        ),
      );
      expect(unlockedTechnology.data, '(Agriculture)');
      expect(unlockedTechnology.style?.color, GameUiTheme.success);
    },
  );
}
