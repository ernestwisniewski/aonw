import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/selection_info/selection_detail_sheet.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cases = <({SelectionDetailViewModel model, double maxWidth})>[
    (
      model: const SelectionDescriptionDetail(
        chipId: SelectionInfoChipId.description,
        title: 'Description',
        contentKey: 'description:wide',
        heading: 'Plain',
        subtitle: 'Map tile',
        body: 'Good place for city growth.',
        items: [],
        yields: [],
        tags: [],
      ),
      maxWidth: 760,
    ),
    (
      model: const SelectionTerrainDetail(
        chipId: SelectionInfoChipId.terrain,
        title: 'Terrain',
        contentKey: 'terrain:wide',
        terrainLabels: ['Plain', 'Forest'],
        tags: [],
      ),
      maxWidth: 680,
    ),
    (
      model: const SelectionResourcesDetail(
        chipId: SelectionInfoChipId.resources,
        title: 'Resources',
        contentKey: 'resources:wide',
        resourceLabels: ['Wheat', 'Iron'],
        resourceItems: [],
      ),
      maxWidth: 760,
    ),
    (
      model: const SelectionImprovementsDetail(
        chipId: SelectionInfoChipId.improvements,
        title: 'Improvements',
        contentKey: 'improvements:wide',
        improvements: [],
      ),
      maxWidth: 680,
    ),
    (
      model: const SelectionBuildingsDetail(
        chipId: SelectionInfoChipId.buildings,
        title: 'Buildings',
        contentKey: 'buildings:wide',
        buildings: ['Granary', 'Workshop', 'Archive'],
      ),
      maxWidth: 680,
    ),
    (
      model: const SelectionArmyDetail(
        chipId: SelectionInfoChipId.army,
        title: 'Army',
        contentKey: 'army:wide',
        troops: [],
      ),
      maxWidth: 680,
    ),
    (
      model: const WorkerActionSelectionDetail(
        chipId: 'workerBuild',
        title: 'Tile improvement',
        contentKey: 'worker:wide',
        workerAction: WorkerActionPanelViewModel(
          unitId: 'worker_1',
          unitName: 'Worker',
          currentHex: CityHex(col: 0, row: 0),
          movementPoints: 2,
          selectionActive: true,
          selectedImprovementType: null,
          activeJob: null,
          options: [
            WorkerImprovementOptionViewModel(
              improvementType: FieldImprovementType.farm,
              title: 'Farm',
              yield: TileYield(food: 1, production: 0, gold: 0, defense: 0),
              buildTurns: 2,
              state: WorkerImprovementOptionState.available,
              reason: '',
              canSelect: true,
              score: 1,
            ),
          ],
        ),
      ),
      maxWidth: 720,
    ),
  ];

  for (final testCase in cases) {
    testWidgets(
      '${testCase.model.chipId} detail sheet stays readable on wide viewports',
      (tester) async {
        tester.view.physicalSize = const Size(1800, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SelectionDetailSheet(
                model: testCase.model,
                compact: false,
                fillWidth: true,
                bottomSheet: true,
                onClose: () {},
              ),
            ),
          ),
        );

        final surface = tester.getRect(
          find.byKey(const Key('selectionInfo.detailSheet.surface')),
        );

        expect(surface.width, lessThanOrEqualTo(testCase.maxWidth));
        expect(surface.center.dx, closeTo(900, 1));
      },
    );
  }

  testWidgets('building detail modal opened from buildings sheet is bounded', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SelectionDetailSheet(
            model: SelectionBuildingsDetail(
              chipId: SelectionInfoChipId.buildings,
              title: 'Buildings',
              contentKey: 'buildings:modal',
              buildings: [],
              buildingItems: [
                SelectionCityBuildingItem(
                  type: CityBuildingType.granary,
                  label: 'Granary',
                ),
              ],
            ),
            cityRuleset: CityRulesets.standard,
            technologyRuleset: TechnologyRulesets.standard,
            compact: false,
            fillWidth: true,
            bottomSheet: true,
            onClose: _noop,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Granary'));
    await tester.pumpAndSettle();

    final surface = tester.getRect(
      find.byKey(const Key('cityBuildingDetailsPanel.surface')),
    );

    expect(find.byType(CityBuildingDetailsPanel), findsOneWidget);
    expect(surface.width, lessThanOrEqualTo(600));
    expect(surface.height, lessThanOrEqualTo(680));
    expect(surface.center.dx, closeTo(900, 1));
    expect(surface.height, lessThan(1100));
  });

  testWidgets(
    'buildings detail sheet shows sorted building rows with metrics',
    (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SelectionDetailSheet(
              model: SelectionBuildingsDetail(
                chipId: SelectionInfoChipId.buildings,
                title: 'Buildings',
                contentKey: 'buildings:list',
                buildings: [],
                buildingItems: [
                  SelectionCityBuildingItem(
                    type: CityBuildingType.granary,
                    label: 'Granary',
                  ),
                  SelectionCityBuildingItem(
                    type: CityBuildingType.workshop,
                    label: 'Workshop',
                  ),
                ],
              ),
              cityRuleset: CityRulesets.standard,
              technologyRuleset: TechnologyRulesets.standard,
              compact: false,
              fillWidth: true,
              bottomSheet: true,
              onClose: _noop,
            ),
          ),
        ),
      );

      expect(find.byType(BuildingSortSelect), findsOneWidget);
      expect(find.byTooltip('Building details'), findsNothing);
      expect(find.text('Built'), findsNWidgets(2));
      expect(find.text('+2 PROD'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('cityProductionList.buildingSort')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Industry').last);
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text('Workshop')).dy,
        lessThan(tester.getTopLeft(find.text('Granary')).dy),
      );
    },
  );

  testWidgets('buildings detail sheet grows taller for long building lists', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final buildingItems = [
      for (final type in CityBuildingType.values.take(12))
        SelectionCityBuildingItem(type: type, label: type.name),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SelectionDetailSheet(
            model: SelectionBuildingsDetail(
              chipId: SelectionInfoChipId.buildings,
              title: 'Buildings',
              contentKey: 'buildings:tall',
              buildings: const [],
              buildingItems: buildingItems,
            ),
            cityRuleset: CityRulesets.standard,
            technologyRuleset: TechnologyRulesets.standard,
            compact: false,
            fillWidth: true,
            bottomSheet: true,
            onClose: _noop,
          ),
        ),
      ),
    );

    final surface = tester.getRect(
      find.byKey(const Key('selectionInfo.detailSheet.surface')),
    );

    expect(surface.height, greaterThan(390));
    expect(surface.height, lessThanOrEqualTo(435));
  });
}

void _noop() {}
