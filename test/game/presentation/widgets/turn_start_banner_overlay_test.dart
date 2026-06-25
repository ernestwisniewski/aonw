import 'package:aonw/game/presentation/widgets/hud/turn_start_banner_overlay.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('turn banner appears on turn change and fades away', (
    tester,
  ) async {
    await tester.pumpWidget(_host(turnNumber: 43));

    expect(find.byKey(const Key('gameHud.turnStartBanner.text')), findsNothing);

    await tester.pumpWidget(_host(turnNumber: 44));
    await tester.pump(const Duration(milliseconds: 80));

    final banner = find.byKey(const Key('gameHud.turnStartBanner.text'));
    expect(banner, findsOneWidget);
    expect(
      find.byKey(const Key('gameHud.turnStartBanner.prefix')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('gameHud.turnStartBanner.numberOutline')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('gameHud.turnStartBanner.numberFill')),
      findsOneWidget,
    );
    expect(find.text('TURN'), findsOneWidget);
    expect(find.text('44'), findsNWidgets(2));
    expect(tester.getRect(banner).center.dy, lessThan(300));

    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();

    expect(find.byKey(const Key('gameHud.turnStartBanner.text')), findsNothing);
  });

  testWidgets('turn banner can be triggered from an initially empty value', (
    tester,
  ) async {
    await tester.pumpWidget(_host(turnNumber: null));

    expect(find.byKey(const Key('gameHud.turnStartBanner.text')), findsNothing);

    await tester.pumpWidget(_host(turnNumber: 7, showSignal: 1));
    await tester.pump(const Duration(milliseconds: 80));

    expect(
      find.byKey(const Key('gameHud.turnStartBanner.text')),
      findsOneWidget,
    );
    expect(find.text('7'), findsNWidgets(2));
  });
}

Widget _host({required int? turnNumber, int showSignal = 0}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Stack(
        children: [
          TurnStartBannerOverlay(
            turnNumber: turnNumber,
            showSignal: showSignal,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    ),
  );
}
