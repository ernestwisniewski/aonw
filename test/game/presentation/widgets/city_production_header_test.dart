import 'package:aonw/game/presentation/widgets/city/city_production_header.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CityProductionHeader renders city economy summary and closes', (
    tester,
  ) async {
    var closes = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CityProductionHeader(
            cityName: 'Krakow',
            title: 'PRODUCTION',
            productionPerTurnLabel: '+4 / turn',
            playerGold: 25,
            closeTooltip: 'Close',
            onClose: () => closes++,
          ),
        ),
      ),
    );

    expect(find.text('Krakow'), findsOneWidget);
    expect(find.text('PRODUCTION • +4 / turn • 25 gold'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));

    expect(closes, 1);
  });

  testWidgets('CityProductionSectionTitle uppercases label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CityProductionSectionTitle('Buildings')),
      ),
    );

    expect(find.text('BUILDINGS'), findsOneWidget);
  });
}
