part of '../game_hud_test.dart';

Future<({GameSave save, ProviderContainer container})>
_pumpCoachmarkWalkthrough(WidgetTester tester) async {
  final save = hudSave.copyWith(turn: 1, gameMode: GameMode.multiplayer);
  final settler = GameUnit(
    id: 'settler_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.settler,
    name: GameUnitType.settler.defaultNameToken,
    col: 1,
    row: 1,
  );
  final repository = FakeHudRepository(
    snapshot: GameSnapshotFactory.fromClientState(
      save: save,
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
  await pumpHud(
    tester,
    repository: repository,
    gameSave: save,
    session: hudSession(hudMap(), gameMode: GameMode.multiplayer),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
  return (
    save: save,
    container: ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    ),
  );
}

Future<void> _walkCoachmarkStepsOneToFour(
  WidgetTester tester,
  ProviderContainer container,
  GameSave save,
) async {
  expect(find.byKey(const Key('firstTurnCoachmarks.overlay')), findsOneWidget);
  expect(find.byKey(const Key('firstTurnCoachmarks.minimize')), findsOneWidget);
  expect(find.text('Step 1: read the selection'), findsOneWidget);
  expect(find.text('Step 1/8'), findsOneWidget);
  expectCoachmarkHaloTracks(
    tester,
    find.byKey(const Key('hudActionDeck.surface')),
    reason: 'Opening coachmark should track the selected-unit deck.',
  );

  await tester.tap(find.text('Next'));
  await tester.pump();
  final minimized = container
      .read(hudMinimizedPopupsProvider)
      .entriesForSave(save.id)
      .where((entry) => entry.kind == HudMinimizedPopupKind.firstTurnCoachmarks)
      .toList(growable: false);
  expect(minimized, hasLength(1));
  expect(minimized.single.id, HudMinimizedPopupIds.firstTurnTutorial(save.id));
  expect(minimized.single.title, 'Tutorial');
  expect(minimized.single.subtitle, 'First-turn guide');
  expect(find.text('Step 2: check your empire'), findsOneWidget);
  expect(find.text('Step 2/8'), findsOneWidget);
  expectCoachmarkHaloTracks(
    tester,
    find.byKey(const Key('gameHud.resource.singleRow')),
    reason: 'Resource coachmark should track the visible top resource row.',
  );

  await tester.tap(find.text('Next'));
  await tester.pump();
  final updated = container
      .read(hudMinimizedPopupsProvider)
      .entriesForSave(save.id)
      .where((entry) => entry.kind == HudMinimizedPopupKind.firstTurnCoachmarks)
      .toList(growable: false);
  expect(updated, hasLength(1));
  expect(updated.single.payload['stepIndex'], '1');
  expect(find.text('Step 3: learn the left menu'), findsOneWidget);
  expect(find.text('Step 3/8'), findsOneWidget);
  expectCoachmarkHaloTracks(
    tester,
    find.byKey(const Key('gameOptions.optionsButton')),
    reason: 'Side menu coachmark should track the left menu rail.',
  );

  await tester.tap(find.text('Next'));
  await tester.pump();
  expect(find.text('Step 4: give the right order'), findsOneWidget);
  expect(find.text('Step 4/8'), findsOneWidget);
  final target = find.byKey(const Key('hudActionDeck.line.actions'));
  expectCoachmarkHaloTracks(
    tester,
    target.evaluate().isNotEmpty
        ? target
        : find.byKey(const Key('hudActionDeck.surface')),
    reason: 'Settler action coachmark should track the visible bottom deck.',
  );
}

Future<void> _finishCoachmarkWalkthrough(
  WidgetTester tester,
  ProviderContainer container,
  GameSave save,
) async {
  await tester.tap(find.text('Next'));
  await tester.pump();
  final minimized = container
      .read(hudMinimizedPopupsProvider)
      .entriesForSave(save.id)
      .where((entry) => entry.kind == HudMinimizedPopupKind.firstTurnCoachmarks)
      .toList(growable: false);
  expect(minimized, hasLength(1));
  expect(minimized.single.payload['stepIndex'], '3');
  expect(find.text('Step 5: choose research'), findsOneWidget);
  expect(find.text('Step 5/8'), findsOneWidget);
  expectCoachmarkHaloTracks(
    tester,
    find.byKey(const Key('globalHud.action.research')),
    reason: 'Research coachmark should track the bottom research action.',
  );

  await tester.tap(find.text('Next'));
  await tester.pump();
  expect(find.text('Step 6: set up the city'), findsOneWidget);
  expect(find.text('Step 6/8'), findsOneWidget);
  expectCoachmarkHaloTracks(
    tester,
    find.byKey(const Key('hudActionDeck.surface')),
    reason: 'City setup coachmark should return to the bottom deck.',
  );
  await tester.tap(find.text('Next'));
  await tester.pump();
  expect(find.text('Step 7: clear the action queue'), findsOneWidget);
  expect(find.text('Step 7/8'), findsOneWidget);
  expectCoachmarkHaloTracks(
    tester,
    find.byType(EndTurnButton),
    reason: 'Action queue coachmark should track the action button.',
  );
  await tester.tap(find.text('Next'));
  await tester.pump();
  expect(find.text('Step 8: end the turn and repeat'), findsOneWidget);
  expect(find.text('Step 8/8'), findsOneWidget);
  expect(find.text('Done'), findsOneWidget);
  expectCoachmarkHaloTracks(
    tester,
    find.byType(EndTurnButton),
    reason: 'End-turn coachmark should track the centered action button.',
  );

  await tester.tap(find.text('Done'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.byKey(const Key('firstTurnCoachmarks.overlay')), findsNothing);
  expect(find.text('Do not show again'), findsNothing);
  final popupId = HudMinimizedPopupIds.firstTurnTutorial(save.id);
  expect(container.read(hudMinimizedPopupsProvider).hasEntry(popupId), isTrue);
  await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
  await tester.pump();
  await tester.tap(find.text('Tutorial'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.byKey(const Key('firstTurnCoachmarks.overlay')), findsOneWidget);
  expect(find.text('Step 1: read the selection'), findsOneWidget);
  expect(find.text('Step 1/8'), findsOneWidget);
}
