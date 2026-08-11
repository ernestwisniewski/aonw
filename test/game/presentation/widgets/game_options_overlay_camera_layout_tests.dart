part of 'game_options_overlay_test.dart';

void _registerGameOptionsCameraLayoutTests() {
  testWidgets('enemy camera focus and tracking toggle independently', (
    tester,
  ) async {
    await _pumpOptionsOverlay(tester);

    await tester.tap(find.byKey(const Key('gameOptions.optionsButton')));
    await tester.pump();

    expect(find.text('FOCUS CAMERA ON ENEMY UNIT MOVEMENT'), findsOneWidget);
    expect(find.text('TRACK ENEMY UNIT MOVEMENT WITH CAMERA'), findsOneWidget);
    expect(
      find.byKey(const Key('gameOptions.focusEnemyUnitMovementCameraIcon.off')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('gameOptions.focusEnemyUnitMovementCameraRow')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('gameOptions.focusEnemyUnitMovementCameraRow')),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameOptionsOverlay)),
      listen: false,
    );
    expect(
      container.read(gameplaySettingsProvider).focusEnemyUnitMovementCamera,
      isTrue,
    );
    expect(
      find.byKey(const Key('gameOptions.focusEnemyUnitMovementCameraIcon.on')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('gameOptions.followEnemyUnitMovementCameraRow')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('gameOptions.followEnemyUnitMovementCameraRow')),
    );
    await tester.pump();

    expect(
      container.read(gameplaySettingsProvider).followEnemyUnitMovementCamera,
      isTrue,
    );
  });

  test('options panel reserves space for an overlapping action deck', () {
    const size = Size(621, 768);
    final layout = GameOptionsOverlayLayout.resolve(
      size: size,
      safePadding: EdgeInsets.zero,
      hasResignAction: false,
      sideActionCount: 5,
    );
    expect(
      layout.panelTop + layout.panelMaxHeight,
      lessThanOrEqualTo(size.height - 188),
    );
  });

  test('options panel keeps its full height beside the action deck', () {
    const size = Size(1920, 1080);
    final layout = GameOptionsOverlayLayout.resolve(
      size: size,
      safePadding: EdgeInsets.zero,
      hasResignAction: false,
      sideActionCount: 5,
    );
    expect(layout.panelMaxHeight, 720);
  });
}
