import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('merchant trade route replanning', () {
    test('persists a replanned route while a merchant is stationary', () {
      final merchant = _merchant(col: 0)
          .copyWith(movementUnits: 0)
          .copyWithMerchantTradeRoute(
            MerchantTradeRoute(
              originCityId: 'origin',
              destinationCityId: 'target',
              transportNetworkFingerprint: 'stale',
              steps: _route().steps,
            ),
          );
      final blocker = _warrior(col: 3);
      final cities = [_city(id: 'origin', col: 0), _city(id: 'target', col: 3)];

      final result = MerchantTradeRouteRules.advanceUnit(
        unit: merchant,
        units: [merchant, blocker],
        cities: cities,
        mapData: _lineMap(),
      );

      expect(result.routeInvalidated, isFalse);
      expect(result.movedSteps, isEmpty);
      expect(result.unit.merchantTradeRoute, isNotNull);
      expect(result.unit.merchantTradeRoute!.transportNetworkFingerprint, '');
    });

    test('invalidates a stale route that cannot be replanned', () {
      final merchant = _merchant(col: 4).copyWithMerchantTradeRoute(_route());
      final cities = [_city(id: 'origin', col: 0), _city(id: 'target', col: 3)];

      final result = MerchantTradeRouteRules.advanceUnit(
        unit: merchant,
        units: [merchant],
        cities: cities,
        mapData: _lineMap(),
      );

      expect(result.routeInvalidated, isTrue);
      expect(result.unit.merchantTradeRoute, isNull);
    });
  });
}

GameUnit _merchant({required int col}) => GameUnit(
  id: 'merchant_1',
  ownerPlayerId: 'player_1',
  type: GameUnitType.merchant,
  name: GameUnitType.merchant.defaultNameToken,
  col: col,
  row: 0,
);

GameUnit _warrior({required int col}) => GameUnit(
  id: 'guard_1',
  ownerPlayerId: 'player_1',
  type: GameUnitType.warrior,
  name: GameUnitType.warrior.defaultNameToken,
  col: col,
  row: 0,
);

GameCity _city({required String id, required int col}) => GameCity(
  id: id,
  ownerPlayerId: 'player_1',
  name: id,
  center: CityHex(col: col, row: 0),
  controlledHexes: [CityHex(col: col, row: 0)],
);

MerchantTradeRoute _route() => MerchantTradeRoute(
  originCityId: 'origin',
  destinationCityId: 'target',
  steps: [
    for (var col = 0; col <= 3; col++)
      UnitMovementStep(
        col: col,
        row: 0,
        enterCost: col == 0 ? 0 : 1,
        cumulativeCost: col,
      ),
  ],
);

WorldMap _lineMap() => WorldMap(
  cols: 4,
  rows: 1,
  tiles: [
    for (var col = 0; col < 4; col++)
      WorldTile(
        col: col,
        row: 0,
        terrains: const [TerrainType.plains],
        resources: const [],
        height: 0,
      ),
  ],
);
