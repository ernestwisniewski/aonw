import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

// Minimal plains map.
MapData _simpleMap({int cols = 3, int rows = 3}) => MapData(
  cols: cols,
  rows: rows,
  tiles: [
    for (var row = 0; row < rows; row++)
      for (var col = 0; col < cols; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

void main() {
  group('UnitMovementTurnRules', () {
    test('resets commander movement points to the per-turn maximum', () {
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
      ).copyWith(movementPoints: 1);

      final reset = UnitMovementTurnRules.resetForNewTurn(commander);

      expect(
        reset.movementPoints,
        UnitMovementBalance.commanderMovementPointsPerTurn,
      );
      expect(reset.col, commander.col);
      expect(reset.row, commander.row);
    });

    test('resetForNewTurn preserves combat hit points', () {
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
      ).copyWith(movementPoints: 0).copyWithHitPoints(3);

      final reset = UnitMovementTurnRules.resetForNewTurn(commander);

      expect(reset.hitPoints, 3);
      expect(
        reset.movementPoints,
        UnitMovementBalance.commanderMovementPointsPerTurn,
      );
    });

    test('resetForNewTurn preserves queuedPath', () {
      final path = QueuedMovePath(
        targetCol: 2,
        targetRow: 0,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
        ],
      );
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'p1',
      ).copyWith(movementPoints: 1).copyWithQueuedPath(path);

      final reset = UnitMovementTurnRules.resetForNewTurn(commander);

      expect(reset.queuedPath, isNotNull);
      expect(reset.queuedPath!.targetCol, 2);
    });

    test('assigned worker stays on work duty with zero movement', () {
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'p1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 1,
        row: 1,
        movementPoints: 1,
        workerAssignment: const WorkerAssignment(
          targetHex: CityHex(col: 1, row: 1),
        ),
      );

      final reset = UnitMovementTurnRules.resetForNewTurn(worker);

      expect(reset.movementPoints, 0);
      expect(reset.workerAssignment, worker.workerAssignment);
    });

    test('fortified unit heals and stays idle while no enemy is visible', () {
      final warrior = GameUnit.startingWarrior(ownerPlayerId: 'p1')
          .copyWith(movementPoints: 0, posture: UnitPosture.fortified)
          .copyWithHitPoints(7);
      final distantEnemy = GameUnit.startingWarrior(
        ownerPlayerId: 'p2',
        col: 4,
        row: 4,
      );

      final reset = UnitMovementTurnRules.resetForNewTurn(
        warrior,
        mapData: _simpleMap(cols: 5, rows: 5),
        allUnits: [warrior, distantEnemy],
      );

      expect(reset.posture, UnitPosture.fortified);
      expect(reset.movementPoints, 0);
      expect(reset.hitPoints, 8);
    });

    test('full-health fortified unit stays idle while no enemy is visible', () {
      final warrior = GameUnit.startingWarrior(
        ownerPlayerId: 'p1',
      ).copyWith(movementPoints: 0, posture: UnitPosture.fortified);
      final distantEnemy = GameUnit.startingWarrior(
        ownerPlayerId: 'p2',
        col: 4,
        row: 4,
      );

      final reset = UnitMovementTurnRules.resetForNewTurn(
        warrior,
        mapData: _simpleMap(cols: 5, rows: 5),
        allUnits: [warrior, distantEnemy],
      );

      expect(reset.posture, UnitPosture.fortified);
      expect(reset.movementPoints, 0);
      expect(reset.hitPoints, isNull);
    });

    test(
      'full-health fortified unit wakes when an enemy enters sight range',
      () {
        final warrior = GameUnit.startingWarrior(
          ownerPlayerId: 'p1',
        ).copyWith(movementPoints: 0, posture: UnitPosture.fortified);
        final visibleEnemy = GameUnit.startingWarrior(
          ownerPlayerId: 'p2',
          col: 2,
          row: 0,
        );

        final reset = UnitMovementTurnRules.resetForNewTurn(
          warrior,
          mapData: _simpleMap(cols: 5, rows: 5),
          allUnits: [warrior, visibleEnemy],
        );

        expect(reset.posture, UnitPosture.active);
        expect(
          reset.movementPoints,
          UnitMovementBalance.maxMovementPointsForType(GameUnitType.warrior),
        );
        expect(reset.hitPoints, isNull);
      },
    );

    test(
      'healing unit spends movement even when an enemy enters sight range',
      () {
        final warrior = GameUnit.startingWarrior(ownerPlayerId: 'p1')
            .copyWith(movementPoints: 0, posture: UnitPosture.fortified)
            .copyWithHitPoints(7);
        final visibleEnemy = GameUnit.startingWarrior(
          ownerPlayerId: 'p2',
          col: 2,
          row: 0,
        );

        final reset = UnitMovementTurnRules.resetForNewTurn(
          warrior,
          mapData: _simpleMap(cols: 5, rows: 5),
          allUnits: [warrior, visibleEnemy],
        );

        expect(reset.posture, UnitPosture.fortified);
        expect(reset.movementPoints, 0);
        expect(reset.hitPoints, 8);
      },
    );

    test('healing unit stays fortified without movement when fully healed', () {
      final warrior = GameUnit.startingWarrior(ownerPlayerId: 'p1')
          .copyWith(movementPoints: 0, posture: UnitPosture.fortified)
          .copyWithHitPoints(9);

      final reset = UnitMovementTurnRules.resetForNewTurn(
        warrior,
        mapData: _simpleMap(cols: 5, rows: 5),
        allUnits: [warrior],
      );

      expect(reset.posture, UnitPosture.fortified);
      expect(reset.movementPoints, 0);
      expect(reset.hitPoints, isNull);
    });

    group('validateQueuedPath', () {
      test('returns unit unchanged when path is valid', () {
        final map = _simpleMap();
        final path = QueuedMovePath(
          targetCol: 2,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
            UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
          ],
        );
        final commander = GameUnit.startingCommander(
          ownerPlayerId: 'p1',
        ).copyWithQueuedPath(path);

        final result = UnitMovementTurnRules.validateQueuedPath(
          unit: commander,
          mapData: map,
          allUnits: [commander],
        );

        expect(result.queuedPath, isNotNull);
      });

      test('clears path when target tile is occupied by another unit', () {
        final map = _simpleMap();
        final path = QueuedMovePath(
          targetCol: 2,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
            UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
          ],
        );
        final commander = GameUnit.startingCommander(
          ownerPlayerId: 'p1',
        ).copyWithQueuedPath(path);
        final blocker = GameUnit.startingCommander(
          ownerPlayerId: 'p2',
        ).copyWith(col: 2, row: 0);

        final result = UnitMovementTurnRules.validateQueuedPath(
          unit: commander,
          mapData: map,
          allUnits: [commander, blocker],
        );

        expect(result.queuedPath, isNull);
      });

      test('returns unit unchanged when queuedPath is null', () {
        final map = _simpleMap();
        final commander = GameUnit.startingCommander(ownerPlayerId: 'p1');

        final result = UnitMovementTurnRules.validateQueuedPath(
          unit: commander,
          mapData: map,
          allUnits: [commander],
        );

        expect(result.queuedPath, isNull);
      });
    });
  });
}
