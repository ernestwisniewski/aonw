import 'package:aonw/game/application/services/game_handoff.dart';
import 'package:aonw/game/presentation/widgets.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const handoff = HandoffData(
    playerId: 'player_2',
    playerName: 'Bob',
    playerColorValue: 0xFFc45050,
    turnNumber: 3,
  );

  testWidgets('shows player name and turn number', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HotSeatHandoffOverlay(handoff: handoff, onConfirm: () {}),
        ),
      ),
    );

    expect(find.text('BOB'), findsOneWidget);
    expect(find.text('TURN 3'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
  });

  testWidgets('calls onConfirm when DALEJ is tapped', (tester) async {
    var confirmed = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HotSeatHandoffOverlay(
            handoff: handoff,
            onConfirm: () => confirmed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('CONTINUE'));
    expect(confirmed, isTrue);
  });
}
