part of '../game_hud_test.dart';

void _registerGameHudCoachmarkReadinessGamepadScenarios() {
  testWidgets('first turn coachmarks navigate with gamepad input', (
    tester,
  ) async {
    final gamepadInput = ValueNotifier<GamepadInputSnapshot>(
      GamepadInputSnapshot.empty,
    );
    addTearDown(gamepadInput.dispose);
    final firstTurnSave = _save.copyWith(
      turn: 1,
      gameMode: GameMode.multiplayer,
    );
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.settler,
      name: GameUnitType.settler.defaultNameToken,
      col: 1,
      row: 1,
    );
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: firstTurnSave,
        state: GameClientState(
          activePlayerId: 'player_1',
          units: [settler],
          interaction: InteractionState(
            selection: GameSelection.unit(settler),
            moveCommandActive: true,
          ),
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      gameSave: firstTurnSave,
      session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
      gamepadInputListenable: gamepadInput,
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    expect(
      find.byKey(const Key('firstTurnCoachmarks.overlay')),
      findsOneWidget,
    );
    expect(find.text('Step 1: read the selection'), findsOneWidget);

    await _pressGamepad(
      tester,
      gamepadInput,
      const GamepadInputSnapshot(confirm: true),
    );

    expect(find.text('Step 2: check your empire'), findsOneWidget);

    await _pressGamepad(
      tester,
      gamepadInput,
      const GamepadInputSnapshot(dpadLeft: true),
    );

    expect(find.text('Step 1: read the selection'), findsOneWidget);

    await _pressGamepad(
      tester,
      gamepadInput,
      const GamepadInputSnapshot(dpadRight: true),
    );

    expect(find.text('Step 2: check your empire'), findsOneWidget);

    await _pressGamepad(
      tester,
      gamepadInput,
      const GamepadInputSnapshot(focusNext: true),
    );

    expect(find.text('Step 3: learn the left menu'), findsOneWidget);

    await _pressGamepad(
      tester,
      gamepadInput,
      const GamepadInputSnapshot(cancel: true),
    );

    final tutorialPopupId = HudMinimizedPopupIds.firstTurnTutorial(
      firstTurnSave.id,
    );
    expect(
      container.read(hudMinimizedPopupsProvider).hasEntry(tutorialPopupId),
      isTrue,
    );
    expect(find.byKey(const Key('firstTurnCoachmarks.overlay')), findsNothing);
  });
  testWidgets('first turn coachmarks require first-turn ready HUD state', (
    tester,
  ) async {
    final firstTurnSave = _save.copyWith(
      turn: 1,
      playerStates: const {'player_1': PlayerTurnState.finished},
    );
    await _pumpHud(
      tester,
      repository: _FakeGameRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: firstTurnSave,
          state: GameClientState(activePlayerId: ''),
        ),
      ),
      gameSave: firstTurnSave,
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('firstTurnCoachmarks.overlay')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    final readyFirstTurnSave = firstTurnSave.copyWith(
      playerStates: const {'player_1': PlayerTurnState.active},
    );
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: readyFirstTurnSave,
        state: GameClientState(activePlayerId: 'player_1'),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      gameSave: readyFirstTurnSave,
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('firstTurnCoachmarks.overlay')), findsNothing);
  });
  testWidgets('first turn coachmarks wait for the initial camera focus', (
    tester,
  ) async {
    final firstTurnSave = _save.copyWith(
      turn: 1,
      gameMode: GameMode.multiplayer,
      players: const [_player],
    );
    final settler = GameUnit.produced(
      id: 'settler_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.settler,
      col: 1,
      row: 1,
    );
    final focusReady = ValueNotifier(false);
    addTearDown(focusReady.dispose);
    final repository = _FakeGameRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: firstTurnSave,
        state: GameClientState(
          activePlayerId: 'player_1',
          units: [settler],
          interaction: InteractionState(
            selection: GameSelection.unit(settler),
            moveCommandActive: true,
          ),
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      gameSave: firstTurnSave,
      session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
      initialCameraFocusReadyListenable: focusReady,
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('firstTurnCoachmarks.overlay')), findsNothing);

    focusReady.value = true;
    await tester.pump();

    expect(
      find.byKey(const Key('firstTurnCoachmarks.overlay')),
      findsOneWidget,
    );
  });
  testWidgets('gamepad jumps between map and bottom action toolbar', (
    tester,
  ) async {
    final gamepadInput = ValueNotifier<GamepadInputSnapshot>(
      GamepadInputSnapshot.empty,
    );
    addTearDown(gamepadInput.dispose);

    await _pumpHud(
      tester,
      repository: _FakeGameRepository(
        snapshot: GameSnapshotFactory.fromClientState(
          save: _save,
          state: GameClientState(activePlayerId: 'player_1'),
        ),
      ),
      gamepadInputListenable: gamepadInput,
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    for (var i = 0; i < 5; i += 1) {
      final targets = HudGamepadFocusTargetRegistry.flatten(
        container.read(hudGamepadFocusTargetRegistryProvider),
      );
      if (targets.any(
        (target) => target.id == HudGamepadFocusTargetIds.bottomCommand,
      )) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 20));
    }
    final targets = HudGamepadFocusTargetRegistry.flatten(
      container.read(hudGamepadFocusTargetRegistryProvider),
    );
    expect(
      targets.any(
        (target) => target.id == HudGamepadFocusTargetIds.bottomCommand,
      ),
      isTrue,
    );
    await tester.pump();

    expect(container.read(hudGamepadFocusControllerProvider).active, isFalse);

    await _pressGamepad(
      tester,
      gamepadInput,
      const GamepadInputSnapshot(hudFocusNext: true),
    );

    final focused = container.read(hudGamepadFocusControllerProvider);
    expect(focused.active, isTrue);
    expect(focused.section, HudGamepadFocusSection.selectionActions);
    expect(
      focused.targetId,
      anyOf(isNull, HudGamepadFocusTargetIds.bottomCommand),
    );

    await _pressGamepad(
      tester,
      gamepadInput,
      const GamepadInputSnapshot(cancel: true),
    );

    expect(container.read(hudGamepadFocusControllerProvider).active, isFalse);
  });
}
