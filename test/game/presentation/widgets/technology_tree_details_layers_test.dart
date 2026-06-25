import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_details_layers.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('TechnologyInlineTechnologyDetailsLayer renders panel', (
    tester,
  ) async {
    await _pumpLayer(
      tester,
      TechnologyInlineTechnologyDetailsLayer(
        card: const TechnologyCardViewModel(
          id: TechnologyId.agriculture,
          state: TechnologyCardState.available,
          progress: 0,
          baseCost: 6,
          totalCost: 6,
          turnsRemaining: 3,
          boostActive: false,
        ),
        l10n: l10n,
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        compact: false,
        onClose: () {},
      ),
    );

    expect(find.byType(TechnologyDetailsPanel), findsOneWidget);
    expect(find.text('Agriculture'), findsOneWidget);
  });

  testWidgets('TechnologyInlineCityBuildingDetailsLayer renders building', (
    tester,
  ) async {
    await _pumpLayer(
      tester,
      TechnologyInlineCityBuildingDetailsLayer(
        buildingType: CityBuildingType.workshop,
        l10n: l10n,
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        compact: true,
        onClose: () {},
      ),
    );

    expect(find.text('Workshop'), findsOneWidget);
    expect(find.text('Unlock'), findsOneWidget);
  });

  testWidgets('TechnologyInlineUnitDetailsLayer renders unit', (tester) async {
    await _pumpLayer(
      tester,
      TechnologyInlineUnitDetailsLayer(
        unitType: GameUnitType.archer,
        l10n: l10n,
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        compact: true,
        onClose: () {},
      ),
    );

    expect(find.text('Archer'), findsOneWidget);
    expect(find.text('Unlock'), findsOneWidget);
  });

  testWidgets('inline details stay compact on tall viewports', (tester) async {
    tester.view.physicalSize = const Size(1600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpLayer(
      tester,
      TechnologyInlineCityBuildingDetailsLayer(
        buildingType: CityBuildingType.workshop,
        l10n: l10n,
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        compact: false,
        onClose: () {},
      ),
      size: const Size(1600, 1400),
    );

    final surface = tester.getSize(
      find.byKey(const Key('cityBuildingDetailsPanel.surface')),
    );

    expect(surface.height, lessThan(700));
  });
}

Future<void> _pumpLayer(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(720, 620),
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox.fromSize(size: size, child: child),
      ),
    ),
  );
}
