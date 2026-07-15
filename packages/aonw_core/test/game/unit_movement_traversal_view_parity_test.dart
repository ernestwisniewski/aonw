import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('UnitMovementPathfinder traversal view', () {
    test('matches MapData on sparse mixed terrain with occupied hexes', () {
      final mapData = _sparseMixedMap();
      final worldView = LegacyWorldMapAdapter.asTraversalView(
        _reversedWorldMap(mapData),
      );
      final movingUnit = _unit(id: 'scout', col: 0, row: 1);
      final units = [
        movingUnit,
        _unit(id: 'route_blocker', col: 2, row: 1),
        _unit(id: 'target_blocker', col: 4, row: 1),
      ];
      final legacy = UnitMovementPathfinder(mapData: mapData, units: units);
      final canonical = UnitMovementPathfinder(
        mapData: worldView,
        units: units,
      );

      final legacyPlan = legacy.plan(
        unit: movingUnit,
        targetTile: mapData.tileAt(5, 2)!,
      );
      final canonicalPlan = canonical.plan(
        unit: movingUnit,
        targetTile: worldView.tileAt(5, 2)!,
      );
      final legacyApproach = legacy.planTowardBlockedTarget(
        unit: movingUnit,
        targetTile: mapData.tileAt(4, 1)!,
      );
      final canonicalApproach = canonical.planTowardBlockedTarget(
        unit: movingUnit,
        targetTile: worldView.tileAt(4, 1)!,
      );
      final legacyCosts = legacy.movementCostsFrom(unit: movingUnit);
      final canonicalCosts = canonical.movementCostsFrom(unit: movingUnit);

      expect(_planSnapshot(canonicalPlan), _planSnapshot(legacyPlan));
      expect(_planSnapshot(canonicalApproach), _planSnapshot(legacyApproach));
      expect(_costSnapshot(canonicalCosts), _costSnapshot(legacyCosts));
      expect(
        canonical.isReachable(unit: movingUnit, col: 5, row: 2),
        legacy.isReachable(unit: movingUnit, col: 5, row: 2),
      );
      expect(
        canonical.isReachable(unit: movingUnit, col: 2, row: 1),
        legacy.isReachable(unit: movingUnit, col: 2, row: 1),
      );

      expect(_planSnapshot(canonicalPlan), isNotNull);
      expect(canonicalPlan?.targetCol, 5);
      expect(canonicalPlan?.targetRow, 2);
      expect(canonicalPlan?.totalCost, 9);
      expect(canonicalApproach?.targetCol, 3);
      expect(canonicalApproach?.targetRow, 1);
      expect(canonicalApproach?.totalCost, 6);
      expect(
        _costSnapshot(canonicalCosts),
        containsAll(<String>['5,2:9', '3,1:6', '4,2:7']),
      );
      expect(canonical.isReachable(unit: movingUnit, col: 5, row: 2), isTrue);
      expect(canonical.isReachable(unit: movingUnit, col: 2, row: 1), isFalse);
      expect(canonical.isReachable(unit: movingUnit, col: 5, row: 3), isFalse);
    });

    test('projects traversal hits and misses lazily once per coordinate', () {
      final mapData = MapData(
        cols: 100,
        rows: 100,
        tiles: const [
          TileData(
            col: 40,
            row: 50,
            terrains: [TerrainType.plains],
            resources: [ResourceType.wheat],
            height: 2,
          ),
        ],
      );
      final counted = _CountingTraversalView(
        LegacyWorldMapAdapter.asTraversalView(_reversedWorldMap(mapData)),
      );

      final pathfinder = UnitMovementPathfinder(
        mapData: counted,
        units: const [],
      );

      expect(counted.reads, isEmpty, reason: 'construction must stay lazy');

      final first = pathfinder.tileAt(40, 50);
      final second = pathfinder.tileAt(40, 50);
      expect(identical(first, second), isTrue);
      expect(counted.reads[(col: 40, row: 50)], 1);

      expect(pathfinder.tileAt(41, 50), isNull);
      expect(pathfinder.tileAt(41, 50), isNull);
      expect(counted.reads[(col: 41, row: 50)], 1);
      expect(counted.reads, hasLength(2));
    });
  });
}

MapData _sparseMixedMap() {
  return MapData(
    cols: 6,
    rows: 4,
    tiles: const [
      TileData(
        col: 0,
        row: 1,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 1,
        terrains: [TerrainType.plains, TerrainType.forest],
        resources: [],
        height: 1,
      ),
      TileData(
        col: 2,
        row: 1,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 3,
        row: 1,
        terrains: [TerrainType.desert],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 4,
        row: 1,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 5,
        row: 1,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 0,
        row: 2,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 2,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 2,
        row: 2,
        terrains: [TerrainType.plains, TerrainType.hills],
        resources: [],
        height: 2,
      ),
      TileData(
        col: 3,
        row: 2,
        terrains: [TerrainType.mountain],
        resources: [],
        height: 5,
      ),
      TileData(
        col: 4,
        row: 2,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 5,
        row: 2,
        terrains: [TerrainType.tundra],
        resources: [],
        height: 0,
      ),
    ],
  );
}

WorldMap _reversedWorldMap(MapData mapData) {
  return WorldMap(
    cols: mapData.cols,
    rows: mapData.rows,
    tiles: mapData.tiles.reversed.map(
      (tile) => WorldTile(
        coordinate: HexCoord(col: tile.col, row: tile.row),
        terrains: tile.terrains,
        resources: tile.resources,
        height: tile.height,
      ),
    ),
  );
}

GameUnit _unit({required String id, required int col, required int row}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.scout,
    name: id,
    col: col,
    row: row,
    movementPoints: 3,
  );
}

String? _planSnapshot(UnitMovementPlan? plan) {
  if (plan == null) return null;
  final steps = plan.steps
      .map(
        (step) =>
            '${step.col},${step.row}:${step.enterCost}/${step.cumulativeCost}',
      )
      .join('>');
  return '${plan.unitId}|${plan.targetCol},${plan.targetRow}'
      '|${plan.totalCost}/${plan.availableMovementPoints}'
      '|${plan.canMoveNow}/${plan.canSpendTurnEnteringFirstStep}|$steps';
}

List<String> _costSnapshot(Map<({int col, int row}), int> costs) {
  final snapshot = [
    for (final entry in costs.entries)
      '${entry.key.col},${entry.key.row}:${entry.value}',
  ];
  return snapshot..sort();
}

final class _CountingTraversalView implements MapTraversalView {
  _CountingTraversalView(this._delegate);

  final MapTraversalView _delegate;
  final Map<({int col, int row}), int> reads = {};

  @override
  int get cols => _delegate.cols;

  @override
  int get rows => _delegate.rows;

  @override
  TileData? tileAt(int col, int row) {
    final coordinate = (col: col, row: row);
    reads.update(coordinate, (count) => count + 1, ifAbsent: () => 1);
    return _delegate.tileAt(col, row);
  }
}
