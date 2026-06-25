import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameUnit', () {
    test('starting general receives full movement points', () {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');

      expect(
        commander.movementPoints,
        UnitMovementBalance.commanderMovementPointsPerTurn,
      );
    });

    test('produced unit uses type display name and full movement points', () {
      final unit = GameUnit.produced(
        id: 'city_1_warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 2,
        row: 3,
      );

      expect(unit.name, GameUnitType.warrior.defaultNameToken);
      expect(
        unit.movementPoints,
        UnitMovementBalance.maxMovementPointsForType(GameUnitType.warrior),
      );
    });

    test('serializes movement points', () {
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
      ).copyWith(movementPoints: 2);

      expect(commander.toJson()['movementPoints'], 2);
    });

    test('serializes and deserializes combat hit points', () {
      final warrior = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 2,
        row: 3,
      ).copyWithHitPoints(6);

      final back = GameUnit.fromJson(warrior.toJson());

      expect(warrior.toJson()['hitPoints'], 6);
      expect(back.hitPoints, 6);
    });

    test('serializes and deserializes experience points', () {
      final warrior = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 2,
        row: 3,
      ).copyWith(experiencePoints: 7);

      final back = GameUnit.fromJson(warrior.toJson());

      expect(warrior.toJson()['experiencePoints'], 7);
      expect(back.experiencePoints, 7);
      expect(UnitVeterancyRules.rankFor(back), UnitVeterancyRank.veteran);
    });

    test('round-trips detached unit types through JSON', () {
      final archer = GameUnit(
        id: 'archer_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.archer,
        name: 'Archer',
        col: 1,
        row: 0,
      );

      final back = GameUnit.fromJson(archer.toJson());

      expect(back.type, GameUnitType.archer);
      expect(back.name, 'Archer');
    });

    test('serializes and deserializes queuedPath', () {
      final path = QueuedMovePath(
        targetCol: 4,
        targetRow: 2,
        steps: [
          const UnitMovementStep(
            col: 1,
            row: 0,
            enterCost: 0,
            cumulativeCost: 0,
          ),
          const UnitMovementStep(
            col: 2,
            row: 0,
            enterCost: 1,
            cumulativeCost: 1,
          ),
          const UnitMovementStep(
            col: 3,
            row: 0,
            enterCost: 1,
            cumulativeCost: 2,
          ),
          const UnitMovementStep(
            col: 4,
            row: 0,
            enterCost: 1,
            cumulativeCost: 3,
          ),
        ],
      );
      final commander = GameUnit.startingCommander(ownerPlayerId: 'p1');
      final withPath = commander.copyWithQueuedPath(path);
      final json = withPath.toJson();
      final back = GameUnit.fromJson(json);

      expect(back.queuedPath?.targetCol, 4);
      expect(back.queuedPath?.steps.length, 4);
      expect(back.queuedPath?.steps.last.cumulativeCost, 3);
    });

    test('copyWithQueuedPath(null) clears the path', () {
      final path = QueuedMovePath(targetCol: 2, targetRow: 0, steps: []);
      final commander = GameUnit.startingCommander(ownerPlayerId: 'p1');
      final withPath = commander.copyWithQueuedPath(path);
      final cleared = withPath.copyWithQueuedPath(null);

      expect(cleared.queuedPath, isNull);
    });

    test('round-trips without queuedPath when no path is queued', () {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final back = GameUnit.fromJson(commander.toJson());

      expect(back.queuedPath, isNull);
      expect(back.movementPoints, commander.movementPoints);
    });

    test('serializes and deserializes workerJob', () {
      final worker =
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 2,
            row: 1,
          ).copyWithWorkerJob(
            const WorkerJob(
              targetHex: CityHex(col: 2, row: 1),
              improvementType: FieldImprovementType.farm,
              remainingTurns: 2,
              totalTurns: 2,
            ),
          );

      final back = GameUnit.fromJson(worker.toJson());

      expect(back.workerJob, worker.workerJob);
      expect(back.type, GameUnitType.worker);
    });

    test('serializes and deserializes cityFoundingJob', () {
      final settler =
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 2,
            row: 1,
          ).copyWithCityFoundingJob(
            CityFoundingJob(
              center: const CityHex(col: 2, row: 1),
              controlledHexes: const [
                CityHex(col: 2, row: 0),
                CityHex(col: 3, row: 1),
              ],
              remainingTurns: 1,
              totalTurns: 1,
            ),
          );

      final back = GameUnit.fromJson(settler.toJson());

      expect(back.cityFoundingJob, settler.cityFoundingJob);
      expect(back.isWorking, isTrue);
    });

    test('serializes and deserializes workerAssignment', () {
      final worker =
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 2,
            row: 1,
          ).copyWithWorkerAssignment(
            const WorkerAssignment(targetHex: CityHex(col: 2, row: 1)),
          );

      final back = GameUnit.fromJson(worker.toJson());

      expect(back.workerAssignment, worker.workerAssignment);
      expect(back.isWorking, isTrue);
    });
  });

  group('QueuedMovePath', () {
    test('round-trips through JSON with steps', () {
      final original = QueuedMovePath(
        targetCol: 3,
        targetRow: 5,
        steps: const [
          UnitMovementStep(col: 1, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 1),
          UnitMovementStep(col: 3, row: 0, enterCost: 2, cumulativeCost: 3),
        ],
      );

      final back = QueuedMovePath.fromJson(original.toJson());

      expect(back.targetCol, 3);
      expect(back.targetRow, 5);
      expect(back.steps.length, 3);
      expect(
        back.steps[0],
        const UnitMovementStep(col: 1, row: 0, enterCost: 0, cumulativeCost: 0),
      );
      expect(
        back.steps[1],
        const UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 1),
      );
      expect(
        back.steps[2],
        const UnitMovementStep(col: 3, row: 0, enterCost: 2, cumulativeCost: 3),
      );
    });

    test('empty steps list survives round-trip', () {
      final original = QueuedMovePath(
        targetCol: 0,
        targetRow: 0,
        steps: const [],
      );
      final back = QueuedMovePath.fromJson(original.toJson());
      expect(back.steps, isEmpty);
    });

    test('fromJson requires target coordinates', () {
      expect(
        () => QueuedMovePath.fromJson({'steps': <dynamic>[]}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
