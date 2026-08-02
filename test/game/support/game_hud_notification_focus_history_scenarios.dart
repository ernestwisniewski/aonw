part of '../game_hud_test.dart';

void _registerGameHudNotificationFocusHistoryScenarios() {
  testWidgets('tapping combat notification focuses a surviving participant', (
    tester,
  ) async {
    final attacker = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 2,
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
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(
          units: [attacker],
          activePlayerId: 'player_1',
          research: activeResearch,
        ),
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
    final postCombatState = container.read(gameStateProvider('save')).value!;

    container.read(gameEventNotificationsProvider.notifier).addAll([
      CombatResolvedEvent(
        attackerUnitId: 'warrior_1',
        defenderUnitId: 'enemy_1',
        outcome: CombatOutcome(
          attackerUnitId: 'warrior_1',
          defenderUnitId: 'enemy_1',
          attackerHpAfter: 3,
          defenderHpAfter: 0,
          attackerKilled: false,
          defenderKilled: true,
          steps: [AttackStep(damage: 3)],
        ),
      ),
    ], postCombatState);
    await tester.pump();

    expect(container.read(gameEventNotificationsProvider), hasLength(1));
    expect(find.text('Combat'), findsOneWidget);

    await tester.tap(find.text('Combat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final state = container.read(gameStateProvider('save')).value;
    expect(state?.selectedUnitId, 'warrior_1');
    expect(container.read(gameEventNotificationsProvider), isEmpty);
    expect(find.text('Combat'), findsNothing);
  });
  testWidgets('activity log keeps combat details after notification fades', (
    tester,
  ) async {
    final attacker = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 2,
      row: 1,
    );
    final activeResearch = ResearchState(
      players: {
        'player_1': PlayerResearchState(
          activeTechnologyId: TechnologyId.mining,
        ),
      },
    );
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: _save,
        state: GameClientState(
          units: [attacker],
          activePlayerId: 'player_1',
          research: activeResearch,
        ),
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
    final postCombatState = container.read(gameStateProvider('save')).value!;

    container.read(gameEventNotificationsProvider.notifier).addAll([
      CombatResolvedEvent(
        attackerUnitId: 'warrior_1',
        defenderUnitId: 'enemy_1',
        outcome: CombatOutcome(
          attackerUnitId: 'warrior_1',
          defenderUnitId: 'enemy_1',
          attackerHpAfter: 3,
          defenderHpAfter: 0,
          attackerKilled: false,
          defenderKilled: true,
          steps: [const RollStep(seed: 77, value: 1), AttackStep(damage: 3)],
        ),
      ),
    ], postCombatState);
    await tester.pump();

    expect(find.text('Combat'), findsWidgets);
    expect(
      find.byKey(const Key('globalHud.action.activityLog')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Combat'), findsNothing);

    container
        .read(hudCommandDispatcherProvider)
        .openActivityLogPanel(
          activePlayerId: 'player_1',
          state: container.read(gameStateProvider('save')).value,
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ActivityLogPanel), findsOneWidget);
    expect(find.byType(ActivityLogDialog), findsNothing);
    expect(find.text('ACTIVITY LOG'), findsOneWidget);
    expect(find.text('Combat'), findsWidgets);
    expect(find.text('Roll 1'), findsOneWidget);
    expect(find.text('Attack: -3 HP'), findsOneWidget);
  });
}
