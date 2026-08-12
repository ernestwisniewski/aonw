import 'dart:async';

import 'package:aonw/game/presentation/widgets/city/city_production_dialog.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_dialog_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('view model quotes strategic stockpile costs', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Miasto',
      center: CityHex(col: 1, row: 1),
      population: 8,
    );
    final research = ResearchState(
      players: {
        'player_1': PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.massProduction},
        ),
      },
    );

    CityProductionDialogViewModel build(StrategicResourceAccounts accounts) {
      return CityProductionDialogViewModel.from(
        city,
        l10n: l10n,
        cityRuleset: CityRulesets.standard,
        research: research,
        technologyRuleset: TechnologyRulesets.standard,
        mapData: null,
        cities: const [city],
        units: const [],
        fieldImprovements: const [],
        strategicResources: accounts,
        strategicResourceEconomy: StrategicResourceEconomyProfile.stockpileV1,
        productionPerTurn: 4,
      );
    }

    final blocked = build(StrategicResourceAccounts.empty);
    final tankWithoutOil = blocked.itemForUnit(GameUnitType.tank)!;
    expect(tankWithoutOil.locked, isTrue);
    expect(tankWithoutOil.strategicResourceLabel, 'Cost: 2 oil');
    expect(tankWithoutOil.requirementLabel, 'Insufficient stock: 0/2 oil');
    expect(blocked.strategicResourceSummaryLabel, contains('0 oil'));

    final available = build(
      StrategicResourceAccounts(
        byPlayerId: {
          'player_1': StrategicResourceStockpile(
            onHand: StrategicResourceBundle.oilTwo,
          ),
        },
      ),
    ).itemForUnit(GameUnitType.tank)!;
    expect(available.locked, isFalse);
    expect(available.strategicResourceLabel, 'Cost: 2 oil');
    expect(available.requirementLabel, isNull);
  });

  test('active production exposes its reserved strategic resources', () {
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Miasto',
      center: const CityHex(col: 1, row: 1),
      population: 8,
      productionQueue: CityProductionQueue.unit(
        unitType: GameUnitType.tank,
        investedProduction: 12,
        resourceAllocation: StrategicResourceBundle.oilTwo,
      ),
    );
    final viewModel = CityProductionDialogViewModel.from(
      city,
      l10n: l10n,
      cityRuleset: CityRulesets.standard,
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.massProduction},
          ),
        },
      ),
      technologyRuleset: TechnologyRulesets.standard,
      mapData: null,
      cities: [city],
      units: const [],
      fieldImprovements: const [],
      strategicResourceEconomy: StrategicResourceEconomyProfile.stockpileV1,
      productionPerTurn: 4,
    );

    final tank = viewModel.itemForUnit(GameUnitType.tank)!;
    expect(tank.active, isTrue);
    expect(tank.locked, isFalse);
    expect(tank.strategicResourceLabel, 'Allocated: 2 oil');
  });

  testWidgets('list explains a strategic resource shortage', (tester) async {
    var productionAttempts = 0;
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
                unitType: GameUnitType.tank,
                projectType: null,
                title: 'Tank',
                emoji: null,
                icon: GameIcons.warrior,
                active: false,
                investedProduction: 0,
                totalCost: 84,
                productionPerTurn: 5,
                turnsRemaining: 17,
                rushGoldCost: 0,
                locked: true,
                requirementLabel: 'Insufficient stock: 0/2 oil',
                buildingState: null,
                strategicResourceLabel: 'Cost: 2 oil',
                strategicResourceShortage: true,
              ),
            ],
            projects: const [],
            specializations: const [],
            onBuildingDetails: (_) {},
            onUnitDetails: (_) {},
            onWonderDetails: (_) {},
            onBuild: (_) {},
            onProduceUnit: (_) => productionAttempts++,
            onStartProject: null,
            onSetSpecialization: null,
          ),
        ),
      ),
    );

    expect(find.text('Cost: 2 oil'), findsOneWidget);
    expect(find.text('Insufficient stock: 0/2 oil'), findsOneWidget);
    expect(find.text('LOCKED'), findsOneWidget);
    await tester.tap(find.text('Tank'));
    await tester.pump();
    expect(productionAttempts, 0);
  });

  testWidgets(
    'explicit resource option and replacement confirmation expose allocation delta',
    (tester) async {
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Air Base',
        center: const CityHex(col: 0, row: 0),
        population: 8,
        productionQueue: CityProductionQueue.unit(
          unitType: GameUnitType.tank,
          investedProduction: 12,
          resourceAllocation: StrategicResourceBundle.oilTwo,
        ),
      );
      GameUnitType? requestedType;
      int? requestedOption;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CityProductionPanel(
              city: city,
              cityRuleset: CityRulesets.standard,
              research: ResearchState(
                players: {
                  'player_1': PlayerResearchState(
                    unlockedTechnologyIds: {
                      TechnologyId.flight,
                      TechnologyId.massProduction,
                    },
                  ),
                },
              ),
              technologyRuleset: TechnologyRulesets.standard,
              mapData: _oneTileMap(),
              cities: [city],
              strategicResources: StrategicResourceAccounts(
                byPlayerId: {
                  'player_1': StrategicResourceStockpile(
                    onHand: StrategicResourceBundle.aluminiumOne,
                  ),
                },
              ),
              strategicResourceEconomy:
                  StrategicResourceEconomyProfile.stockpileV1,
              productionPerTurn: 4,
              onBuild: (_) {},
              onProduceUnit: (_) {},
              onProduceUnitRequested: (type, option) async {
                requestedType = type;
                requestedOption = option;
              },
              onClose: () {},
            ),
          ),
        ),
      );

      await _scrollTo(tester, find.text('Recon Plane'));
      await tester.tap(find.text('Recon Plane'));
      await tester.pumpAndSettle();

      expect(find.text('Choose strategic resources'), findsOneWidget);
      expect(find.text('1 aluminum'), findsOneWidget);
      expect(find.text('1 oil'), findsOneWidget);

      await tester.tap(find.text('1 aluminum'));
      await tester.pumpAndSettle();

      expect(find.text('Change production?'), findsOneWidget);
      expect(find.text('Releases: 2 oil'), findsOneWidget);
      expect(find.text('Allocates: 1 aluminum'), findsOneWidget);
      expect(
        find.textContaining('Free after change: 2 oil · 0 aluminum'),
        findsOneWidget,
      );

      await tester.tap(find.text('Change production'));
      await tester.pumpAndSettle();

      expect(requestedType, GameUnitType.reconPlane);
      expect(requestedOption, 0);
    },
  );

  testWidgets('pending selection prevents duplicate production commands', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Factory',
      center: CityHex(col: 0, row: 0),
      population: 8,
    );
    final pending = Completer<void>();
    var requests = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CityProductionPanel(
            city: city,
            cityRuleset: CityRulesets.standard,
            research: ResearchState(
              players: {
                'player_1': PlayerResearchState(
                  unlockedTechnologyIds: {TechnologyId.massProduction},
                ),
              },
            ),
            technologyRuleset: TechnologyRulesets.standard,
            mapData: _oneTileMap(),
            cities: const [city],
            strategicResources: StrategicResourceAccounts(
              byPlayerId: {
                'player_1': StrategicResourceStockpile(
                  onHand: StrategicResourceBundle.oilTwo,
                ),
              },
            ),
            strategicResourceEconomy:
                StrategicResourceEconomyProfile.stockpileV1,
            productionPerTurn: 4,
            onBuild: (_) {},
            onProduceUnit: (_) {},
            onProduceUnitRequested: (_, _) {
              requests++;
              return pending.future;
            },
            onClose: () {},
          ),
        ),
      ),
    );

    await _scrollTo(tester, find.text('Tank'));
    await tester.tap(find.text('Tank'));
    await tester.pump();

    expect(
      find.byKey(const Key('cityProductionPanel.pending')),
      findsOneWidget,
    );
    await tester.tap(find.text('Tank'), warnIfMissed: false);
    await tester.pump();
    expect(requests, 1);

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cityProductionPanel.pending')), findsNothing);
  });
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

WorldMap _oneTileMap() => WorldMap(
  cols: 1,
  rows: 1,
  tiles: [
    WorldTile(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);
