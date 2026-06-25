import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MerchantTradeRouteRules', () {
    test('plans a route into an occupied owned city center', () {
      final merchant = _merchant(col: 0, row: 0);
      final blocker = _warrior(id: 'guard_1', col: 3, row: 0);
      final cities = [_city(id: 'origin', col: 0), _city(id: 'target', col: 3)];
      final mapData = _lineMap(4);

      final route = MerchantTradeRouteRules.planRoute(
        merchant: merchant,
        originCity: cities.first,
        destinationCity: cities.last,
        mapData: mapData,
        units: [merchant, blocker],
        cities: cities,
      );

      expect(route, isNotNull);
      expect(route!.destinationCityId, 'target');
      expect(route.steps.last.col, 3);
      expect(route.steps.last.row, 0);
    });

    test('lets only a merchant share an occupied owned city center', () {
      final city = _city(id: 'target', col: 3);
      final mapData = _lineMap(4);
      final blocker = _warrior(id: 'guard_1', col: 3, row: 0);
      final warrior = _warrior(id: 'warrior_1', col: 0, row: 0);
      final pathfinder = UnitMovementPathfinder(
        mapData: mapData,
        units: [warrior, blocker],
        canEnterOccupiedTile:
            ({
              required movingUnit,
              required blockingUnit,
              required col,
              required row,
            }) => MerchantTradeRouteRules.canShareOccupiedCityTile(
              movingUnit: movingUnit,
              col: col,
              row: row,
              cities: [city],
            ),
      );

      final plan = pathfinder.plan(
        unit: warrior,
        targetTile: mapData.tileAt(3, 0)!,
      );

      expect(plan, isNull);
      expect(
        MerchantTradeRouteRules.canShareOccupiedCityTile(
          movingUnit: _merchant(col: 0, row: 0),
          col: 3,
          row: 0,
          cities: [city],
        ),
        isTrue,
      );
      expect(
        MerchantTradeRouteRules.canShareOccupiedCityTile(
          movingUnit: warrior,
          col: 3,
          row: 0,
          cities: [city],
        ),
        isFalse,
      );
    });

    test(
      'plans city travel from outside a city into occupied owned center',
      () {
        final merchant = _merchant(col: 1, row: 0);
        final blocker = _warrior(id: 'guard_1', col: 3, row: 0);
        final target = _city(id: 'target', col: 3);

        final plan = MerchantTradeRouteRules.planMoveToCity(
          merchant: merchant,
          destinationCity: target,
          mapData: _lineMap(4),
          units: [merchant, blocker],
          cities: [target],
        );

        expect(plan, isNotNull);
        expect(plan!.targetCol, 3);
        expect(plan.targetRow, 0);
        expect(plan.steps.last.col, 3);
      },
    );

    test('advances into occupied owned city centers', () {
      final merchant = _merchant(col: 0, row: 0).copyWithMerchantTradeRoute(
        _route(originCityId: 'origin', destinationCityId: 'target', toCol: 3),
      );
      final blocker = _warrior(id: 'guard_1', col: 3, row: 0);
      final cities = [_city(id: 'origin', col: 0), _city(id: 'target', col: 3)];

      final result = MerchantTradeRouteRules.advanceUnit(
        unit: merchant,
        units: [merchant, blocker],
        cities: cities,
        mapData: _lineMap(4),
      );

      expect(result.movedSteps.map((step) => step.col), [1, 2, 3]);
      expect(result.unit.col, 3);
      expect(result.unit.row, 0);
      expect(result.unit.merchantTradeRoute?.originCityId, 'target');
      expect(result.unit.merchantTradeRoute?.destinationCityId, 'origin');
    });

    test('stops before a unit blocking a non-city route hex', () {
      final merchant = _merchant(col: 0, row: 0).copyWithMerchantTradeRoute(
        _route(originCityId: 'origin', destinationCityId: 'target', toCol: 3),
      );
      final blocker = _warrior(id: 'guard_1', col: 1, row: 0);
      final cities = [_city(id: 'origin', col: 0), _city(id: 'target', col: 3)];

      final result = MerchantTradeRouteRules.advanceUnit(
        unit: merchant,
        units: [merchant, blocker],
        cities: cities,
        mapData: _lineMap(4),
      );

      expect(result.movedSteps, isEmpty);
      expect(result.unit.col, 0);
      expect(result.unit.row, 0);
      expect(result.unit.merchantTradeRoute, isNotNull);
    });
  });
}

GameUnit _merchant({required int col, required int row}) {
  return GameUnit(
    id: 'merchant_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.merchant,
    name: GameUnitType.merchant.defaultNameToken,
    col: col,
    row: row,
  );
}

GameUnit _warrior({required String id, required int col, required int row}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    name: GameUnitType.warrior.defaultNameToken,
    col: col,
    row: row,
  );
}

GameCity _city({required String id, required int col}) {
  return GameCity(
    id: id,
    ownerPlayerId: 'player_1',
    name: id,
    center: CityHex(col: col, row: 0),
    controlledHexes: [CityHex(col: col, row: 0)],
  );
}

MerchantTradeRoute _route({
  required String originCityId,
  required String destinationCityId,
  required int toCol,
}) {
  return MerchantTradeRoute(
    originCityId: originCityId,
    destinationCityId: destinationCityId,
    steps: [
      for (var col = 0; col <= toCol; col++)
        UnitMovementStep(
          col: col,
          row: 0,
          enterCost: col == 0 ? 0 : 1,
          cumulativeCost: col,
        ),
    ],
  );
}

MapData _lineMap(int cols) {
  return MapData(
    cols: cols,
    rows: 1,
    tiles: [
      for (var col = 0; col < cols; col++)
        TileData(
          col: col,
          row: 0,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
