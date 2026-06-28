import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('unit primitives', () {
    test('maps troop type to detached unit metadata', () {
      expect(TroopType.archer.detachedUnitType, GameUnitType.archer);
      expect(
        TroopType.settler.detachedUnitNameToken,
        GameUnitType.settler.defaultNameToken,
      );
    });

    test('exposes city production definitions', () {
      expect(
        UnitProductionCatalog.standard[GameUnitType.worker]?.productionCost,
        14,
      );
      expect(
        UnitProductionCatalog.standard[GameUnitType.commander]?.productionCost,
        54,
      );
      expect(GameUnitType.commander.canBeProducedByCities, isTrue);
    });

    test('computes unit upkeep after free allowance', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
      );
      final units = [
        GameUnit.startingCommander(ownerPlayerId: 'player_1'),
        GameUnit(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          name: GameUnitType.settler.defaultNameToken,
          col: 0,
          row: 1,
        ),
        GameUnit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: GameUnitType.warrior.defaultNameToken,
          col: 1,
          row: 0,
        ),
        GameUnit(
          id: 'archer_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.archer,
          name: GameUnitType.archer.defaultNameToken,
          col: 1,
          row: 1,
        ),
        GameUnit(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          name: GameUnitType.worker.defaultNameToken,
          col: 2,
          row: 0,
        ),
        GameUnit(
          id: 'worker_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          name: GameUnitType.worker.defaultNameToken,
          col: 2,
          row: 1,
        ),
      ];

      final upkeep = UnitUpkeepRules.forPlayer(
        playerId: 'player_1',
        units: units,
        cities: const [city],
      );

      expect(UnitUpkeepRules.upkeepCostForType(GameUnitType.commander), 0);
      expect(UnitUpkeepRules.upkeepCostForType(GameUnitType.settler), 2);
      expect(upkeep.freeUnitCount, 4);
      expect(upkeep.unitCount, 5);
      expect(upkeep.paidUnitCount, 1);
      expect(upkeep.total, 1);
      expect(upkeep.paidUnitsByType, {GameUnitType.worker: 1});
      expect(upkeep.freeUnitSlots, 0);
      expect(upkeep.paidWorkerCount, 1);
      expect(upkeep.nextWorkerUpkeep, 2);
    });

    test('escalates upkeep for additional paid workers', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
      );
      final workers = [
        for (var i = 0; i < 7; i++)
          GameUnit(
            id: 'worker_$i',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            name: GameUnitType.worker.defaultNameToken,
            col: i,
            row: 0,
          ),
      ];

      final upkeep = UnitUpkeepRules.forPlayer(
        playerId: 'player_1',
        units: workers,
        cities: const [city],
      );

      expect(upkeep.freeUnitCount, 4);
      expect(upkeep.paidUnitCount, 3);
      expect(upkeep.total, 6);
      expect(upkeep.paidUnitsByType, {GameUnitType.worker: 3});
      expect(upkeep.upkeepByType, {GameUnitType.worker: 6});
      expect(upkeep.nextWorkerUpkeep, 4);
    });

    test('keeps next worker free while free unit slots remain', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
      );
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 0,
        row: 1,
      );

      final upkeep = UnitUpkeepRules.forPlayer(
        playerId: 'player_1',
        units: [worker],
        cities: const [city],
      );

      expect(upkeep.freeUnitSlots, 3);
      expect(upkeep.nextWorkerUpkeep, 0);
    });

    test('serializes worker job state', () {
      const job = WorkerJob(
        targetHex: CityHex(col: 2, row: 1),
        improvementType: FieldImprovementType.farm,
        remainingTurns: 1,
        totalTurns: 3,
      );

      expect(WorkerJob.fromJson(job.toJson()), job);
      expect(
        job.copyWith(remainingTurns: 0),
        const WorkerJob(
          targetHex: CityHex(col: 2, row: 1),
          improvementType: FieldImprovementType.farm,
          remainingTurns: 0,
          totalTurns: 3,
        ),
      );
    });

    test('serializes worker assignment state', () {
      const assignment = WorkerAssignment(targetHex: CityHex(col: 3, row: 4));

      expect(WorkerAssignment.fromJson(assignment.toJson()), assignment);
      expect(
        assignment.copyWith(targetHex: const CityHex(col: 4, row: 4)),
        const WorkerAssignment(targetHex: CityHex(col: 4, row: 4)),
      );
    });

    test('serializes game unit state with worker metadata', () {
      final unit =
          GameUnit(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            name: GameUnitType.worker.defaultNameToken,
            col: 1,
            row: 2,
          ).copyWithWorkerJob(
            const WorkerJob(
              targetHex: CityHex(col: 2, row: 2),
              improvementType: FieldImprovementType.mine,
              remainingTurns: 2,
              totalTurns: 4,
            ),
          );

      expect(GameUnit.fromJson(unit.toJson()), unit);
      expect(unit.hasActiveWorkerJob, isTrue);
      expect(unit.isWorking, isTrue);
    });

    test('reports whether unit is ready to act', () {
      final unit = GameUnit.startingWarrior(ownerPlayerId: 'player_1');
      final queued = unit.copyWithQueuedPath(
        QueuedMovePath(targetCol: 1, targetRow: 1, steps: const []),
      );
      final working =
          GameUnit(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            name: GameUnitType.worker.defaultNameToken,
            col: 1,
            row: 2,
          ).copyWithWorkerJob(
            const WorkerJob(
              targetHex: CityHex(col: 2, row: 2),
              improvementType: FieldImprovementType.mine,
              remainingTurns: 2,
              totalTurns: 4,
            ),
          );

      expect(unit.isReadyToAct, isTrue);
      expect(unit.copyWith(movementPoints: 0).isReadyToAct, isFalse);
      expect(queued.isReadyToAct, isFalse);
      expect(working.isReadyToAct, isFalse);
    });

    test('tracks configurable worker improvement charges', () {
      final worker = GameUnit.produced(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        col: 1,
        row: 2,
      );
      final veteranWorker = worker.copyWithWorkerBuildCharges(3);
      final warrior = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 2,
        row: 2,
      );

      expect(worker.workerBuildCharges, 1);
      expect(worker.toJson().containsKey('workerBuildCharges'), isFalse);
      expect(veteranWorker.workerBuildCharges, 3);
      expect(veteranWorker.toJson()['workerBuildCharges'], 3);
      expect(GameUnit.fromJson(veteranWorker.toJson()), veteranWorker);
      expect(warrior.workerBuildCharges, 0);
      expect(warrior.copyWithWorkerBuildCharges(3).workerBuildCharges, 0);
    });

    test('round-trips auto-explore posture through game unit JSON', () {
      final scout = GameUnit.produced(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        col: 1,
        row: 2,
      ).copyWith(posture: UnitPosture.autoExploring);

      final restored = GameUnit.fromJson(scout.toJson());

      expect(restored.posture, UnitPosture.autoExploring);
      expect(restored.isAutoExploring, isTrue);
    });

    test('maps experience points to veterancy ranks and stat bonuses', () {
      expect(
        UnitVeterancyRules.rankForExperience(0),
        UnitVeterancyRank.recruit,
      );
      expect(
        UnitVeterancyRules.rankForExperience(3),
        UnitVeterancyRank.seasoned,
      );
      expect(
        UnitVeterancyRules.rankForExperience(7),
        UnitVeterancyRank.veteran,
      );
      expect(UnitVeterancyRules.rankForExperience(12), UnitVeterancyRank.elite);
      expect(
        UnitVeterancyRules.statsBonusForRank(UnitVeterancyRank.elite),
        const CombatStats(attack: 2, defense: 1, hp: 2),
      );
    });

    test('awards combat experience only to surviving combat units', () {
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 1,
        row: 2,
      );
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 1,
        row: 2,
      );

      expect(
        UnitVeterancyRules.experienceAwardForCombat(
          unit: warrior,
          survived: true,
          defeatedEnemy: true,
        ),
        3,
      );
      expect(
        UnitVeterancyRules.experienceAwardForCombat(
          unit: warrior,
          survived: false,
          defeatedEnemy: true,
        ),
        0,
      );
      expect(
        UnitVeterancyRules.experienceAwardForCombat(
          unit: worker,
          survived: true,
          defeatedEnemy: true,
        ),
        0,
      );
    });

    test('clears nullable game unit fields through explicit helpers', () {
      final unit = GameUnit.startingCommander(ownerPlayerId: 'player_1')
          .copyWithHitPoints(6)
          .copyWithQueuedPath(
            QueuedMovePath(targetCol: 1, targetRow: 1, steps: const []),
          );

      final moved = unit.copyWith(col: 2);
      final cleared = unit.copyWithHitPoints(null).copyWithQueuedPath(null);

      expect(moved.queuedPath, same(unit.queuedPath));
      expect(moved.hitPoints, unit.hitPoints);
      expect(cleared.hitPoints, isNull);
      expect(cleared.queuedPath, isNull);
    });
  });

  group('movement primitives', () {
    test('computes movement balance by unit type', () {
      expect(
        UnitMovementBalance.maxMovementPointsForType(GameUnitType.commander),
        UnitMovementBalance.commanderMovementPointsPerTurn,
      );
      expect(
        UnitMovementBalance.maxMovementPointsForType(GameUnitType.warrior),
        UnitMovementBalance.footUnitMovementPointsPerTurn,
      );
    });

    test('computes terrain movement cost', () {
      const tile = TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains, TerrainType.forest],
        resources: [],
        height: 0,
      );

      expect(
        UnitMovementCostRules.costToEnterTile(tile),
        const MovementCost.passable(2),
      );
    });

    test('serializes queued movement paths', () {
      final path = QueuedMovePath(
        targetCol: 2,
        targetRow: 3,
        steps: const [
          UnitMovementStep(col: 1, row: 1, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 2, row: 3, enterCost: 1, cumulativeCost: 1),
        ],
      );

      expect(QueuedMovePath.fromJson(path.toJson()).toJson(), path.toJson());
    });
  });
}
