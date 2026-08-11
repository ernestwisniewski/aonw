part of 'options_screen_performance_test.dart';

void registerOptionsScreenCameraMapTests() {
  testWidgets('options screen toggles own unit camera focus and tracking', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedHarness(child: OptionsScreen())),
    );
    await tester.pump();

    final focus = find.byKey(const Key('options.focusOwnUnitMovementCamera'));
    final follow = find.byKey(const Key('options.followOwnUnitMovementCamera'));
    await tester.ensureVisible(focus);
    await tester.pumpAndSettle();
    await tester.tap(focus);
    await tester.pump();
    await tester.ensureVisible(follow);
    await tester.pumpAndSettle();
    await tester.tap(follow);
    await tester.pump();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);
    expect(
      container.read(gameplaySettingsProvider).focusOwnUnitMovementCamera,
      isFalse,
    );
    expect(
      container.read(gameplaySettingsProvider).followOwnUnitMovementCamera,
      isTrue,
    );
  });

  testWidgets('options screen toggles cinematic camera', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedHarness(child: OptionsScreen())),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Cinematic camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cinematic camera'));
    await tester.pump();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);
    expect(
      container.read(gameplaySettingsProvider).cinematicCameraEnabled,
      isTrue,
    );
  });

  testWidgets('options screen toggles enemy unit camera focus and tracking', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedHarness(child: OptionsScreen())),
    );
    await tester.pump();

    final focus = find.byKey(const Key('options.focusEnemyUnitMovementCamera'));
    final follow = find.byKey(
      const Key('options.followEnemyUnitMovementCamera'),
    );
    await tester.ensureVisible(focus);
    await tester.pumpAndSettle();
    await tester.tap(focus);
    await tester.pump();
    await tester.ensureVisible(follow);
    await tester.pumpAndSettle();
    await tester.tap(follow);
    await tester.pump();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);
    expect(
      container.read(gameplaySettingsProvider).focusEnemyUnitMovementCamera,
      isTrue,
    );
    expect(
      container.read(gameplaySettingsProvider).followEnemyUnitMovementCamera,
      isTrue,
    );
  });

  testWidgets('main settings control map display and automation defaults', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedHarness(child: OptionsScreen())),
    );
    await tester.pumpAndSettle();

    final resources = find.byKey(const Key('options.showResources'));
    await tester.ensureVisible(resources);
    await tester.pumpAndSettle();
    await tester.tap(resources);

    final autoAction = find.byKey(const Key('options.autoActionFlow'));
    await tester.ensureVisible(autoAction);
    await tester.pumpAndSettle();
    await tester.tap(autoAction);

    await tester.ensureVisible(find.text('TILES'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TILES'));
    await tester.pump();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);
    expect(container.read(hexDisplayProvider).showResources, isFalse);
    expect(
      container.read(gameplaySettingsProvider).autoActionFlowEnabled,
      isFalse,
    );
    expect(
      container.read(gameplaySettingsProvider).preferredMapViewMode,
      MapViewMode.tile,
    );
  });
}
