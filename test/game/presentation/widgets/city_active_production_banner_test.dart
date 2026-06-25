import 'package:aonw/game/presentation/formatters/turn_eta.dart';
import 'package:aonw/game/presentation/widgets/city/city_active_production_banner.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CityActiveProductionBanner renders continuous project output', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CityActiveProductionBanner(
            title: 'Research',
            continuous: true,
            turnsRemaining: null,
            totalCost: 0,
            investedProduction: 0,
            progress: 0,
            metaLabels: ['continuous', '+3 science / turn'],
            canBeRushed: false,
            rushGoldCost: 0,
            playerGold: 12,
            onRushProduction: null,
          ),
        ),
      ),
    );

    expect(find.text('Research'), findsOneWidget);
    expect(find.text('continuous'), findsOneWidget);
    expect(find.text('+3 science / turn'), findsOneWidget);
    expect(find.textContaining('Rush'), findsNothing);
  });

  testWidgets('CityActiveProductionBanner enables rush only when affordable', (
    tester,
  ) async {
    var rushes = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CityActiveProductionBanner(
            title: 'Granary',
            continuous: false,
            turnsRemaining: 2,
            eta: const TurnEta(turnsRemaining: 2, completionTurn: 9),
            totalCost: 40,
            investedProduction: 18,
            progress: 0.45,
            metaLabels: const [],
            canBeRushed: true,
            rushGoldCost: 10,
            playerGold: 12,
            onRushProduction: () => rushes++,
          ),
        ),
      ),
    );

    expect(find.text('2 turns • T9'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Rush -10'))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Rush -10'));

    expect(rushes, 1);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CityActiveProductionBanner(
            title: 'Granary',
            continuous: false,
            turnsRemaining: null,
            totalCost: 40,
            investedProduction: 18,
            progress: 0.45,
            metaLabels: const [],
            canBeRushed: true,
            rushGoldCost: 10,
            playerGold: 4,
            onRushProduction: () => rushes++,
          ),
        ),
      ),
    );

    expect(find.text('22 prod.'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Rush -10'))
          .onPressed,
      isNull,
    );
  });
}
