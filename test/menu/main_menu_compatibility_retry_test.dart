import 'package:aonw/game/presentation/providers/multiplayer/multiplayer_compatibility_provider.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/menu/main_menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('main menu retries an unavailable compatibility check', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    var attempts = 0;
    final container = ProviderContainer(
      overrides: [
        multiplayerUpdateCheckEnabledProvider.overrideWithValue(true),
        multiplayerUpdateNoticeProvider.overrideWith((_) async {
          attempts++;
          if (attempts == 1) throw StateError('temporary outage');
          return null;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainMenuScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      container.read(multiplayerAccessStateProvider),
      MultiplayerAccessState.unavailable,
    );
    expect(find.text('RETRY'), findsOneWidget);

    await tester.tap(find.text('RETRY'));
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    expect(
      container.read(multiplayerAccessStateProvider),
      MultiplayerAccessState.allowed,
    );
    expect(find.text('RETRY'), findsNothing);
  });
}
