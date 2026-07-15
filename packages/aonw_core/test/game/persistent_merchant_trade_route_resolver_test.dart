import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  const resolver = PersistentMerchantTradeRouteResolver();

  group('PersistentMerchantTradeRouteResolver', () {
    test('assigns a route between owned cities', () {
      final result = resolver.assignRoute(
        state: _state(merchantCol: 0),
        command: const AssignMerchantTradeRouteCommand('merchant_1', 'city_2'),
        actorPlayerId: 'player_1',
        mapData: WorldMapReadView(_lineMap()),
      );

      expect(result.accepted, isTrue);
      final merchant = result.state.units.single;
      expect(merchant.merchantTradeRoute?.originCityId, 'city_1');
      expect(merchant.merchantTradeRoute?.destinationCityId, 'city_2');
      expect(merchant.queuedPath, isNull);
    });

    test('queues travel to an owned city', () {
      final result = resolver.moveToCity(
        state: _state(merchantCol: 1),
        command: const MoveMerchantToCityCommand('merchant_1', 'city_2'),
        actorPlayerId: 'player_1',
        mapData: WorldMapReadView(_lineMap()),
      );

      expect(result.accepted, isTrue);
      final merchant = result.state.units.single;
      expect(merchant.queuedPath?.targetCol, 3);
      expect(merchant.queuedPath?.targetRow, 0);
      expect(merchant.merchantTradeRoute, isNull);
    });
  });
}

PersistentGameState _state({required int merchantCol}) {
  return PersistentGameState(
    units: [
      GameUnit(
        id: 'merchant_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.merchant,
        name: GameUnitType.merchant.defaultNameToken,
        col: merchantCol,
        row: 0,
      ),
    ],
    cities: const [
      GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'city_1',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 0, row: 0)],
      ),
      GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_1',
        name: 'city_2',
        center: CityHex(col: 3, row: 0),
        controlledHexes: [CityHex(col: 3, row: 0)],
      ),
    ],
  );
}

WorldMap _lineMap() {
  return WorldMap(
    cols: 4,
    rows: 1,
    tiles: [
      for (var col = 0; col < 4; col++)
        WorldTile(
          coordinate: HexCoord(col: col, row: 0),
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
