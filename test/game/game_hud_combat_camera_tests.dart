part of 'game_hud_test.dart';

void _registerSplitHudTests() {
  _registerHudAutoFlowRegressionTests();
  _registerHudAutoFlowLifecycleTests();
  _registerHudCombatCameraTests();
}

Future<void> _setActivePlayerWaiting(ProviderContainer container) {
  return container
      .read(gameStateProvider('save').notifier)
      .syncActivePlayer(playerId: 'player_1', canAct: false);
}

void _registerHudCombatCameraTests() {
  testWidgets(
    'attack target focuses attacker before opening prediction popup',
    (tester) async {
      final attacker = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 0,
        movementPoints: 2,
      );
      final defender = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 1,
        row: 0,
        movementPoints: 2,
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: GameState(
            activePlayerId: 'player_1',
            units: [attacker, defender],
            fogOfWar: FogOfWarState(
              players: {
                'player_1': PlayerFogOfWar(
                  playerId: 'player_1',
                  visibleHexes: {
                    const HexCoordinate(col: 0, row: 0),
                    const HexCoordinate(col: 1, row: 0),
                  },
                ),
              },
            ),
            interaction: GameInteractionState(
              selection: GameSelection.unit(attacker),
            ),
          ),
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
      await _disableAutoTurnFlow(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatchIntent(const StartAttackTargetingCommand('warrior_1'));
      await tester.pump();
      renderer.handledEffects.clear();
      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatchIntent(const TileTappedCommand(1, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      var state = container.read(gameStateProvider('save')).value!;
      final pending = state.pendingAction as PendingAttackTargeting;
      expect(pending.defenderCol, 1);
      expect(pending.defenderRow, 0);
      expect(find.byKey(const Key('hudCombatConfirm.surface')), findsOneWidget);
      expect(find.text('Confirm attack'), findsAtLeastNWidgets(1));
      expect(find.text('Why this forecast?'), findsOneWidget);
      final cameraFocus = renderer.handledEffects
          .whereType<SmoothCameraEffect>()
          .single;
      expect((cameraFocus.col, cameraFocus.row), (0, 0));

      await tester.tap(find.byKey(const Key('hudCombatConfirm.confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      state = container.read(gameStateProvider('save')).value!;
      expect(state.pendingAction, isNull);
      expect(
        state.units
            .singleWhere((unit) => unit.id == 'warrior_1')
            .movementPoints,
        0,
      );
      expect(find.byKey(const Key('hudCombatConfirm.surface')), findsNothing);
    },
  );
}
