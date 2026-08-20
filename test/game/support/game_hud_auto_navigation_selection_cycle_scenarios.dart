part of '../game_hud_test.dart';

void _registerGameHudAutoNavigationSelectionCycleScenarios() {
  testWidgets(
    'Enabled Auto lets the player inspect a city while a unit can move',
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
        center: const CityHex(col: 2, row: 2),
        controlledHexes: const [CityHex(col: 2, row: 2)],
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      );
      final repository = FakeHudRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: hudSave,
          state: GameClientState(
            units: [unit],
            cities: [city],
            research: research,
          ),
        ),
      );
      final renderer = HudTestRenderer(mapData: hudMap());

      await pumpHud(
        tester,
        repository: repository,
        renderer: renderer,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await enableAutoTurnFlow(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      expect(
        container.read(gameStateProvider('save')).value?.selectedUnitId,
        'warrior_1',
      );

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatchIntent(const CityTappedCommand('city_1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final state = container.read(gameStateProvider('save')).value;
      expect(state?.selection?.city?.id, 'city_1');
      expect(state?.selectedUnitId, isNull);
      expect(state?.units.single.movementPoints, 1);

      renderer.handledEffects.clear();

      await tester.tap(find.byType(EndTurnButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final focusedState = container.read(gameStateProvider('save')).value;
      expect(focusedState?.selectedUnitId, 'warrior_1');
      expect(
        renderer.handledEffects.whereType<SmoothCameraEffect>().any(
          (effect) => effect.col == unit.col && effect.row == unit.row,
        ),
        isTrue,
      );
    },
  );
  testWidgets(
    'action button advances from open city production panel to remaining unit',
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
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 2, row: 2),
        controlledHexes: [CityHex(col: 2, row: 2)],
        productionQueue: null,
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      );
      final repository = FakeHudRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: hudSave,
          state: GameClientState(
            units: [unit],
            cities: [city],
            research: research,
          ),
        ),
      );
      final renderer = HudTestRenderer(mapData: hudMap());

      await pumpHud(
        tester,
        repository: repository,
        renderer: renderer,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await disableAutoTurnFlow(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatchIntent(const CityTappedCommand('city_1'));
      await tester.pump();
      container
          .read(hudCommandDispatcherProvider)
          .openCityProductionPanel(
            state: container.read(gameStateProvider('save')).value,
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CityProductionPanel), findsOneWidget);
      expect(
        container.read(gameStateProvider('save')).value?.selection?.city?.id,
        'city_1',
      );

      renderer.handledEffects.clear();

      await tester.tap(find.byType(EndTurnButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final focusedState = container.read(gameStateProvider('save')).value;
      expect(find.byType(CityProductionPanel), findsNothing);
      expect(focusedState?.selectedUnitId, 'warrior_1');
      expect(focusedState?.moveCommandActive, isTrue);
      expect(
        renderer.handledEffects.whereType<SmoothCameraEffect>().any(
          (effect) => effect.col == unit.col && effect.row == unit.row,
        ),
        isTrue,
      );
    },
  );
  testWidgets(
    'turn-start focus keeps open city production panel without a flicker',
    (tester) async {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 2, row: 2),
        controlledHexes: [CityHex(col: 2, row: 2)],
        productionQueue: null,
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      );
      final repository = FakeHudRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: hudSave,
          state: GameClientState(
            activePlayerId: 'player_1',
            cities: const [city],
            research: research,
          ),
        ),
      );
      final renderer = HudTestRenderer(mapData: hudMap());

      await pumpHud(
        tester,
        repository: repository,
        renderer: renderer,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await disableAutoTurnFlow(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatchIntent(const CityTappedCommand('city_1'));
      await tester.pump();
      container
          .read(hudCommandDispatcherProvider)
          .openCityProductionPanel(
            state: container.read(gameStateProvider('save')).value,
          );
      await tester.pump();

      expect(find.byType(CityProductionPanel), findsOneWidget);

      final focus = container
          .read(hudCommandDispatcherProvider)
          .focusTurnStartMapTarget(
            activePlayerId: 'player_1',
            state: container.read(gameStateProvider('save')).value,
            moveCamera: false,
          );
      await tester.pump();

      expect(find.byType(CityProductionPanel), findsOneWidget);

      await focus;
      await tester.pump();

      expect(find.byType(CityProductionPanel), findsOneWidget);
    },
  );
  testWidgets('next action button cycles between movable units', (
    tester,
  ) async {
    final firstUnit = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 1,
    );
    final secondUnit = GameUnit(
      id: 'warrior_2',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 2,
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
    final research = ResearchState(
      players: {
        'player_1': PlayerResearchState(
          activeTechnologyId: TechnologyId.agriculture,
        ),
      },
    );
    final repository = FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: hudSave,
        state: GameClientState(
          units: [firstUnit, secondUnit],
          cities: [city],
          research: research,
        ),
      ),
    );
    final renderer = HudTestRenderer(mapData: hudMap());

    await pumpHud(
      tester,
      repository: repository,
      renderer: renderer,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatchIntent(const SelectTileCommand(2, 2));
    await tester.pump();

    expect(
      find.byKey(const Key('endTurnButton.actionProgress')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('endTurnButton.actionProgress')))
          .data,
      '1/2',
    );

    await tester.tap(find.byType(EndTurnButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      container.read(gameStateProvider('save')).value?.selectedUnitId,
      'warrior_1',
    );
    expect(
      container.read(gameStateProvider('save')).value?.moveCommandActive,
      isTrue,
    );
    renderer.handledEffects.clear();

    await tester.tap(find.byType(EndTurnButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TECHNOLOGY TREE'), findsNothing);
    final state = container.read(gameStateProvider('save')).value;
    expect(state?.selectedUnitId, 'warrior_2');
    expect(state?.moveCommandActive, isTrue);
    expect(state?.pendingAction, isNull);
    expect(
      renderer.handledEffects.whereType<SmoothCameraEffect>().any(
        (effect) =>
            effect.col == secondUnit.col && effect.row == secondUnit.row,
      ),
      isTrue,
    );
  });
}
