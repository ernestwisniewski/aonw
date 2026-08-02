part of '../game_hud_test.dart';

void _registerGameHudLayoutNavigationPanelNavigationScenarios() {
  testWidgets('deck global empire action opens non-modal empire panel', (
    tester,
  ) async {
    final warriorA = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior A',
      col: 0,
      row: 1,
    );
    final warriorB = GameUnit(
      id: 'warrior_2',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior B',
      col: 1,
      row: 1,
    );
    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      name: 'Worker',
      col: 2,
      row: 1,
    );
    final enemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 2,
      row: 2,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Roma',
      center: CityHex(col: 1, row: 1),
    );
    const enemyCity = GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_2',
      name: 'Antium',
      center: CityHex(col: 2, row: 2),
    );
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(
          units: [warriorA, warriorB, worker, enemy],
          cities: const [city, enemyCity],
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('globalHud.action.empire')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(EmpireOverviewPanel), findsOneWidget);
    expect(find.byType(EmpireOverviewDialog), findsNothing);
    expect(find.text('EMPIRE'), findsOneWidget);
    expect(find.text('Warrior'), findsWidgets);
    expect(find.text('2 units - 2 with movement'), findsOneWidget);
    expect(find.text('Worker'), findsWidgets);
    expect(find.text('Cities'), findsOneWidget);
    expect(find.text('Roma'), findsWidgets);
    expect(find.text('Enemy'), findsNothing);
    expect(find.text('Antium'), findsNothing);
  });
  testWidgets('empire panel can focus a unit or city from the map', (
    tester,
  ) async {
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior A',
      col: 0,
      row: 1,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Roma',
      center: CityHex(col: 1, row: 1),
    );
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(units: [warrior], cities: const [city]),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await _disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    await tester.tap(find.byKey(const Key('globalHud.action.empire')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('empire.unit.warrior_1')));
    await tester.tap(find.byKey(const Key('empire.unit.warrior_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    var state = container.read(gameStateProvider('save')).value;
    expect(state?.selectedUnitId, 'warrior_1');
    expect(find.text('EMPIRE'), findsNothing);

    await tester.tap(find.byKey(const Key('globalHud.action.empire')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('empire.city.city_1')));
    await tester.tap(find.byKey(const Key('empire.city.city_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    state = container.read(gameStateProvider('save')).value;
    expect(state?.selection?.city?.id, 'city_1');
    expect(find.text('EMPIRE'), findsNothing);
  });
}
