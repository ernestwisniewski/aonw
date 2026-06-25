import 'package:aonw/game/presentation/widgets/resources/resource_breakdown_popup.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_strip.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const city = GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'Krakow',
    center: CityHex(col: 1, row: 1),
  );
  const upkeep = UnitUpkeepBreakdown(
    playerId: 'player_1',
    unitCount: 3,
    freeUnitCount: 2,
    paidUnitCount: 1,
    grossUpkeep: 1,
    paidUnitsByType: {GameUnitType.warrior: 1},
    upkeepByType: {GameUnitType.warrior: 1},
  );

  testWidgets('ResourceBreakdownPopup renders gold summary and closes', (
    tester,
  ) async {
    var closes = 0;

    await _pumpPopup(
      tester,
      type: ResourceBreakdownType.gold,
      gold: const GoldBreakdown(
        treasury: 42,
        citySources: [GoldCitySource(city: city, amount: 4)],
        projectSources: [GoldProjectSource(city: city, amount: 3)],
        upkeep: upkeep,
      ),
      onClose: () => closes++,
    );

    expect(find.text('Gold'), findsOneWidget);
    expect(find.text('Treasury'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('City income'), findsOneWidget);
    expect(find.text('+4'), findsAtLeastNWidgets(1));
    expect(find.text('Projects'), findsAtLeastNWidgets(1));
    expect(find.text('+3'), findsAtLeastNWidgets(1));
    expect(find.text('Krakow: Wealth'), findsOneWidget);
    expect(find.text('Upkeep'), findsOneWidget);
    expect(find.text('-1'), findsAtLeastNWidgets(1));
    expect(find.text('Next worker upkeep'), findsOneWidget);
    expect(find.text('-1 gold/turn'), findsOneWidget);
    expect(find.text('Net / turn'), findsOneWidget);
    expect(find.text('+6'), findsOneWidget);
    expect(find.text('Krakow'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));

    expect(closes, 1);
  });

  testWidgets('ResourceBreakdownPopup renders science details', (tester) async {
    await _pumpPopup(
      tester,
      type: ResourceBreakdownType.science,
      science: const ScienceYieldBreakdown(
        total: 8,
        byCityId: {'city_1': 8},
        sources: [
          ScienceYieldSource(
            cityId: 'city_1',
            amount: 6,
            label: 'City science',
          ),
          ScienceYieldSource(
            cityId: 'city_1',
            amount: 2,
            label: 'City research project',
          ),
        ],
      ),
      activeTechnologyName: 'Gornictwo',
      activeTechnologyTurnsRemaining: 3,
      activeTechnologyCompletionTurn: 8,
    );

    expect(find.text('Science and research'), findsOneWidget);
    expect(find.text('Science / turn'), findsOneWidget);
    expect(find.text('+8'), findsOneWidget);
    expect(find.text('+6'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('Active research'), findsOneWidget);
    expect(find.text('Gornictwo'), findsOneWidget);
    expect(find.text('To complete'), findsOneWidget);
    expect(find.text('3 turns • turn 8'), findsOneWidget);
    expect(find.text('Krakow'), findsOneWidget);
    expect(find.text('Krakow: Research'), findsOneWidget);
  });

  testWidgets('ResourceBreakdownPopup renders resource inventory sources', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();

    await _pumpPopup(
      tester,
      type: ResourceBreakdownType.resources,
      resources: const CityResourceInventory(
        playerId: 'player_1',
        countsByType: {ResourceType.iron: 2, ResourceType.horses: 1},
        sources: [
          CityResourceSource(
            cityId: 'city_1',
            hex: CityHex(col: 2, row: 3),
            resource: ResourceType.iron,
          ),
        ],
      ),
    );

    expect(find.text('Resources'), findsOneWidget);
    expect(find.text('Controlled deposits'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Resource types'), findsOneWidget);
    expect(find.text('2'), findsAtLeastNWidgets(1));
    expect(find.text(l10n.resourceIron), findsAtLeastNWidgets(1));
    expect(find.text(l10n.resourceHorses), findsOneWidget);
    expect(find.text('Krakow (2, 3)'), findsOneWidget);
  });

  testWidgets('ResourceBreakdownPopup renders hidden resource gates', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();

    await _pumpPopup(
      tester,
      type: ResourceBreakdownType.resources,
      resourceNetwork: const EmpireResourceNetwork(
        playerId: 'player_1',
        visibleInventory: CityResourceInventory(
          playerId: 'player_1',
          countsByType: {ResourceType.iron: 1},
          sources: [
            CityResourceSource(
              cityId: 'city_1',
              hex: CityHex(col: 1, row: 1),
              resource: ResourceType.iron,
            ),
          ],
        ),
        hiddenCountsByType: {ResourceType.oil: 1},
        hiddenSources: [
          CityResourceSource(
            cityId: 'city_1',
            hex: CityHex(col: 2, row: 1),
            resource: ResourceType.oil,
          ),
        ],
        unitGates: [
          EmpireResourceUnitGate(
            unitType: GameUnitType.tank,
            resourceChoices: {ResourceType.oil},
            visibleControlledResources: {},
            hiddenControlledResources: {ResourceType.oil},
          ),
        ],
      ),
    );

    expect(find.text(l10n.resourceOil), findsAtLeastNWidgets(1));
    expect(find.text('?x1'), findsOneWidget);
    expect(find.text('Krakow (2, 1)'), findsOneWidget);
    expect(find.text(l10n.unitTank), findsOneWidget);
    expect(find.text('? ${l10n.resourceOil}'), findsAtLeastNWidgets(1));
  });
}

Future<void> _pumpPopup(
  WidgetTester tester, {
  required ResourceBreakdownType type,
  GoldBreakdown gold = const GoldBreakdown(
    treasury: 0,
    citySources: [],
    projectSources: [],
    upkeep: UnitUpkeepBreakdown(
      playerId: 'player_1',
      unitCount: 0,
      freeUnitCount: 0,
      paidUnitCount: 0,
      grossUpkeep: 0,
    ),
  ),
  ScienceYieldBreakdown science = ScienceYieldBreakdown.empty,
  CityResourceInventory resources = CityResourceInventory.empty,
  EmpireResourceNetwork resourceNetwork = EmpireResourceNetwork.empty,
  String? activeTechnologyName,
  int? activeTechnologyTurnsRemaining,
  int? activeTechnologyCompletionTurn,
  VoidCallback? onClose,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: ResourceBreakdownPopup(
            type: type,
            gold: gold,
            science: science,
            resources: resources,
            resourceNetwork: resourceNetwork,
            cities: const [
              GameCity(
                id: 'city_1',
                ownerPlayerId: 'player_1',
                name: 'Krakow',
                center: CityHex(col: 1, row: 1),
              ),
            ],
            activeTechnologyName: activeTechnologyName,
            activeTechnologyTurnsRemaining: activeTechnologyTurnsRemaining,
            activeTechnologyCompletionTurn: activeTechnologyCompletionTurn,
            l10n: AppLocalizationsEn(),
            onClose: onClose ?? () {},
          ),
        ),
      ),
    ),
  );
}
