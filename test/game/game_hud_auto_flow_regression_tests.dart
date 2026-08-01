part of 'game_hud_test.dart';

GameUnit _autoFlowUnit(
  String id, {
  int col = 0,
  int row = 1,
  int movementPoints = 1,
}) => GameUnit(
  id: id,
  ownerPlayerId: 'player_1',
  type: GameUnitType.warrior,
  name: GameUnitType.warrior.defaultNameToken,
  col: col,
  row: row,
  movementPoints: movementPoints,
);

GameCity _autoFlowCity(
  String id, {
  int col = 1,
  int row = 1,
  bool productionSelected = true,
}) => GameCity(
  id: id,
  ownerPlayerId: 'player_1',
  name: id,
  center: CityHex(col: col, row: row),
  controlledHexes: [CityHex(col: col, row: row)],
  productionQueue: productionSelected
      ? CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        )
      : null,
);

ResearchState _autoFlowActiveResearch() => ResearchState(
  players: {
    'player_1': PlayerResearchState(
      activeTechnologyId: TechnologyId.agriculture,
    ),
  },
);

_FakeGameRepository _autoFlowManualPauseRepository(GameSave save) =>
    _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: save,
        state: GameClientState(
          units: [_autoFlowUnit('warrior_1')],
          cities: [_autoFlowCity('city_1', col: 2, row: 2)],
          research: _autoFlowActiveResearch(),
        ),
      ),
    );

GameClientState? _autoFlowState(ProviderContainer container, String saveId) =>
    container.read(gameStateProvider(saveId)).value;

void _registerHudAutoFlowRegressionTests() {
  testWidgets('Auto action keeps an inspected resolved city selected', (
    tester,
  ) async {
    final resolvedCity = _autoFlowCity('resolved_city');
    final pendingCity = _autoFlowCity(
      'pending_city',
      col: 2,
      row: 2,
      productionSelected: false,
    );
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(
          cities: [resolvedCity, pendingCity],
          research: _autoFlowActiveResearch(),
        ),
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

    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatchIntent(const CityTappedCommand('resolved_city'));
    await tester.pump();
    expect(
      container.read(gameStateProvider('save')).value?.selection?.city?.id,
      'resolved_city',
    );

    container.read(hudAutoActionFlowProvider.notifier).setEnabled(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      container.read(gameStateProvider('save')).value?.selection?.city?.id,
      'resolved_city',
    );
  });

  testWidgets('Auto action advances through city production before research', (
    tester,
  ) async {
    final firstCity = _autoFlowCity('city_1', productionSelected: false);
    final secondCity = _autoFlowCity(
      'city_2',
      col: 2,
      row: 2,
      productionSelected: false,
    );
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(cities: [firstCity, secondCity]),
      ),
    );
    final renderer = _SpyGameRenderer(mapData: _makeMap());

    await _pumpHud(
      tester,
      repository: repository,
      renderer: renderer,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
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

    container.read(hudAutoActionFlowProvider.notifier).setEnabled(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CityProductionPanel), findsOneWidget);
    expect(
      container.read(gameStateProvider('save')).value?.selection?.city?.id,
      'city_1',
    );

    await container
        .read(hudCommandDispatcherProvider)
        .startCityBuilding('city_1', CityBuildingType.granary);
    await _pumpUntil(
      tester,
      () =>
          find.byType(CityProductionPanel).evaluate().isNotEmpty &&
          container
                  .read(gameStateProvider('save'))
                  .value
                  ?.selection
                  ?.city
                  ?.id ==
              'city_2',
      frames: 8,
    );

    expect(find.byType(CityProductionPanel), findsOneWidget);
    expect(
      container.read(gameStateProvider('save')).value?.selection?.city?.id,
      'city_2',
    );
    expect(
      container
          .read(gameStateProvider('save'))
          .value
          ?.cities
          .first
          .productionQueue,
      isNotNull,
    );

    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(CityProductionPanel), findsOneWidget);
    expect(
      container.read(gameStateProvider('save')).value?.selection?.city?.id,
      'city_2',
    );

    await container
        .read(hudCommandDispatcherProvider)
        .startCityBuilding('city_2', CityBuildingType.granary);
    await _pumpUntil(
      tester,
      () =>
          find.text('TECHNOLOGY TREE').evaluate().isNotEmpty &&
          container.read(gameStateProvider('save')).value?.pendingAction
              is PendingResearchSelection,
      frames: 8,
    );

    expect(find.byType(CityProductionPanel), findsNothing);
    expect(find.text('TECHNOLOGY TREE'), findsOneWidget);
    expect(
      container.read(gameStateProvider('save')).value?.pendingAction,
      isA<PendingResearchSelection>(),
    );
  });
}

void _registerHudAutoFlowLifecycleTests() {
  testWidgets(
    'Auto resumes after a manual pause without leaving an inspected city',
    (tester) async {
      final repository = _autoFlowManualPauseRepository(_save);
      await _pumpHud(
        tester,
        repository: repository,
        renderer: _SpyGameRenderer(mapData: _makeMap()),
        autoActionFlowEnabled: false,
        autoTurnFlowEnabled: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await _enableAutoTurnFlow(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      expect(_autoFlowState(container, 'save')?.selectedUnitId, 'warrior_1');

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatchIntent(const CityTappedCommand('city_1'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_autoFlowState(container, 'save')?.selection?.city?.id, 'city_1');

      await _setAutoTurnFlow(tester, false);
      await _setAutoTurnFlow(tester, true);
      expect(_autoFlowState(container, 'save')?.selection?.city?.id, 'city_1');

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatchIntent(const SelectTileCommand(1, 0));
      await _pumpUntil(
        tester,
        () => _autoFlowState(container, 'save')?.selectedUnitId == 'warrior_1',
        frames: 8,
      );
      expect(_autoFlowState(container, 'save')?.selectedUnitId, 'warrior_1');
    },
  );

  testWidgets(
    'Auto flow state does not leak between saves on the same player turn',
    (tester) async {
      await _pumpHud(
        tester,
        repository: _autoFlowManualPauseRepository(_save),
        renderer: _SpyGameRenderer(mapData: _makeMap()),
        autoActionFlowEnabled: false,
        autoTurnFlowEnabled: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await _enableAutoTurnFlow(tester);
      var container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatchIntent(const CityTappedCommand('city_1'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_autoFlowState(container, 'save')?.selection?.city?.id, 'city_1');

      final nextSave = _save.copyWith(id: 'other_save');
      final map = _makeMap();
      await _pumpHud(
        tester,
        repository: _autoFlowManualPauseRepository(nextSave),
        gameSave: nextSave,
        session: GameSession(
          mapData: map,
          viewMode: MapViewMode.tile,
          saveId: nextSave.id,
        ),
        renderer: _SpyGameRenderer(mapData: map),
        autoActionFlowEnabled: true,
        autoTurnFlowEnabled: true,
      );
      await tester.pump();
      container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await _pumpUntil(
        tester,
        () =>
            _autoFlowState(container, nextSave.id)?.selectedUnitId ==
            'warrior_1',
        frames: 8,
      );

      expect(
        _autoFlowState(container, nextSave.id)?.selectedUnitId,
        'warrior_1',
      );
    },
  );

  testWidgets(
    'Enabled Auto continues after the selected unit spends movement',
    (tester) async {
      final map = _makeMap();
      final firstUnit = _autoFlowUnit('warrior_1');
      final nextUnit = _autoFlowUnit('warrior_2', col: 2);
      final repository = _FakeGameRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: _save,
          state: GameClientState(
            units: [firstUnit, nextUnit],
            cities: [_autoFlowCity('city_1', col: 2, row: 2)],
            research: _autoFlowActiveResearch(),
            interaction: InteractionState(
              selection: GameSelection.unit(
                firstUnit,
                tile: map.tileAt(firstUnit.col, firstUnit.row),
              ),
            ),
          ),
        ),
      );
      final renderer = _SpyGameRenderer(mapData: map);

      await _pumpHud(tester, repository: repository, renderer: renderer);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await _enableAutoTurnFlow(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatchIntent(const SelectUnitCommand('warrior_1'));
      await tester.pump();

      expect(container.read(hudAutoTurnFlowProvider), isTrue);
      expect(
        container.read(gameStateProvider('save')).value?.selectedUnitId,
        'warrior_1',
      );
      await tester.pump();

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(const MoveUnitCommand('warrior_1', 1, 1));

      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (container.read(gameStateProvider('save')).value?.selectedUnitId ==
            'warrior_2') {
          break;
        }
      }

      expect(
        container.read(gameStateProvider('save')).value?.selectedUnitId,
        'warrior_2',
      );
    },
  );

  testWidgets(
    'Auto action mode stops before ending turn when auto turn is disabled',
    (tester) async {
      final unit = _autoFlowUnit('warrior_1');
      final repository = _FakeGameRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: _save,
          state: GameClientState(
            units: [unit],
            cities: [_autoFlowCity('city_1')],
            research: _autoFlowActiveResearch(),
          ),
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

      expect(container.read(hudAutoActionFlowProvider), isTrue);
      expect(container.read(hudAutoTurnFlowProvider), isFalse);
      expect(
        container.read(gameStateProvider('save')).value?.selectedUnitId,
        'warrior_1',
      );

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(const SkipUnitTurnCommand('warrior_1'));
      await tester.pump();
      await tester.runAsync(() async {
        for (var i = 0; i < 20; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pump();

      expect(repository.snapshot.save.turn, _save.turn);
      expect(
        container.read(gameStateProvider('save')).value?.submittedPlayerIds,
        isEmpty,
      );
    },
  );

  testWidgets('Auto action mode ends the turn after the last action resolves', (
    tester,
  ) async {
    final unit = _autoFlowUnit('warrior_1');
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(
          units: [unit],
          cities: [_autoFlowCity('city_1')],
          research: _autoFlowActiveResearch(),
        ),
      ),
    );
    final renderer = _SpyGameRenderer(mapData: _makeMap());

    await _pumpHud(tester, repository: repository, renderer: renderer);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await _enableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    await tester.tap(find.text('ACTION'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      container.read(gameStateProvider('save')).value?.selectedUnitId,
      'warrior_1',
    );

    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatch(const SkipUnitTurnCommand('warrior_1'));
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 60; i++) {
        if (repository.snapshot.save.turn > _save.turn) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();

    expect(repository.snapshot.save.turn, _save.turn + 1);
  });
}
