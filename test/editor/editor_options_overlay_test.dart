import 'package:aonw/editor/widgets/editor_options_overlay.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('visibility toggles update an open editor options panel', (
    tester,
  ) async {
    var showHeightBadge = true;
    var showCityGrowth = false;
    var showDiceRollTest = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: StatefulBuilder(
              builder: (context, setState) {
                return EditorOptionsOverlay(
                  viewMode: MapViewMode.tile,
                  allowGraphicMode: true,
                  onViewModeChanged: (_) {},
                  onSave: () {},
                  showTerrain: true,
                  showResources: true,
                  showHeightBadge: showHeightBadge,
                  showCitySites: false,
                  showCityGrowth: showCityGrowth,
                  showDiceRollTest: showDiceRollTest,
                  onToggleTerrain: () {},
                  onToggleResources: () {},
                  onToggleHeightBadge: () {
                    setState(() => showHeightBadge = !showHeightBadge);
                  },
                  onToggleCitySites: () {},
                  onToggleCityGrowth: () {
                    setState(() => showCityGrowth = !showCityGrowth);
                  },
                  onToggleDiceRollTest: () {
                    setState(() => showDiceRollTest = !showDiceRollTest);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();

    expect(find.text('CITY GROWTH'), findsOneWidget);
    expect(find.text('HEIGHT'), findsOneWidget);
    expect(find.text('DICE TEST'), findsOneWidget);

    await tester.tap(find.text('HEIGHT'));
    await tester.pump();
    await tester.pump();

    expect(showHeightBadge, isFalse);

    await tester.tap(find.text('CITY GROWTH'));
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(showCityGrowth, isTrue);

    await tester.tap(find.text('DICE TEST'));
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(showDiceRollTest, isTrue);
  });
}
