import 'package:aonw/game/presentation/widgets/screen/game_loading_progress.dart';
import 'package:aonw/game/presentation/widgets/screen/game_screen_state_views.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders epic map loading screen chrome', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: GameLoadingPanel()),
      ),
    );

    expect(find.text('Loading world'), findsOneWidget);
    expect(find.byKey(const Key('gameLoading.mapBackdrop')), findsOneWidget);
    expect(find.byKey(const Key('gameLoading.frame')), findsOneWidget);
    expect(find.byKey(const Key('gameLoading.emblem')), findsOneWidget);
    expect(find.byKey(const Key('gameLoading.progressFrame')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('renders determinate progress when provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GameLoadingPanel(progress: GameLoadingProgress(value: 0.42)),
        ),
      ),
    );

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 0.42);
    expect(find.text('42%'), findsOneWidget);
  });
}
