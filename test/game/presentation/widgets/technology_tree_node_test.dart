import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_node.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('TechnologyTreeNode renders labels and routes actions', (
    tester,
  ) async {
    var selected = 0;
    var details = 0;
    var researched = 0;
    CityBuildingType? buildingDetails;
    GameUnitType? unitDetails;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 190,
            child: TechnologyTreeNode(
              card: const TechnologyCardViewModel(
                id: TechnologyId.craftsmanship,
                state: TechnologyCardState.available,
                progress: 2,
                baseCost: 7,
                totalCost: 7,
                turnsRemaining: 3,
                boostActive: true,
                unlocks: [
                  UnlockCityBuilding(CityBuildingUnlockId.workshop),
                  UnlockUnitType(GameUnitType.archer),
                ],
              ),
              l10n: l10n,
              selected: true,
              inSelectedPath: false,
              showUnlockDetails: true,
              onSelected: () => selected++,
              onDetails: () => details++,
              onBuildingDetails: (value) => buildingDetails = value,
              onUnitDetails: (value) => unitDetails = value,
              onResearch: () => researched++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Craftsmanship'), findsOneWidget);
    expect(find.text('2/7'), findsOneWidget);
    expect(find.byTooltip(l10n.technologyDetailsTooltip), findsOneWidget);
    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.valueColor, isA<AlwaysStoppedAnimation<Color>>());
    expect(
      (progress.valueColor! as AlwaysStoppedAnimation<Color>).value,
      GameUiTheme.info,
    );

    await tester.tap(find.text('Craftsmanship'));
    await tester.pump();
    await tester.tap(find.byTooltip(l10n.technologyDetailsTooltip));
    await tester.pump();
    await tester.tap(find.text(l10n.technologyButtonResearch));
    await tester.pump();

    expect(selected, 1);
    expect(details, 1);
    expect(researched, 1);

    await tester.tap(find.byTooltip(l10n.buildingDetailsTooltip));
    await tester.pump();
    await tester.tap(find.byTooltip(l10n.unitDetailsTooltip));
    await tester.pump();

    expect(buildingDetails, CityBuildingType.workshop);
    expect(unitDetails, GameUnitType.archer);
  });

  testWidgets('TechnologyTreeNode hides unlock detail buttons when asked', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 190,
            child: TechnologyTreeNode(
              card: const TechnologyCardViewModel(
                id: TechnologyId.craftsmanship,
                state: TechnologyCardState.locked,
                progress: 0,
                baseCost: 7,
                totalCost: 7,
                turnsRemaining: 3,
                boostActive: false,
                unlocks: [UnlockCityBuilding(CityBuildingUnlockId.workshop)],
              ),
              l10n: l10n,
              selected: false,
              inSelectedPath: true,
              showUnlockDetails: false,
              onSelected: () {},
              onDetails: () {},
              onBuildingDetails: (_) {},
              onUnitDetails: (_) {},
              onResearch: null,
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip(l10n.buildingDetailsTooltip), findsNothing);
    expect(find.text(l10n.technologyButtonLocked), findsOneWidget);
  });
}
