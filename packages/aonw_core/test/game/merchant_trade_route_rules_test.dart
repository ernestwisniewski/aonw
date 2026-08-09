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

    test('preserves exact plans through the WorldMap traversal view', () {
      final mapData = _mixedLineMap();
      final worldMap = _worldMapFrom(mapData, reverseTiles: true);
      final cities = [_city(id: 'origin', col: 0), _city(id: 'target', col: 3)];
      final blocker = _warrior(id: 'guard_1', col: 3, row: 0);
      final routeMerchant = _merchant(col: 0, row: 0);

      final legacyRoute = MerchantTradeRouteRules.planRoute(
        merchant: routeMerchant,
        originCity: cities.first,
        destinationCity: cities.last,
        mapData: mapData,
        units: [routeMerchant, blocker],
        cities: cities,
      );
      final canonicalRoute = MerchantTradeRouteRules.planRoute(
        merchant: routeMerchant,
        originCity: cities.first,
        destinationCity: cities.last,
        mapData: worldMap,
        units: [routeMerchant, blocker],
        cities: cities,
      );

      final expectedRoute = MerchantTradeRoute(
        originCityId: 'origin',
        destinationCityId: 'target',
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 2, cumulativeCost: 2),
          UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 3),
          UnitMovementStep(col: 3, row: 0, enterCost: 2, cumulativeCost: 5),
        ],
      );
      expect(legacyRoute, expectedRoute);
      expect(canonicalRoute, expectedRoute);

      final cityMerchant = _merchant(col: 1, row: 0);
      final legacyMove = MerchantTradeRouteRules.planMoveToCity(
        merchant: cityMerchant,
        destinationCity: cities.last,
        mapData: mapData,
        units: [cityMerchant, blocker],
        cities: cities,
      );
      final canonicalMove = MerchantTradeRouteRules.planMoveToCity(
        merchant: cityMerchant,
        destinationCity: cities.last,
        mapData: worldMap,
        units: [cityMerchant, blocker],
        cities: cities,
      );

      const expectedMoveSteps = [
        UnitMovementStep(col: 1, row: 0, enterCost: 0, cumulativeCost: 0),
        UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 1),
        UnitMovementStep(col: 3, row: 0, enterCost: 2, cumulativeCost: 3),
      ];
      expect(legacyMove?.steps, expectedMoveSteps);
      expect(canonicalMove?.steps, expectedMoveSteps);
      expect(legacyMove?.totalCost, 3);
      expect(canonicalMove?.totalCost, 3);
      expect(legacyMove?.targetCol, 3);
      expect(canonicalMove?.targetCol, 3);
    });

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

    test('exhausts its positive remainder on the next costly route step', () {
      final merchant = _merchant(col: 0, row: 0).copyWithMerchantTradeRoute(
        MerchantTradeRoute(
          originCityId: 'origin',
          destinationCityId: 'target',
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 1, row: 0, enterCost: 2, cumulativeCost: 2),
            UnitMovementStep(col: 2, row: 0, enterCost: 2, cumulativeCost: 4),
            UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 5),
          ],
        ),
      );
      final cities = [_city(id: 'origin', col: 0), _city(id: 'target', col: 3)];

      final result = MerchantTradeRouteRules.advanceUnit(
        unit: merchant,
        units: [merchant],
        cities: cities,
        mapData: _roughLineMap(),
      );

      expect(result.movedSteps.map((step) => step.col), [1, 2]);
      expect((result.unit.col, result.unit.movementPoints), (2, 0));
      expect(result.unit.merchantTradeRoute, isNotNull);
    });

    test('rejects and invalidates routes beyond per-turn capacity', () {
      final cities = [_city(id: 'origin', col: 0), _city(id: 'target', col: 2)];
      final merchant = _merchant(col: 0, row: 0);
      final map = _overCapacityLineMap();

      final planned = MerchantTradeRouteRules.planRoute(
        merchant: merchant,
        originCity: cities.first,
        destinationCity: cities.last,
        mapData: map,
        units: [merchant],
        cities: cities,
      );
      final persisted = merchant.copyWithMerchantTradeRoute(
        MerchantTradeRoute(
          originCityId: 'origin',
          destinationCityId: 'target',
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 1, row: 0, enterCost: 4, cumulativeCost: 4),
            UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 5),
          ],
        ),
      );

      final advanced = MerchantTradeRouteRules.advanceUnit(
        unit: persisted,
        units: [persisted],
        cities: cities,
        mapData: map,
      );

      expect(planned, isNull);
      expect(advanced.routeInvalidated, isTrue);
      expect(advanced.movedSteps, isEmpty);
      expect((advanced.unit.col, advanced.unit.row), (0, 0));
      expect(advanced.unit.merchantTradeRoute, isNull);
    });

    test('preserves the artifact-carrier rough-terrain exception', () {
      final cities = [_city(id: 'origin', col: 0), _city(id: 'target', col: 2)];
      final merchant = _merchant(
        col: 0,
        row: 0,
      ).copyWith(movementPoints: 2).copyWithCarriedArtifact('artifact_1');
      final map = _overCapacityLineMap();
      final route = MerchantTradeRouteRules.planRoute(
        merchant: merchant,
        originCity: cities.first,
        destinationCity: cities.last,
        mapData: map,
        units: [merchant],
        cities: cities,
      );

      final advanced = MerchantTradeRouteRules.advanceUnit(
        unit: merchant.copyWithMerchantTradeRoute(route),
        units: [merchant],
        cities: cities,
        mapData: map,
      );

      expect(route, isNotNull);
      expect(advanced.routeInvalidated, isFalse);
      expect(advanced.movedSteps.map((step) => step.col), [1]);
      expect((advanced.unit.col, advanced.unit.movementPoints), (1, 0));
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

WorldMap _lineMap(int cols) {
  return WorldMap(
    cols: cols,
    rows: 1,
    tiles: [
      for (var col = 0; col < cols; col++)
        WorldTile(
          col: col,
          row: 0,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
    ],
  );
}

WorldMap _mixedLineMap() {
  return WorldMap(
    cols: 4,
    rows: 1,
    tiles: [
      WorldTile(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      WorldTile(
        col: 1,
        row: 0,
        terrains: [TerrainType.plains, TerrainType.forest],
        resources: [],
        height: 1,
      ),
      WorldTile(
        col: 2,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      WorldTile(
        col: 3,
        row: 0,
        terrains: [TerrainType.plains, TerrainType.hills],
        resources: [],
        height: 2,
      ),
    ],
  );
}

WorldMap _roughLineMap() {
  return WorldMap(
    cols: 4,
    rows: 1,
    tiles: [
      for (var col = 0; col < 4; col++)
        WorldTile(
          col: col,
          row: 0,
          terrains: col == 1 || col == 2
              ? const [TerrainType.plains, TerrainType.forest]
              : const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
    ],
  );
}

WorldMap _overCapacityLineMap() {
  return WorldMap(
    cols: 3,
    rows: 1,
    tiles: [
      for (var col = 0; col < 3; col++)
        WorldTile(
          col: col,
          row: 0,
          terrains: col == 1
              ? const [
                  TerrainType.grassland,
                  TerrainType.forest,
                  TerrainType.jungle,
                  TerrainType.hills,
                ]
              : const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
    ],
  );
}

WorldMap _worldMapFrom(WorldMap mapData, {required bool reverseTiles}) {
  final tiles = [
    for (final tile in mapData.tiles)
      WorldTile.at(
        coordinate: HexCoord(col: tile.col, row: tile.row),
        terrains: tile.terrains,
        resources: tile.resources,
        height: tile.height,
      ),
  ];
  return WorldMap(
    cols: mapData.cols,
    rows: mapData.rows,
    tiles: reverseTiles ? tiles.reversed : tiles,
  );
}
