import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_strategic_resource_summary.dart';
import 'package:aonw/game/presentation/widgets/resources/strategic_resource_economy_dialog.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'strategic economy presents alerts, flows, consumers, sources and trade',
    (tester) async {
      GameCity? selectedCity;
      String? selectedPartnerId;

      await _pumpPanel(
        tester,
        onCityPressed: (city) => selectedCity = city,
        onTradePartnerPressed: (playerId) => selectedPartnerId = playerId,
      );

      expect(find.text('Strategic economy'), findsOneWidget);
      expect(find.text('2 issues require attention.'), findsOneWidget);
      expect(find.text('Economic alerts'), findsOneWidget);
      expect(find.text('No free oil'), findsOneWidget);
      expect(find.text('oil agreement expires in 2 turns'), findsOneWidget);

      expect(find.text('Strategic resources'), findsOneWidget);
      expect(
        find.byKey(const Key('strategicResourceEconomy.resource.oil')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('strategicResourceEconomy.resource.aluminium')),
        findsOneWidget,
      );
      expect(find.text('Production allocations'), findsOneWidget);
      expect(find.text('Tank · Krakow'), findsOneWidget);
      expect(find.text('2 oil'), findsOneWidget);
      expect(find.text('oil · Oil Well'), findsOneWidget);
      expect(find.textContaining('Importing: 1 oil/turn'), findsOneWidget);
      expect(find.text('Trade partners'), findsOneWidget);
      expect(find.text('Bob'), findsAtLeastNWidgets(1));

      final allocation = find.byKey(
        const Key('strategicResourceEconomy.allocation.city_1'),
      );
      await tester.ensureVisible(allocation);
      await tester.tap(allocation);
      expect(selectedCity?.id, 'city_1');

      final tradeAction = find.byKey(
        const Key('strategicResourceEconomy.openTrade.player_2'),
      );
      await tester.ensureVisible(tradeAction);
      await tester.tap(tradeAction);
      expect(selectedPartnerId, 'player_2');
    },
  );

  testWidgets('strategic economy remains overflow-free on a narrow phone', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    await _pumpPanel(tester);

    expect(find.text('Strategic economy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  ValueChanged<GameCity>? onCityPressed,
  ValueChanged<String>? onTradePartnerPressed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StrategicResourceEconomyPanel(
          summary: _summary,
          gameState: _state,
          gameSave: _save,
          activePlayerId: 'player_1',
          onClose: () {},
          onCityPressed: onCityPressed ?? (_) {},
          onTradePartnerPressed: onTradePartnerPressed ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}

final _city = GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'Krakow',
  center: const CityHex(col: 1, row: 1),
  productionQueue: CityProductionQueue.unit(
    unitType: GameUnitType.tank,
    investedProduction: 20,
    resourceAllocation: StrategicResourceBundle.oilTwo,
  ),
);

final _summary = HudStrategicResourceSummary(
  enabled: true,
  rows: const [
    HudStrategicResourceRow(
      resource: ResourceType.oil,
      available: 0,
      allocated: 2,
      domesticProduction: 1,
      imports: 1,
      exports: 0,
      sourceCount: 1,
      shortage: true,
    ),
    HudStrategicResourceRow(
      resource: ResourceType.aluminium,
      available: 3,
      allocated: 0,
      domesticProduction: 1,
      imports: 0,
      exports: 1,
      sourceCount: 0,
      shortage: false,
    ),
  ],
  allocations: [
    HudStrategicResourceAllocation(
      city: _city,
      bundle: StrategicResourceBundle.oilTwo,
    ),
  ],
  sources: [
    HudStrategicResourceSource(
      city: _city,
      hex: const CityHex(col: 2, row: 2),
      resource: ResourceType.oil,
      improvement: FieldImprovementType.oilWell,
      amountPerTurn: 1,
    ),
  ],
);

final _state = GameClientState(
  activePlayerId: 'player_1',
  cities: [_city],
  diplomacy: DiplomacyState.empty.addContact('player_1', 'player_2'),
  resourceTradeAgreements: const [
    ResourceTradeAgreement(
      id: 'oil-import',
      exporterPlayerId: 'player_2',
      importerPlayerId: 'player_1',
      resource: ResourceType.oil,
      goldPerTurn: 2,
      remainingTurns: 2,
    ),
  ],
);

final _save = GameSave(
  id: 'save',
  name: 'Game',
  mapName: 'verdantia',
  turn: 6,
  savedAt: DateTime.utc(2026, 8, 12),
  camera: CameraState.zero,
  players: const [
    Player(id: 'player_1', name: 'Alice', colorValue: 0xFF2563EB),
    Player(
      id: 'player_2',
      name: 'Bob',
      colorValue: 0xFFDC2626,
      country: PlayerCountry.germany,
    ),
  ],
  playerStates: const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.active,
  },
);
