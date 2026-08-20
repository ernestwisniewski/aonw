part of 'diplomatic_message_popup_overlay_test.dart';

Future<void> _pumpOverlay(
  WidgetTester tester, {
  GameSave? gameSave,
  ValueNotifier<GamepadInputSnapshot>? gamepadInput,
  VoidCallback? onRendererCancel,
}) async {
  final save = gameSave ?? _save;
  Widget overlay = DiplomaticMessagePopupOverlay(gameSave: save);
  if (gamepadInput != null) {
    overlay = GamepadInputRouterScope(
      input: gamepadInput,
      child: GamepadInputRouteListener(
        route: GamepadInputRoute(
          priority: GamepadInputRoutePriority.renderer,
          onCancel: onRendererCancel,
        ),
        child: overlay,
      ),
    );
  }
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProviderScope(
          overrides: [gamePlayerControlSaveProvider.overrideWithValue(save)],
          child: Scaffold(body: overlay),
        ),
      ),
    ),
  );
}
