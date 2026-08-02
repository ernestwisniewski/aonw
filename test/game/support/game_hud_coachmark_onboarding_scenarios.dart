part of '../game_hud_test.dart';

void _registerGameHudCoachmarkOnboardingScenarios() {
  testWidgets('first turn first game walks through unit-led coachmarks', (
    tester,
  ) async {
    final fixture = await _pumpCoachmarkWalkthrough(tester);
    await _walkCoachmarkStepsOneToFour(tester, fixture.container, fixture.save);
    await _finishCoachmarkWalkthrough(tester, fixture.container, fixture.save);
  });
  testWidgets('skipped first turn coachmarks stay in question menu', (
    tester,
  ) async {
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

    await tester.tap(find.text('Skip'));
    await tester.pump();

    final tutorialPopupId = HudMinimizedPopupIds.firstTurnTutorial(
      firstTurnSave.id,
    );
    expect(
      container.read(hudMinimizedPopupsProvider).hasEntry(tutorialPopupId),
      isTrue,
    );
    expect(find.byKey(const Key('firstTurnCoachmarks.overlay')), findsNothing);
    expect(
      find.byKey(const Key('gameOptions.helpPopupsButton')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
    await tester.pump();

    expect(find.text('Tutorial'), findsOneWidget);
    expect(find.text('Auto turn completion'), findsOneWidget);
    await tester.tap(find.text('Tutorial'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const Key('firstTurnCoachmarks.overlay')),
      findsOneWidget,
    );
  });
  testWidgets('first turn coachmarks can be disabled from the popup', (
    tester,
  ) async {
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
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    final tutorialPopupId = HudMinimizedPopupIds.firstTurnTutorial(
      firstTurnSave.id,
    );

    expect(
      find.byKey(const Key('firstTurnCoachmarks.overlay')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('firstTurnCoachmarks.disable')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('firstTurnCoachmarks.disable')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final disabledEntry = container
        .read(hudMinimizedPopupsProvider)
        .entryFor(tutorialPopupId);
    expect(disabledEntry, isNotNull);
    expect(disabledEntry!.payload['disabled'], 'true');
    expect(find.byKey(const Key('firstTurnCoachmarks.overlay')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await _pumpHud(
      tester,
      repository: repository,
      gameSave: firstTurnSave,
      session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('firstTurnCoachmarks.overlay')), findsNothing);

    await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
    await tester.pump();
    await tester.tap(find.text('Tutorial'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const Key('firstTurnCoachmarks.overlay')),
      findsOneWidget,
    );
    expect(find.text('Step 1: read the selection'), findsOneWidget);
  });
}
