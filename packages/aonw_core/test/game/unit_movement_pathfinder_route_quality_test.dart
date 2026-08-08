import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('UnitMovementPathfinder route quality', () {
    test('prefers fewer steps when movement cost and ETA are equal', () {
      final map = _map(
        cols: 3,
        rows: 3,
        passable: const {
          (col: 1, row: 0): [TerrainType.grassland],
          (col: 1, row: 1): [TerrainType.grassland, TerrainType.forest],
          (col: 1, row: 2): [TerrainType.grassland],
          (col: 0, row: 1): [TerrainType.grassland],
          (col: 0, row: 2): [TerrainType.grassland],
        },
      );
      final unit = GameUnit.startingWarrior(
        ownerPlayerId: 'p1',
        col: 1,
        row: 0,
      );

      final plan = UnitMovementPathfinder(
        mapData: map,
        units: [unit],
      ).plan(unit: unit, targetTile: map.tileAt(1, 2)!);

      expect(plan, isNotNull);
      expect(plan!.totalCost, 3);
      expect(plan.path, [(col: 1, row: 0), (col: 1, row: 1), (col: 1, row: 2)]);
    });

    test('prefers the route that arrives in fewer turns', () {
      final map = _map(
        cols: 3,
        rows: 3,
        passable: const {
          (col: 2, row: 1): [TerrainType.grassland],
          (col: 0, row: 2): [TerrainType.grassland],
          (col: 1, row: 0): [TerrainType.grassland],
          (col: 0, row: 1): [TerrainType.snow],
          (col: 2, row: 2): [TerrainType.snow],
          (col: 1, row: 2): [TerrainType.tundra],
        },
      );
      final unit = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'p1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 2,
        row: 1,
        movementPoints: 1,
      );

      final plan = UnitMovementPathfinder(
        mapData: map,
        units: [unit],
      ).plan(unit: unit, targetTile: map.tileAt(0, 2)!);

      expect(plan, isNotNull);
      expect(plan!.totalCost, 6);
      expect(plan.estimatedTurns(3), 2);
      expect(plan.path, [
        (col: 2, row: 1),
        (col: 2, row: 2),
        (col: 1, row: 2),
        (col: 0, row: 2),
      ]);
    });
  });
}

WorldMap _map({
  required int cols,
  required int rows,
  required Map<({int col, int row}), List<TerrainType>> passable,
}) {
  return WorldMap(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          WorldTile.at(
            coordinate: HexCoord(col: col, row: row),
            terrains:
                passable[(col: col, row: row)] ??
                const [TerrainType.grassland, TerrainType.mountain],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
