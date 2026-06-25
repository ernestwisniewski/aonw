import 'package:aonw/game/presentation/widgets/empire/empire_overview_header.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_view_model.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders empire title, subtitle and close action', (
    tester,
  ) async {
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: EmpireOverviewHeader(
            subtitle: '2 cities - 3 units',
            onClose: () => closed = true,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('empireOverviewHeader.titleIcon')),
      findsOneWidget,
    );
    expect(find.text('EMPIRE'), findsOneWidget);
    expect(find.text('2 CITIES - 3 UNITS'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();

    expect(closed, isTrue);
  });

  testWidgets('renders compact summary metrics from view model', (
    tester,
  ) async {
    const viewModel = EmpireOverviewViewModel(
      units: [],
      cities: [],
      unitGroups: [],
      cityComparisons: [],
      readyUnitCount: 4,
      totalPopulation: 12,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => SizedBox(
              width: 320,
              child: EmpireSummaryStrip(
                items: empireSummaryItems(
                  AppLocalizations.of(context),
                  viewModel,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('CITIES'), findsOneWidget);
    expect(find.text('UNITS'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('POPULATION'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('4'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });
}
