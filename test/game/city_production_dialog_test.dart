import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_dialog.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_header.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list_tile.dart';
import 'package:aonw/game/presentation/widgets/unit/unit_details_panel.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'opens building details from help button without starting build',
    (tester) async {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
      );
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CityProductionDialog(
              city: city,
              cityRuleset: CityRulesets.standard,
              research: ResearchState.empty,
              technologyRuleset: TechnologyRulesets.standard,
              productionPerTurn: 2,
              onBuild: (_) => buildCount++,
              onProduceUnit: (_) {},
            ),
          ),
        ),
      );

      await _scrollUntilVisible(tester, find.text('Granary'));

      expect(find.byTooltip('Building details'), findsOneWidget);
      expect(find.byTooltip('Unit details'), findsWidgets);

      await tester.tap(find.byTooltip('Building details'));
      await tester.pumpAndSettle();

      expect(buildCount, 0);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(CityBuildingDetailsDialog), findsNothing);
      expect(find.byType(CityProductionList), findsOneWidget);
      expect(
        find.byKey(const Key('cityProductionPanel.detailsLayer')),
        findsOneWidget,
      );
      expect(find.byType(CityBuildingDetailsPanel), findsOneWidget);
      expect(find.textContaining('stabilizes city growth'), findsOneWidget);
      expect(find.text('COST'), findsOneWidget);
      expect(find.text('REQUIREMENTS'), findsOneWidget);
      expect(find.text('EFFECTS'), findsOneWidget);
      expect(find.textContaining('+2 food'), findsOneWidget);

      await tester.tap(find.byTooltip('Close').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('stabilizes city growth'), findsNothing);
      expect(find.byType(CityBuildingDetailsPanel), findsNothing);
      expect(
        find.byKey(const Key('cityProductionPanel.detailsLayer')),
        findsNothing,
      );

      await _scrollUntilVisible(tester, find.text('Warrior'));

      await tester.tap(find.byTooltip('Unit details').first);
      await tester.pumpAndSettle();

      expect(buildCount, 0);
      expect(find.byType(CityProductionList), findsOneWidget);
      expect(
        find.byKey(const Key('cityProductionPanel.detailsLayer')),
        findsOneWidget,
      );
      expect(find.byType(UnitDetailsPanel), findsOneWidget);
      expect(find.textContaining('basic combat unit'), findsOneWidget);
      expect(find.text('COMBAT'), findsOneWidget);
    },
  );

  testWidgets('row starts production while help opens details', (tester) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
    );
    var buildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CityProductionDialog(
            city: city,
            cityRuleset: CityRulesets.standard,
            research: ResearchState.empty,
            technologyRuleset: TechnologyRulesets.standard,
            productionPerTurn: 2,
            onBuild: (_) => buildCount++,
            onProduceUnit: (_) {},
          ),
        ),
      ),
    );

    await _scrollUntilVisible(tester, find.text('Granary'));

    await tester.tap(find.text('Granary'));
    await tester.pump();

    expect(buildCount, 1);
    expect(find.byType(CityBuildingDetailsPanel), findsNothing);

    await tester.tap(find.byTooltip('Building details'));
    await tester.pumpAndSettle();

    expect(buildCount, 1);
    expect(find.byType(CityBuildingDetailsPanel), findsOneWidget);

    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('Granary'));

    final granaryTile = find.ancestor(
      of: find.text('Granary'),
      matching: find.byType(ProductionListTile),
    );
    await tester.tap(
      find.descendant(
        of: granaryTile,
        matching: find.widgetWithText(TextButton, 'PRODUCE'),
      ),
    );
    await tester.pump();

    expect(buildCount, 2);
    expect(find.byType(CityBuildingDetailsPanel), findsNothing);
  });

  testWidgets(
    'building help chart uses current city yield after clicking help',
    (tester) async {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        population: 1,
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CityProductionDialog(
              city: city,
              cityRuleset: CityRulesets.standard,
              research: ResearchState.empty,
              technologyRuleset: TechnologyRulesets.standard,
              mapData: _richFoodMap(),
              fieldImprovements: const [
                FieldImprovement(
                  hex: CityHex(col: 1, row: 0),
                  type: FieldImprovementType.farm,
                  builtByCityId: 'city_1',
                ),
              ],
              productionPerTurn: 2,
              onBuild: (_) {},
              onProduceUnit: (_) {},
            ),
          ),
        ),
      );

      await _scrollUntilVisible(tester, find.text('Granary'));
      await tester.tap(find.byTooltip('Building details'));
      await tester.pumpAndSettle();

      expect(find.byType(CityBuildingDetailsPanel), findsOneWidget);
      expect(find.text('CITY IMPACT'), findsOneWidget);
      expect(find.text('NOW'), findsOneWidget);
      expect(find.text('AFTER CHANGE'), findsOneWidget);
      final chartValues = tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .whereType<String>()
          .where((text) => text.contains('->'))
          .toList();
      expect(chartValues, contains('5 -> 7'));
      final beforeBar = tester.getSize(
        find.byKey(const Key('gameYieldDeltaComparison.beforeBar.0')),
      );
      final afterBar = tester.getSize(
        find.byKey(const Key('gameYieldDeltaComparison.afterBar.0')),
      );
      expect(beforeBar.width, greaterThan(0));
      expect(afterBar.width, greaterThan(beforeBar.width));
      expect(find.text('0 -> 2'), findsNothing);
    },
  );

  testWidgets(
    'portrait building help opens standalone full-width detail modal',
    (tester) async {
      tester.view.physicalSize = const Size(390, 840);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CityProductionDialog(
              city: city,
              cityRuleset: CityRulesets.standard,
              research: ResearchState.empty,
              technologyRuleset: TechnologyRulesets.standard,
              productionPerTurn: 2,
              onBuild: (_) {},
              onProduceUnit: (_) {},
            ),
          ),
        ),
      );

      await _scrollUntilVisible(tester, find.text('Granary'));
      await tester.tap(find.byTooltip('Building details'));
      await tester.pumpAndSettle();

      expect(find.byType(CityBuildingDetailsDialog), findsOneWidget);
      expect(find.byType(CityBuildingDetailsPanel), findsOneWidget);
      expect(
        find.byKey(const Key('cityProductionPanel.detailsLayer')),
        findsNothing,
      );

      final surface = tester.getRect(
        find.byKey(const Key('cityBuildingDetailsPanel.surface')),
      );
      expect(surface.width, greaterThan(340));
      expect(surface.width, lessThanOrEqualTo(390));
    },
  );

  testWidgets('portrait unit help opens standalone full-width detail modal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 840);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CityProductionDialog(
            city: city,
            cityRuleset: CityRulesets.standard,
            research: ResearchState.empty,
            technologyRuleset: TechnologyRulesets.standard,
            productionPerTurn: 2,
            onBuild: (_) {},
            onProduceUnit: (_) {},
          ),
        ),
      ),
    );

    await _scrollUntilVisible(tester, find.text('Warrior'));
    await tester.tap(find.byTooltip('Unit details').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(UnitDetailsPanel), findsOneWidget);
    expect(
      find.byKey(const Key('cityProductionPanel.detailsLayer')),
      findsNothing,
    );

    final surface = tester.getRect(
      find.byKey(const Key('unitDetailsPanel.surface')),
    );
    expect(surface.width, greaterThan(340));
    expect(surface.width, lessThanOrEqualTo(390));
  });

  testWidgets('shows next worker upkeep on worker production row', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
    );
    final workers = [
      for (var i = 0; i < 5; i++)
        GameUnit(
          id: 'worker_$i',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          name: GameUnitType.worker.defaultNameToken,
          col: i,
          row: 0,
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CityProductionDialog(
            city: city,
            cityRuleset: CityRulesets.standard,
            research: ResearchState.empty,
            technologyRuleset: TechnologyRulesets.standard,
            cities: const [city],
            units: workers,
            productionPerTurn: 2,
            onBuild: (_) {},
            onProduceUnit: (_) {},
          ),
        ),
      ),
    );

    await _scrollUntilVisible(tester, find.text('Worker'));

    expect(find.text('Worker'), findsOneWidget);
    expect(find.text('next upkeep: 2'), findsOneWidget);
  });

  testWidgets('keeps future buildings collapsed until requested', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CityProductionDialog(
            city: city,
            cityRuleset: CityRulesets.standard,
            research: ResearchState.empty,
            technologyRuleset: TechnologyRulesets.standard,
            productionPerTurn: 2,
            onBuild: (_) {},
            onProduceUnit: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Granary'), findsOneWidget);
    expect(find.textContaining('FUTURE BUILDINGS'), findsOneWidget);
    expect(find.text('Workshop'), findsNothing);

    await tester.tap(find.textContaining('FUTURE BUILDINGS'));
    await tester.pumpAndSettle();

    expect(find.text('Workshop'), findsOneWidget);
    expect(find.text('Requires: Craftsmanship'), findsOneWidget);
    expect(find.text('LOCKED'), findsWidgets);
  });

  testWidgets('does not render city economy breakdown in production panel', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 0, row: 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CityProductionDialog(
            city: city,
            cityRuleset: CityRulesets.standard,
            research: ResearchState.empty,
            technologyRuleset: TechnologyRulesets.standard,
            mapData: _map(),
            productionPerTurn: 2,
            onBuild: (_) {},
            onProduceUnit: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(CityProductionPanel), findsOneWidget);
    expect(find.text('City economy'), findsNothing);
  });

  testWidgets('mobile production panel uses compact header and list density', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CityProductionPanel(
            city: city,
            cityRuleset: CityRulesets.standard,
            research: ResearchState.empty,
            technologyRuleset: TechnologyRulesets.standard,
            productionPerTurn: 2,
            maxHeight: 500,
            onBuild: (_) {},
            onProduceUnit: (_) {},
            onClose: () {},
          ),
        ),
      ),
    );

    final panel = tester.getRect(find.byType(CityProductionPanel));
    final header = tester.getRect(find.byType(CityProductionHeader));
    expect(header.height, lessThanOrEqualTo(62));
    expect(find.text('CITY PROJECTS'), findsNothing);

    await _scrollUntilVisible(tester, find.text('CITY PROJECTS'));
    final projectsTitle = tester.getRect(find.text('CITY PROJECTS'));
    expect(projectsTitle.bottom, lessThanOrEqualTo(panel.bottom));

    await _scrollUntilVisible(tester, find.text('Wealth'));
    final firstProject = tester.getRect(find.text('Wealth'));
    expect(
      firstProject.bottom,
      lessThanOrEqualTo(panel.bottom),
      reason: 'compact production list keeps city projects reachable',
    );
  });
}

Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 180);
  await tester.pumpAndSettle();
}

MapData _map() {
  return MapData(
    cols: 1,
    rows: 1,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}

MapData _richFoodMap() {
  return MapData(
    cols: 2,
    rows: 1,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [ResourceType.wheat],
        height: 0,
      ),
    ],
  );
}
