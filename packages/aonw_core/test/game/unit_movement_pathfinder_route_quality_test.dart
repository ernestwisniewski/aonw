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

    test('discards an over-capacity shortcut before ranking routes', () {
      final map = _map(
        cols: 3,
        rows: 3,
        passable: const {
          (col: 0, row: 0): [TerrainType.grassland],
          (col: 1, row: 0): [
            TerrainType.grassland,
            TerrainType.forest,
            TerrainType.jungle,
            TerrainType.hills,
          ],
          (col: 2, row: 0): [TerrainType.grassland],
          (col: 0, row: 1): [TerrainType.grassland],
          (col: 0, row: 2): [TerrainType.grassland],
          (col: 1, row: 2): [TerrainType.grassland],
          (col: 2, row: 2): [TerrainType.grassland],
          (col: 2, row: 1): [TerrainType.grassland],
        },
      );
      final unit = GameUnit.startingWarrior(ownerPlayerId: 'p1');
      final pathfinder = UnitMovementPathfinder(mapData: map, units: [unit]);

      final plan = pathfinder.plan(unit: unit, targetTile: map.tileAt(2, 0)!);
      final costs = pathfinder.movementCostsFrom(unit: unit);

      expect(plan, isNotNull);
      expect(plan!.totalCost, 6);
      expect(plan.estimatedTurns(3), 2);
      expect(plan.path, const [
        (col: 0, row: 0),
        (col: 0, row: 1),
        (col: 0, row: 2),
        (col: 1, row: 2),
        (col: 2, row: 2),
        (col: 2, row: 1),
        (col: 2, row: 0),
      ]);
      expect(plan.steps.skip(1).every((step) => step.enterCost <= 3), isTrue);
      expect(costs.containsKey((col: 1, row: 0)), isFalse);
      expect(costs[(col: 2, row: 0)], 6);
    });

    test('bounded search includes exactly one movement-exhausting step', () {
      final map = _map(
        cols: 4,
        rows: 1,
        passable: const {
          (col: 0, row: 0): [TerrainType.plains],
          (col: 1, row: 0): [TerrainType.plains, TerrainType.forest],
          (col: 2, row: 0): [TerrainType.plains, TerrainType.forest],
          (col: 3, row: 0): [TerrainType.plains],
        },
      );
      final unit = GameUnit.startingWarrior(ownerPlayerId: 'p1');
      final pathfinder = UnitMovementPathfinder(mapData: map, units: [unit]);

      final costs = pathfinder.movementCostsFrom(
        unit: unit,
        maxCost: unit.movementPoints,
      );
      final exhaustedCosts = pathfinder.movementCostsFrom(
        unit: unit.copyWith(movementPoints: 0),
        maxCost: 0,
      );
      final plan = pathfinder.plan(unit: unit, targetTile: map.tileAt(3, 0)!);

      expect(costs[(col: 1, row: 0)], 2);
      expect(costs[(col: 2, row: 0)], 4);
      expect(costs.containsKey((col: 3, row: 0)), isFalse);
      expect(exhaustedCosts, isEmpty);
      expect(plan?.furthestReachableStep?.coord, (col: 2, row: 0));
      expect(plan?.estimatedTurns(3), 2);
    });

    test(
      'route search scores the movement-exhausting boundary in this turn',
      () {
        final map = _map(
          cols: 5,
          rows: 4,
          passable: const {
            (col: 0, row: 2): [TerrainType.plains],
            (col: 0, row: 3): [TerrainType.plains],
            (col: 1, row: 0): [TerrainType.plains],
            (col: 1, row: 1): [TerrainType.plains],
            (col: 1, row: 3): [TerrainType.snow],
            (col: 2, row: 0): [TerrainType.snow],
            (col: 2, row: 3): [TerrainType.tundra],
            (col: 3, row: 0): [TerrainType.tundra],
            (col: 3, row: 1): [TerrainType.tundra],
            (col: 3, row: 2): [TerrainType.plains],
            (col: 4, row: 2): [TerrainType.tundra],
          },
        );
        final unit = GameUnit.startingWarrior(
          ownerPlayerId: 'p1',
          col: 1,
          row: 1,
        );

        final plan = UnitMovementPathfinder(
          mapData: map,
          units: [unit],
        ).plan(unit: unit, targetTile: map.tileAt(4, 2)!);

        expect(plan?.estimatedTurns(3), 3);
        expect(plan?.path, const [
          (col: 1, row: 1),
          (col: 1, row: 0),
          (col: 2, row: 0),
          (col: 3, row: 0),
          (col: 3, row: 1),
          (col: 4, row: 2),
        ]);
      },
    );
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
