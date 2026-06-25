import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map(
  int cols,
  int rows, {
  List<TerrainType> terrains = const [TerrainType.grassland],
}) => MapData(
  cols: cols,
  rows: rows,
  tiles: [
    for (int row = 0; row < rows; row++)
      for (int col = 0; col < cols; col++)
        TileData(
          col: col,
          row: row,
          terrains: terrains,
          resources: const [],
          height: 0,
        ),
  ],
);

TileData _tile(MapData map, int col, int row) =>
    map.tiles.firstWhere((tile) => tile.col == col && tile.row == row);

void main() {
  group('UnitMovementPlanner', () {
    test('plans adjacent movement as one movement point', () {
      final map = _map(3, 3);
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final planner = UnitMovementPlanner(mapData: map, units: [commander]);

      final plan = planner.planMove(
        unit: commander,
        targetTile: _tile(map, 1, 0),
      );

      expect(plan, isNotNull);
      expect(plan!.targetCol, 1);
      expect(plan.targetRow, 0);
      expect(plan.totalCost, 1);
      expect(plan.availableMovementPoints, 5);
      expect(plan.canMoveNow, isTrue);
      expect(plan.path, [(col: 0, row: 0), (col: 1, row: 0)]);
    });

    test('plans movement for workers and settlers', () {
      final map = _map(3, 3);
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: 'Worker',
        col: 0,
        row: 0,
      );
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        name: 'Settler',
        col: 0,
        row: 0,
      );

      final workerPlan = UnitMovementPlanner(
        mapData: map,
        units: [worker],
      ).planMove(unit: worker, targetTile: _tile(map, 1, 0));
      final settlerPlan = UnitMovementPlanner(
        mapData: map,
        units: [settler],
      ).planMove(unit: settler, targetTile: _tile(map, 1, 0));

      expect(workerPlan, isNotNull);
      expect(workerPlan!.availableMovementPoints, 3);
      expect(workerPlan.totalCost, 1);
      expect(settlerPlan, isNotNull);
      expect(settlerPlan!.availableMovementPoints, 3);
      expect(settlerPlan.totalCost, 1);
    });

    test('plans multi-hex movement with shortest path', () {
      final map = _map(4, 4);
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final planner = UnitMovementPlanner(mapData: map, units: [commander]);

      final plan = planner.planMove(
        unit: commander,
        targetTile: _tile(map, 2, 0),
      );

      expect(plan, isNotNull);
      expect(plan!.targetCol, 2);
      expect(plan.targetRow, 0);
      expect(plan.totalCost, 2);
      expect(plan.path.first, (col: 0, row: 0));
      expect(plan.path.last, (col: 2, row: 0));
    });

    test('adds feature movement cost when a hex has multiple terrains', () {
      final map = _map(3, 1);
      map.tiles[1] = map.tiles[1].copyWith(
        terrains: const [TerrainType.grassland, TerrainType.forest],
      );
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final planner = UnitMovementPlanner(mapData: map, units: [commander]);

      final plan = planner.planMove(
        unit: commander,
        targetTile: _tile(map, 2, 0),
      );

      expect(plan, isNotNull);
      expect(plan!.totalCost, 3);
      expect(plan.steps[1].enterCost, 2);
      expect(plan.steps[2].enterCost, 1);
    });

    test(
      'allows an artifact carrier to spend the turn entering rough terrain',
      () {
        final map = _map(3, 1);
        map.tiles[1] = map.tiles[1].copyWith(
          terrains: const [
            TerrainType.grassland,
            TerrainType.forest,
            TerrainType.hills,
          ],
        );
        final carrier = GameUnit(
          id: 'carrier_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.scout,
          name: 'Scout',
          col: 0,
          row: 0,
          carriedArtifactId: 'artifact_1',
        );
        final planner = UnitMovementPlanner(mapData: map, units: [carrier]);

        final adjacentPlan = planner.planMove(
          unit: carrier,
          targetTile: _tile(map, 1, 0),
        );
        final distantPlan = planner.planMove(
          unit: carrier,
          targetTile: _tile(map, 2, 0),
        );
        final movementCosts = UnitMovementPathfinder(
          mapData: map,
          units: [carrier],
        ).movementCostsFrom(unit: carrier, maxCost: carrier.movementPoints);

        expect(carrier.movementPoints, 2);
        expect(adjacentPlan, isNotNull);
        expect(adjacentPlan!.totalCost, 3);
        expect(adjacentPlan.canMoveNow, isTrue);
        expect(
          adjacentPlan.remainingMovementPointsAfterStep(
            adjacentPlan.steps.last,
          ),
          0,
        );
        expect(distantPlan, isNotNull);
        expect(distantPlan!.canMoveNow, isFalse);
        expect(distantPlan.furthestReachableStep?.coord, (col: 1, row: 0));
        expect(movementCosts[(col: 1, row: 0)], 3);
        expect(movementCosts.containsKey((col: 2, row: 0)), isFalse);
      },
    );

    test('lets low-movement units spend a turn entering snowy forest', () {
      final map = _map(2, 1);
      map.tiles[1] = map.tiles[1].copyWith(
        terrains: const [
          TerrainType.snow,
          TerrainType.forest,
          TerrainType.river,
          TerrainType.tundra,
        ],
      );
      final scout = GameUnit.produced(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        col: 0,
        row: 0,
      ).copyWith(movementPoints: 2);
      final planner = UnitMovementPlanner(mapData: map, units: [scout]);

      final plan = planner.planMove(unit: scout, targetTile: _tile(map, 1, 0));
      final movementCosts = UnitMovementPathfinder(
        mapData: map,
        units: [scout],
      ).movementCostsFrom(unit: scout, maxCost: scout.movementPoints);

      expect(plan, isNotNull);
      expect(plan!.totalCost, 3);
      expect(plan.canMoveNow, isTrue);
      expect(plan.furthestReachableStep?.coord, (col: 1, row: 0));
      expect(plan.remainingMovementPointsAfterStep(plan.steps.last), 0);
      expect(movementCosts[(col: 1, row: 0)], 3);
    });

    test('plans naval movement through coast and ocean but not land', () {
      final map = _map(4, 1, terrains: const [TerrainType.ocean]);
      map.tiles[0] = map.tiles[0].copyWith(terrains: const [TerrainType.coast]);
      map.tiles[2] = map.tiles[2].copyWith(terrains: const [TerrainType.coast]);
      map.tiles[3] = map.tiles[3].copyWith(
        terrains: const [TerrainType.grassland],
      );
      final ship = GameUnit.produced(
        id: 'ship_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scoutShip,
        col: 0,
        row: 0,
      );
      final planner = UnitMovementPlanner(mapData: map, units: [ship]);

      final oceanPlan = planner.planMove(
        unit: ship,
        targetTile: _tile(map, 1, 0),
      );
      final coastPlan = planner.planMove(
        unit: ship,
        targetTile: _tile(map, 2, 0),
      );
      final landPlan = planner.planMove(
        unit: ship,
        targetTile: _tile(map, 3, 0),
      );

      expect(oceanPlan, isNotNull);
      expect(oceanPlan!.totalCost, 1);
      expect(coastPlan, isNotNull);
      expect(coastPlan!.totalCost, 2);
      expect(landPlan, isNull);
    });

    test('rejects target occupied by another unit', () {
      final map = _map(4, 4);
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final blocker = GameUnit.startingCommander(
        ownerPlayerId: 'player_2',
        col: 2,
        row: 0,
      );
      final planner = UnitMovementPlanner(
        mapData: map,
        units: [commander, blocker],
      );

      final plan = planner.planMove(
        unit: commander,
        targetTile: _tile(map, 2, 0),
      );

      expect(plan, isNull);
    });

    test('does not return a plan for the current tile', () {
      final map = _map(3, 3);
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final planner = UnitMovementPlanner(mapData: map, units: [commander]);

      final plan = planner.planMove(
        unit: commander,
        targetTile: _tile(map, 0, 0),
      );

      expect(plan, isNull);
    });
  });

  group('UnitMovementPathfinder', () {
    test('checks reachability with the same blockers as movement plans', () {
      final map = _map(3, 3);
      map.tiles[4] = map.tiles[4].copyWith(
        terrains: const [TerrainType.mountain],
      );
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final blocker = GameUnit(
        id: 'blocker_1',
        ownerPlayerId: 'player_2',
        type: GameUnitType.commander,
        name: 'Blocker',
        col: 2,
        row: 0,
      );
      final pathfinder = UnitMovementPathfinder(
        mapData: map,
        units: [commander, blocker],
      );

      expect(pathfinder.isReachable(unit: commander, col: 1, row: 0), isTrue);
      expect(pathfinder.isReachable(unit: commander, col: 0, row: 0), isFalse);
      expect(pathfinder.isReachable(unit: commander, col: 1, row: 1), isFalse);
      expect(pathfinder.isReachable(unit: commander, col: 2, row: 0), isFalse);
    });

    test('memoizes reachability for repeated probes of the same unit', () {
      final map = _map(4, 4);
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      var enterChecks = 0;
      final pathfinder = UnitMovementPathfinder(
        mapData: map,
        units: [commander],
        canEnterTile: (_) {
          enterChecks++;
          return true;
        },
      );

      expect(pathfinder.isReachable(unit: commander, col: 3, row: 3), isTrue);
      final checksAfterFirstProbe = enterChecks;
      expect(checksAfterFirstProbe, greaterThan(0));

      expect(pathfinder.isReachable(unit: commander, col: 1, row: 0), isTrue);
      expect(enterChecks, checksAfterFirstProbe);
    });
  });
}
