import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/ai/military_assessment.dart';
import 'package:aonw_core/ai/strategic/war_goal.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

const _militaryAssessment = AiMilitaryAssessment();

final class MctsCommandReconciliationRules {
  const MctsCommandReconciliationRules();
  Set<String> reservedMoveTargetsForCommand(
    MoveUnitCommand command,
    GameView view,
  ) {
    final reserved = {hexKey(command.targetCol, command.targetRow)};
    final unit = unitById(view.ownUnits, command.unitId);
    if (unit == null) return reserved;
    if (isStrategicSupportUnit(unit)) {
      reserved.add(hexKey(unit.col, unit.row));
    }

    final targetTile = view.mapData.tileAt(
      command.targetCol,
      command.targetRow,
    );
    if (targetTile == null || unit.occupies(targetTile.col, targetTile.row)) {
      return reserved;
    }

    final knownUnits = view.movementBlockingUnits;
    final targetBlocker = knownUnits.unitAt(targetTile.col, targetTile.row);
    final pathfinder = UnitMovementPathfinder(
      mapData: view.mapData,
      units: knownUnits,
    );
    var plan = pathfinder.plan(unit: unit, targetTile: targetTile);
    if (plan == null && targetBlocker != null && targetBlocker.id != unit.id) {
      final approach = pathfinder.planTowardBlockedTarget(
        unit: unit,
        targetTile: targetTile,
      );
      final targetBlockedByOpponent =
          targetBlocker.ownerPlayerId != unit.ownerPlayerId;
      if (approach != null &&
          (targetBlockedByOpponent ||
              approach.totalCost > unit.movementPoints)) {
        plan = approach;
      }
    }
    if (plan == null) return reserved;
    if (!UnitMovementFeasibility.canEventuallyTraverse(
      unit: unit,
      plan: plan,
    )) {
      return reserved;
    }

    for (final hex in plan.reservedHexes) {
      reserved.add(hexKey(hex.col, hex.row));
    }
    reserved.addAll(
      reservedReachableApproachTargets(
        unit: unit,
        targetTile: targetTile,
        pathfinder: pathfinder,
      ),
    );
    return reserved;
  }

  Set<String> reservedReachableApproachTargets({
    required GameUnit unit,
    required TileData targetTile,
    required UnitMovementPathfinder pathfinder,
  }) {
    final origin = HexCoordinate(col: unit.col, row: unit.row);
    final target = HexCoordinate(col: targetTile.col, row: targetTile.row);
    final currentDistance = HexDistance.between(origin, target);
    return {
      for (final entry
          in pathfinder
              .movementCostsFrom(unit: unit, maxCost: unit.movementPoints)
              .entries)
        if (entry.value <= unit.movementPoints)
          if (HexDistance.between(
                HexCoordinate(col: entry.key.col, row: entry.key.row),
                target,
              ) <
              currentDistance)
            hexKey(entry.key.col, entry.key.row),
    };
  }

  Set<String> reservedCombatHexesForAttack(
    AttackHexCommand command,
    GameView view,
  ) {
    final reserved = {hexKey(command.defenderCol, command.defenderRow)};
    final attacker = unitById(view.ownUnits, command.attackerUnitId);
    final defender = view.visibleEnemyUnits.unitAt(
      command.defenderCol,
      command.defenderRow,
    );
    if (attacker == null ||
        defender == null ||
        defender.ownerPlayerId == attacker.ownerPlayerId) {
      return reserved;
    }

    final defenderStats = UnitCombatStats.derive(
      defender,
      ruleset: view.ruleset.combat,
    );
    if (defenderStats.attack <= 0) return reserved;

    final retreatDestination = CombatRetreatResolver.destination(
      attacker: attacker,
      defender: defender,
      units: view.movementBlockingUnits,
      tileAt: view.mapData.tileAt,
    );
    if (retreatDestination != null) {
      reserved.add(hexKey(retreatDestination.col, retreatDestination.row));
    }
    return reserved;
  }

  Set<String> reservedFollowUpAttackHexesForAttack(
    AttackHexCommand command,
    GameView view,
  ) {
    final target = HexCoordinate(
      col: command.defenderCol,
      row: command.defenderRow,
    );
    final reserved = {hexKey(target.col, target.row)};
    final defender = view.visibleEnemyUnits.unitAt(
      command.defenderCol,
      command.defenderRow,
    );
    if (defender == null) return reserved;

    final defenderStats = UnitCombatStats.derive(
      defender,
      ruleset: view.ruleset.combat,
    );
    if (defenderStats.attack <= 0) return reserved;

    for (final neighbor in HexNeighbors.existingAround(target, view.mapData)) {
      reserved.add(hexKey(neighbor.col, neighbor.row));
    }
    return reserved;
  }

  void reserveActualMoveDestination(
    MoveUnitCommand command, {
    required SimulatedState after,
    required Set<String> reservedMoveTargets,
  }) {
    final moved = unitById(after.ownUnits, command.unitId);
    if (moved == null) return;
    reservedMoveTargets.add(hexKey(moved.col, moved.row));
  }

  String? actingUnitId(GameCommand command) {
    return switch (command) {
      MoveUnitCommand(:final unitId) => unitId,
      AttackHexCommand(:final attackerUnitId) => attackerUnitId,
      CancelUnitActionCommand(:final unitId) => unitId,
      FortifyUnitCommand(:final unitId) => unitId,
      FoundCityCommand(:final founderId) => founderId,
      SelectWorkerImprovementCommand(:final unitId) => unitId,
      AssignWorkerToHexCommand(:final unitId) => unitId,
      StartArtifactExcavationCommand(:final unitId) => unitId,
      StoreArtifactInCityCommand(:final unitId) => unitId,
      _ => null,
    };
  }

  bool moveWouldBeNoOp(MoveUnitCommand command, SimulatedState state) {
    final unit = unitById(state.ownUnits, command.unitId);
    if (unit == null || unit.isWorking) return true;
    if (unit.occupies(command.targetCol, command.targetRow)) {
      return true;
    }
    if (state.view.mapData.tileAt(command.targetCol, command.targetRow) ==
        null) {
      return true;
    }
    if (isRememberedEnemyCityCenter(
      state.view,
      command.targetCol,
      command.targetRow,
    )) {
      return true;
    }
    for (final other in state.view.movementBlockingUnits) {
      if (other.id == unit.id) continue;
      if (other.occupies(command.targetCol, command.targetRow)) {
        return true;
      }
    }
    return false;
  }

  bool moveDidNotChangeUnit(
    MoveUnitCommand command, {
    required SimulatedState before,
    required SimulatedState after,
  }) {
    final previous = unitById(before.ownUnits, command.unitId);
    final next = unitById(after.ownUnits, command.unitId);
    if (previous == null || next == null) return true;
    return previous.col == next.col &&
        previous.row == next.row &&
        previous.queuedPath == next.queuedPath &&
        previous.movementPoints == next.movementPoints;
  }

  bool attackWouldBeNoOp(AttackHexCommand command, SimulatedState state) {
    final attacker = unitById(state.ownUnits, command.attackerUnitId);
    if (attacker == null || attacker.isWorking) return true;
    final ownTargetOccupant = state.ownUnits.unitAt(
      command.defenderCol,
      command.defenderRow,
    );
    if (ownTargetOccupant != null &&
        ownTargetOccupant.id != command.attackerUnitId) {
      return true;
    }
    if (state.visibleEnemyUnits.unitAt(
          command.defenderCol,
          command.defenderRow,
        ) !=
        null) {
      return false;
    }
    return state.rememberedEnemyCities.cityAt(
          command.defenderCol,
          command.defenderRow,
        ) ==
        null;
  }

  bool attackDidNotChangeCombatState(
    AttackHexCommand command, {
    required SimulatedState before,
    required SimulatedState after,
  }) {
    final previousAttacker = unitById(before.ownUnits, command.attackerUnitId);
    final nextAttacker = unitById(after.ownUnits, command.attackerUnitId);
    final previousDefender = before.visibleEnemyUnits.unitAt(
      command.defenderCol,
      command.defenderRow,
    );
    final previousCity = previousDefender == null
        ? before.rememberedEnemyCities.cityAt(
            command.defenderCol,
            command.defenderRow,
          )
        : null;
    final nextDefender = previousDefender == null
        ? null
        : unitById(after.visibleEnemyUnits, previousDefender.id);
    final nextCity = previousCity == null
        ? null
        : cityById(after.rememberedEnemyCities, previousCity.id);
    return previousAttacker == nextAttacker &&
        previousDefender == nextDefender &&
        previousCity == nextCity &&
        before.ownUnits.length == after.ownUnits.length &&
        before.visibleEnemyUnits.length == after.visibleEnemyUnits.length &&
        before.ownCities.length == after.ownCities.length &&
        before.rememberedEnemyCities.length ==
            after.rememberedEnemyCities.length;
  }

  GameUnit? unitById(Iterable<GameUnit> units, String unitId) {
    return units.byId(unitId);
  }

  GameCity? cityById(Iterable<GameCity> cities, String cityId) {
    return cities.byId(cityId);
  }

  bool isStrategicSupportUnit(GameUnit unit) =>
      unit.isWorker || isFounderUnit(unit) || isReconUnit(unit);

  bool isAssignedWarGoalMilitaryUnit(GameUnit unit, AiContext context) =>
      canServeAsMilitaryUnit(unit, context) &&
      warTargetsForUnit(unit.id, context).isNotEmpty;

  Set<String> warTargetsForUnit(String unitId, AiContext context) => {
    for (final goal in context.strategicPlan?.warGoals ?? const <WarGoal>[])
      if (goal.assignedUnitIds.contains(unitId)) goal.targetPlayerId,
  };

  bool isFounderUnit(GameUnit unit) =>
      unit.type == GameUnitType.settler || unit.hasSettlers;

  bool isReconUnit(GameUnit unit) {
    return switch (unit.type) {
      GameUnitType.scout ||
      GameUnitType.scoutShip ||
      GameUnitType.reconPlane => true,
      _ => false,
    };
  }

  bool canServeAsMilitaryUnit(GameUnit unit, AiContext context) =>
      _militaryAssessment.canServeAsMilitaryUnitInContext(unit, context);

  bool ownMilitaryNear(
    GameView view,
    int col,
    int row,
    int range,
    AiContext context,
  ) {
    final target = HexCoordinate(col: col, row: row);
    for (final unit in view.ownUnits) {
      if (!canServeAsMilitaryUnit(unit, context)) continue;
      final distance = HexDistance.between(
        target,
        HexCoordinate(col: unit.col, row: unit.row),
      );
      if (distance <= range) return true;
    }
    return false;
  }

  int nearestOwnCityDistance(GameView view, HexCoordinate target) {
    var best = 1 << 30;
    for (final city in view.ownCities) {
      final distance = HexDistance.between(target, city.center.toCoordinate());
      if (distance < best) best = distance;
    }
    return best;
  }

  int? nearestVisibleMilitaryDistance(
    GameView view,
    HexCoordinate target,
    AiContext context,
  ) {
    int? nearest;
    for (final unit in view.visibleTargetableEnemyUnits) {
      if (!canServeAsMilitaryUnit(unit, context)) continue;
      final distance = HexDistance.between(
        target,
        HexCoordinate(col: unit.col, row: unit.row),
      );
      if (nearest == null || distance < nearest) nearest = distance;
    }
    return nearest;
  }

  bool isFounderThreatReducedByMove({
    required int? currentEnemy,
    required int? targetEnemy,
  }) {
    if (currentEnemy == null || currentEnemy > 3) return false;
    final targetDistance = targetEnemy ?? 1 << 20;
    return targetDistance > currentEnemy && targetDistance > 2;
  }

  bool isRememberedEnemyCityHex(GameView view, int col, int row) {
    for (final city in view.rememberedEnemyCities) {
      if (city.occupiesCenter(col, row)) return true;
      for (final hex in city.controlledHexes) {
        if (hex.col == col && hex.row == row) return true;
      }
    }
    return false;
  }

  bool isRememberedEnemyCityCenter(GameView view, int col, int row) {
    for (final city in view.rememberedEnemyCities) {
      if (city.occupiesCenter(col, row)) return true;
    }
    return false;
  }

  String hexKey(int col, int row) => '$col,$row';
}
