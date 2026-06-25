import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectionImprovementList', () {
    testWidgets('renders compact improvement cards vertically', (tester) async {
      await _pump(tester, density: SelectionDensity.compact);

      expect(find.text('Tile improvements'), findsOneWidget);
      expect(find.text('Farm'), findsOneWidget);
      expect(find.text('AVAILABLE'), findsOneWidget);
      expect(find.text('2F'), findsOneWidget);
      expect(find.text('3 turns'), findsOneWidget);
    });

    testWidgets('renders comfortable improvement cards horizontally', (
      tester,
    ) async {
      await _pump(tester, density: SelectionDensity.comfortable);

      expect(find.text('Farm'), findsOneWidget);
      expect(find.text('AVAILABLE'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}

Future<void> _pump(WidgetTester tester, {required SelectionDensity density}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: SelectionImprovementList(
            density: density,
            items: const [
              SelectionImprovementItem(
                type: FieldImprovementType.farm,
                title: 'Farm',
                yield: TileYield(food: 2, production: 0, gold: 0, defense: 0),
                buildTurns: 3,
                state: SelectionImprovementState.available,
                technologyRequirement: '',
                buildingRequirement: '',
                cityRequirement: '',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
