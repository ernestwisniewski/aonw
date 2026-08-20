part of 'city_production_list_test.dart';

void _runCityProductionSortingScenario() {
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
