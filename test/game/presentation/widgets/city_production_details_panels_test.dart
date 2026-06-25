import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_details_panels.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('CityProductionBuildingDetailsPanel adapts production item', (
    tester,
  ) async {
    var closes = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 700,
            height: 600,
            child: CityProductionBuildingDetailsPanel(
              item: const CityProductionItem(
                buildingType: CityBuildingType.granary,
                unitType: null,
                projectType: null,
                title: 'Granary',
                emoji: '🌾',
                icon: null,
                active: true,
                investedProduction: 10,
                totalCost: 30,
                productionPerTurn: 5,
                turnsRemaining: 4,
                rushGoldCost: 40,
                locked: false,
                requirementLabel: null,
                buildingState: CityBuildingCardState.inProgress,
              ),
              l10n: l10n,
              definition: CityRulesets.standard.buildingDefinitionFor(
                CityBuildingType.granary,
              ),
              currentCityYield: const TileYield(
                food: 4,
                production: 1,
                gold: 0,
                defense: 0,
              ),
              unlockingTechnology: null,
              onClose: () => closes++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Granary'), findsOneWidget);
    expect(find.text(l10n.productionInProgressLabel), findsOneWidget);
    expect(find.text('10/30 • ${l10n.turnCountLabel(4)}'), findsOneWidget);
    expect(find.text('4 -> 6'), findsOneWidget);
    expect(find.text('0 -> 2'), findsNothing);

    await tester.tap(find.byTooltip(l10n.closeAction));

    expect(closes, 1);
  });

  testWidgets('CityProductionBuildingDetailsPanel shows active built yields', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 700,
            height: 600,
            child: CityProductionBuildingDetailsPanel(
              item: const CityProductionItem(
                buildingType: CityBuildingType.granary,
                unitType: null,
                projectType: null,
                title: 'Granary',
                emoji: '🌾',
                icon: null,
                active: false,
                investedProduction: 30,
                totalCost: 30,
                productionPerTurn: 0,
                turnsRemaining: null,
                rushGoldCost: 0,
                locked: false,
                requirementLabel: null,
                buildingState: CityBuildingCardState.built,
              ),
              l10n: l10n,
              definition: CityRulesets.standard.buildingDefinitionFor(
                CityBuildingType.granary,
              ),
              unlockingTechnology: null,
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text(l10n.cityProductionBuiltLabel), findsOneWidget);
    expect(find.text('0 -> 2'), findsNothing);
    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets(
    'CityProductionBuildingDetailsLayer keeps detail panel compact on tall viewports',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: CityProductionBuildingDetailsLayer(
                item: const CityProductionItem(
                  buildingType: CityBuildingType.workshop,
                  unitType: null,
                  projectType: null,
                  title: 'Workshop',
                  emoji: '🏗️',
                  icon: null,
                  active: false,
                  investedProduction: 0,
                  totalCost: 15,
                  productionPerTurn: 10,
                  turnsRemaining: 2,
                  rushGoldCost: 20,
                  locked: false,
                  requirementLabel: null,
                  buildingState: CityBuildingCardState.available,
                ),
                l10n: l10n,
                definition: CityRulesets.standard.buildingDefinitionFor(
                  CityBuildingType.workshop,
                ),
                unlockingTechnology: null,
                currentCityYield: const TileYield(
                  food: 2,
                  production: 3,
                  gold: 0,
                  defense: 0,
                ),
                currentCityScience: 0,
                compact: false,
                onClose: () {},
              ),
            ),
          ),
        ),
      );

      final overlay = tester.getSize(
        find.byKey(const Key('cityProductionPanel.detailsLayer')),
      );
      final surface = tester.getSize(
        find.byKey(const Key('cityBuildingDetailsPanel.surface')),
      );

      expect(overlay.height, 1400);
      expect(surface.height, lessThan(700));
    },
  );

  testWidgets('CityProductionUnitDetailsPanel adapts production item', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 700,
            height: 600,
            child: CityProductionUnitDetailsPanel(
              item: const CityProductionItem(
                buildingType: null,
                unitType: GameUnitType.warrior,
                projectType: null,
                title: 'Warrior',
                emoji: null,
                icon: GameIcons.warrior,
                active: false,
                investedProduction: 0,
                totalCost: 20,
                productionPerTurn: 4,
                turnsRemaining: 5,
                rushGoldCost: 40,
                locked: false,
                requirementLabel: null,
                buildingState: null,
              ),
              l10n: l10n,
              definition: CityRulesets.standard.unitDefinitionFor(
                GameUnitType.warrior,
              ),
              unlockingTechnology: null,
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Warrior'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('0/20 • ${l10n.turnCountLabel(5)}'), findsOneWidget);
    expect(find.text('4 prod./turn'), findsOneWidget);
  });
}
