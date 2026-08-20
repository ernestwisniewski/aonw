import 'package:aonw/game/presentation/widgets/city/city_production_dialog_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_gamepad_navigation.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list_parts.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list_sections.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list_tile.dart';
import 'package:aonw/game/presentation/widgets/theme/building_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_sprite_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/wonder_sprite_catalog.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'ProductionLeading uses only atlas widgets for sprite-backed items',
    (tester) async {
      CityProductionItem atlasItem({
        CityBuildingType? buildingType,
        GameUnitType? unitType,
        WonderType? wonderType,
      }) {
        return CityProductionItem(
          buildingType: buildingType,
          unitType: unitType,
          projectType: null,
          wonderType: wonderType,
          title: 'Atlas item',
          active: false,
          investedProduction: 0,
          totalCost: 20,
          productionPerTurn: 5,
          turnsRemaining: 4,
          rushGoldCost: 0,
          locked: false,
          requirementLabel: null,
          buildingState: null,
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: [
              ProductionLeading(
                item: atlasItem(buildingType: CityBuildingType.granary),
                compact: false,
              ),
              ProductionLeading(
                item: atlasItem(unitType: GameUnitType.warrior),
                compact: false,
              ),
              ProductionLeading(
                item: atlasItem(wonderType: WonderType.greatLibrary),
                compact: false,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(BuildingSpriteIcon), findsOneWidget);
      expect(find.byType(UnitSpriteIcon), findsOneWidget);
      expect(find.byType(WonderSpriteIcon), findsOneWidget);
      expect(find.byType(GameIcon), findsNothing);
    },
  );

  testWidgets('CityProductionList routes row build and help details', (
    tester,
  ) async {
    var detailCount = 0;
    final built = <CityBuildingType>[];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CityProductionList(
            buildings: const [
              CityProductionItem(
                buildingType: CityBuildingType.granary,
                unitType: null,
                projectType: null,
                title: 'Granary',
                active: false,
                investedProduction: 0,
                totalCost: 30,
                productionPerTurn: 5,
                turnsRemaining: 6,
                rushGoldCost: 0,
                locked: false,
                requirementLabel: null,
                buildingState: null,
              ),
            ],
            futureBuildings: const [],
            units: const [],
            projects: const [],
            specializations: const [],
            onBuildingDetails: (_) => detailCount++,
            onUnitDetails: (_) {},
            onWonderDetails: (_) {},
            onBuild: built.add,
            onProduceUnit: (_) {},
            onStartProject: null,
            onSetSpecialization: null,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Granary'));
    await tester.pump();

    expect(detailCount, 0);
    expect(built, [CityBuildingType.granary]);

    await tester.tap(find.byTooltip('Building details'));
    await tester.pump();

    expect(detailCount, 1);

    await tester.tap(find.text('PRODUCE'));
    await tester.pump();

    expect(built, [CityBuildingType.granary, CityBuildingType.granary]);
  });

  testWidgets(
    'CityProductionList exposes unit project and specialization actions',
    (tester) async {
      var unitDetails = 0;
      final produced = <GameUnitType>[];
      final projects = <CityProjectType>[];
      final specializations = <CitySpecializationType>[];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CityProductionList(
              buildings: const [],
              futureBuildings: const [],
              units: const [
                CityProductionItem(
                  buildingType: null,
                  unitType: GameUnitType.warrior,
                  projectType: null,
                  title: 'Warrior',
                  active: false,
                  investedProduction: 0,
                  totalCost: 20,
                  productionPerTurn: 5,
                  turnsRemaining: 4,
                  rushGoldCost: 0,
                  locked: false,
                  requirementLabel: null,
                  buildingState: null,
                ),
              ],
              projects: [
                CityProductionItem.project(
                  type: CityProjectType.wealth,
                  productionPerTurn: 5,
                  active: false,
                  l10n: AppLocalizationsEn(),
                ),
              ],
              specializations: const [
                CitySpecializationItem(
                  type: CitySpecializationType.science,
                  title: 'Science',
                  icon: GameIcons.science,
                  active: false,
                  locked: false,
                  metaLabels: ['+2 science'],
                ),
              ],
              onBuildingDetails: (_) {},
              onUnitDetails: (_) => unitDetails++,
              onWonderDetails: (_) {},
              onBuild: (_) {},
              onProduceUnit: produced.add,
              onStartProject: projects.add,
              onSetSpecialization: specializations.add,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Warrior'));
      await tester.pump();

      expect(unitDetails, 0);
      expect(produced, [GameUnitType.warrior]);

      await tester.tap(find.byTooltip('Unit details'));
      await tester.pump();

      expect(unitDetails, 1);

      await tester.tap(find.text('PRODUCE').first);
      await tester.pump();
      await tester.tap(find.text('PRODUCE').last);
      await tester.pump();
      await tester.tap(find.text('Select'));
      await tester.pump();

      expect(produced, [GameUnitType.warrior, GameUnitType.warrior]);
      expect(projects, [CityProjectType.wealth]);
      expect(specializations, [CitySpecializationType.science]);
    },
  );

  testWidgets('CityProductionList keeps city projects at the bottom', (
    tester,
  ) async {
    Future<List<CityProductionItem>> render({
      required bool activeProject,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CityProductionList(
              buildings: const [
                CityProductionItem(
                  buildingType: CityBuildingType.granary,
                  unitType: null,
                  projectType: null,
                  title: 'Granary',
                  active: false,
                  investedProduction: 0,
                  totalCost: 30,
                  productionPerTurn: 5,
                  turnsRemaining: 6,
                  rushGoldCost: 0,
                  locked: false,
                  requirementLabel: null,
                  buildingState: null,
                ),
              ],
              futureBuildings: const [],
              units: const [
                CityProductionItem(
                  buildingType: null,
                  unitType: GameUnitType.warrior,
                  projectType: null,
                  title: 'Warrior',
                  active: false,
                  investedProduction: 0,
                  totalCost: 20,
                  productionPerTurn: 5,
                  turnsRemaining: 4,
                  rushGoldCost: 0,
                  locked: false,
                  requirementLabel: null,
                  buildingState: null,
                ),
              ],
              projects: [
                CityProductionItem.project(
                  type: CityProjectType.wealth,
                  productionPerTurn: 5,
                  active: activeProject,
                  l10n: AppLocalizationsEn(),
                ),
              ],
              specializations: const [
                CitySpecializationItem(
                  type: CitySpecializationType.science,
                  title: 'Science',
                  icon: GameIcons.science,
                  active: false,
                  locked: false,
                  metaLabels: [],
                ),
              ],
              onBuildingDetails: (_) {},
              onUnitDetails: (_) {},
              onWonderDetails: (_) {},
              onBuild: (_) {},
              onProduceUnit: (_) {},
              onStartProject: (_) {},
              onSetSpecialization: null,
            ),
          ),
        ),
      );

      return tester
          .widgetList<ProductionListTile>(find.byType(ProductionListTile))
          .map((tile) => tile.item)
          .toList();
    }

    var items = await render(activeProject: false);
    expect(items.map((item) => item.projectType), [
      null,
      null,
      CityProjectType.wealth,
    ]);
    expect(
      tester.getTopLeft(find.text('Wealth')).dy,
      greaterThan(tester.getTopLeft(find.text('Science')).dy),
    );

    items = await render(activeProject: true);
    expect(items.map((item) => item.projectType), [
      null,
      null,
      CityProjectType.wealth,
    ]);
    expect(
      tester.getTopLeft(find.text('Wealth')).dy,
      greaterThan(tester.getTopLeft(find.text('Science')).dy),
    );
  });

  testWidgets(
    'CityProductionList puts collapsed unavailable wonders after units',
    (tester) async {
      final builtWonders = <WonderType>[];
      final wonderDetails = <WonderType>[];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CityProductionList(
              buildings: const [],
              futureBuildings: const [],
              units: const [
                CityProductionItem(
                  buildingType: null,
                  unitType: GameUnitType.warrior,
                  projectType: null,
                  title: 'Warrior',
                  active: false,
                  investedProduction: 0,
                  totalCost: 20,
                  productionPerTurn: 5,
                  turnsRemaining: 4,
                  rushGoldCost: 0,
                  locked: false,
                  requirementLabel: null,
                  buildingState: null,
                ),
              ],
              wonders: const [
                CityProductionItem(
                  buildingType: null,
                  unitType: null,
                  projectType: null,
                  wonderType: WonderType.greatLibrary,
                  title: 'Great Library',
                  active: false,
                  investedProduction: 0,
                  totalCost: 120,
                  productionPerTurn: 5,
                  turnsRemaining: 24,
                  rushGoldCost: 0,
                  locked: false,
                  requirementLabel: null,
                  buildingState: null,
                ),
                CityProductionItem(
                  buildingType: null,
                  unitType: null,
                  projectType: null,
                  wonderType: WonderType.petra,
                  title: 'Petra',
                  active: false,
                  investedProduction: 0,
                  totalCost: 150,
                  productionPerTurn: 5,
                  turnsRemaining: 30,
                  rushGoldCost: 0,
                  locked: true,
                  requirementLabel: 'Requires terrain: Desert',
                  buildingState: null,
                ),
              ],
              projects: const [],
              specializations: const [],
              onBuildingDetails: (_) {},
              onUnitDetails: (_) {},
              onWonderDetails: (item) => wonderDetails.add(item.wonderType!),
              onBuild: (_) {},
              onBuildWonder: builtWonders.add,
              onProduceUnit: (_) {},
              onStartProject: null,
              onSetSpecialization: null,
            ),
          ),
        ),
      );

      expect(find.text('UNITS'), findsOneWidget);
      expect(find.text('WONDERS'), findsOneWidget);
      expect(find.text('Great Library'), findsOneWidget);
      expect(find.text('Future wonders (1)'), findsNothing);
      expect(find.text('FUTURE WONDERS (1)'), findsOneWidget);
      expect(find.text('Petra'), findsNothing);

      expect(
        tester.getTopLeft(find.text('WONDERS')).dy,
        greaterThan(tester.getTopLeft(find.text('UNITS')).dy),
      );

      await tester.tap(find.text('Great Library'));
      await tester.pump();

      expect(builtWonders, [WonderType.greatLibrary]);

      await tester.tap(find.byTooltip('Wonder details'));
      await tester.pump();

      expect(wonderDetails, [WonderType.greatLibrary]);

      await tester.tap(find.text('FUTURE WONDERS (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Petra'), findsOneWidget);
      expect(find.text('Requires terrain: Desert'), findsOneWidget);

      await tester.tap(find.byTooltip('Wonder details').last);
      await tester.pump();

      expect(wonderDetails, [WonderType.greatLibrary, WonderType.petra]);
    },
  );

  test('CityProductionGamepadNavigation follows visible production order', () {
    final choices = CityProductionGamepadNavigation.choicesFor(
      viewModel: const CityProductionDialogViewModel(
        cityName: 'City',
        productionPerTurn: 5,
        currentCityYield: null,
        currentCityScience: 0,
        buildings: [],
        futureBuildings: [],
        wonders: [
          CityProductionItem(
            buildingType: null,
            unitType: null,
            projectType: null,
            wonderType: WonderType.greatLibrary,
            title: 'Great Library',
            active: false,
            investedProduction: 0,
            totalCost: 120,
            productionPerTurn: 5,
            turnsRemaining: 24,
            rushGoldCost: 0,
            locked: false,
            requirementLabel: null,
            buildingState: null,
          ),
          CityProductionItem(
            buildingType: null,
            unitType: null,
            projectType: null,
            wonderType: WonderType.petra,
            title: 'Petra',
            active: false,
            investedProduction: 0,
            totalCost: 150,
            productionPerTurn: 5,
            turnsRemaining: 30,
            rushGoldCost: 0,
            locked: true,
            requirementLabel: 'Requires terrain: Desert',
            buildingState: null,
          ),
        ],
        units: [
          CityProductionItem(
            buildingType: null,
            unitType: GameUnitType.warrior,
            projectType: null,
            title: 'Warrior',
            active: false,
            investedProduction: 0,
            totalCost: 20,
            productionPerTurn: 5,
            turnsRemaining: 4,
            rushGoldCost: 0,
            locked: false,
            requirementLabel: null,
            buildingState: null,
          ),
        ],
        projects: [],
        specializations: [],
      ),
      buildingSortMode: CityBuildingSortMode.recommended,
      onBuild: (_) {},
      onBuildWonder: (_) {},
      onProduceUnit: (_) {},
      onBuildingDetails: (_) {},
      onUnitDetails: (_) {},
      onWonderDetails: (_) {},
      onStartProject: null,
      onSetSpecialization: null,
    );

    expect(choices.map((choice) => choice.key), [
      'unit:warrior',
      'wonder:greatLibrary',
    ]);
    expect(
      choices
          .singleWhere((choice) => choice.key == 'wonder:greatLibrary')
          .onDetails,
      isNotNull,
    );
  });

  testWidgets('CityProductionList sorts visible and collapsed buildings', (
    tester,
  ) async {
    CityProductionItem building(
      String title,
      CityBuildingType type, {
      int production = 0,
      int science = 0,
      int turnsRemaining = 5,
      bool locked = false,
    }) {
      return CityProductionItem(
        buildingType: type,
        unitType: null,
        projectType: null,
        title: title,
        active: false,
        investedProduction: 0,
        totalCost: turnsRemaining * 5,
        productionPerTurn: 5,
        turnsRemaining: turnsRemaining,
        rushGoldCost: 0,
        locked: locked,
        requirementLabel: locked ? 'Requires technology' : null,
        buildingState: null,
        buildingSortMetrics: CityProductionSortMetrics(
          production: production,
          science: science,
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CityProductionList(
            buildings: [
              building('Granary', CityBuildingType.granary, production: 0),
              building('Workshop', CityBuildingType.workshop, production: 3),
            ],
            futureBuildings: [
              building(
                'Archive',
                CityBuildingType.archive,
                science: 2,
                locked: true,
              ),
              building(
                'Factory',
                CityBuildingType.factory,
                production: 5,
                locked: true,
              ),
            ],
            units: const [],
            projects: const [],
            specializations: const [],
            buildingSortMode: CityBuildingSortMode.industry,
            onBuildingSortModeChanged: (_) {},
            onBuildingDetails: (_) {},
            onUnitDetails: (_) {},
            onWonderDetails: (_) {},
            onBuild: (_) {},
            onProduceUnit: (_) {},
            onStartProject: null,
            onSetSpecialization: null,
          ),
        ),
      ),
    );

    expect(find.byType(BuildingSortSelect), findsOneWidget);

    final visibleTiles = tester
        .widgetList<ProductionListTile>(find.byType(ProductionListTile))
        .toList();
    expect(visibleTiles.first.item.title, 'Workshop');

    final futureSection = tester.widget<FutureBuildingsSection>(
      find.byType(FutureBuildingsSection),
    );
    expect(futureSection.items.map((item) => item.title), [
      'Factory',
      'Archive',
    ]);
  });
}
