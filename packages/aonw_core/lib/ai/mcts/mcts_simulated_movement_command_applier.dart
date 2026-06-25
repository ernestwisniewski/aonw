import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class MctsSimulatedMovementCommandApplier {
  const MctsSimulatedMovementCommandApplier({
    required this.view,
    required this.ownUnits,
    required this.ownCities,
    required this.rememberedEnemyCities,
  });

  final GameView view;
  final List<GameUnit> ownUnits;
  final List<GameCity> ownCities;
  final List<GameCity> rememberedEnemyCities;

  List<GameUnit> applyMoveUnit(MoveUnitCommand command) {
    final unitIndex = _unitIndexById(ownUnits, command.unitId);
    if (unitIndex == null) return ownUnits;

    final unit = ownUnits[unitIndex];
    if (unit.isWorking) return ownUnits;
    if (view.mapData.tileAt(unit.col, unit.row) == null) return ownUnits;

    final targetTile = view.mapData.tileAt(
      command.targetCol,
      command.targetRow,
    );
    if (targetTile == null || unit.occupies(targetTile.col, targetTile.row)) {
      return ownUnits;
    }
    final targetCity = _cityAt(targetTile.col, targetTile.row);
    if (targetCity != null && targetCity.ownerPlayerId != unit.ownerPlayerId) {
      return ownUnits;
    }

    final knownUnits = view.movementBlockingUnits;
    final targetBlocker = _unitAt(knownUnits, targetTile.col, targetTile.row);
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
    if (plan == null) return ownUnits;
    if (!UnitMovementFeasibility.canEventuallyTraverse(
      unit: unit,
      plan: plan,
    )) {
      return ownUnits;
    }

    final reachable = plan.canMoveNow;
    final destinationStep = reachable
        ? plan.steps.last
        : plan.furthestReachableStep;

    if (destinationStep == null ||
        (destinationStep.col == unit.col && destinationStep.row == unit.row)) {
      return _replaceUnit(
        unit
            .copyWith(posture: UnitPosture.active)
            .copyWithQueuedPath(_queuedPathFor(plan)),
      );
    }

    final moved = unit.copyWith(
      col: destinationStep.col,
      row: destinationStep.row,
      movementPoints: plan.remainingMovementPointsAfterStep(destinationStep),
      posture: UnitPosture.active,
    );
    return _replaceUnit(
      reachable
          ? moved.copyWithQueuedPath(null)
          : moved.copyWithQueuedPath(_queuedPathFor(plan)),
    );
  }

  List<GameUnit> applyCancelUnitAction(CancelUnitActionCommand command) {
    final unitIndex = _unitIndexById(ownUnits, command.unitId);
    if (unitIndex == null) return ownUnits;

    final unit = ownUnits[unitIndex];
    final nextMovementPoints = unit.isFortified
        ? UnitMovementBalance.maxMovementPointsFor(
            type: unit.type,
            carriedArtifactId: unit.carriedArtifactId,
          )
        : unit.movementPoints;
    final updated = unit
        .copyWith(movementPoints: nextMovementPoints)
        .copyWithQueuedPath(null)
        .copyWithWorkerJob(null)
        .copyWithWorkerAssignment(null)
        .copyWithPosture(UnitPosture.active);
    return _replaceUnit(updated);
  }

  List<GameUnit> _replaceUnit(GameUnit updated) {
    return [
      for (final unit in ownUnits)
        if (unit.id == updated.id) updated else unit,
    ];
  }

  GameCity? _cityAt(int col, int row) {
    for (final city in ownCities) {
      if (city.occupiesCenter(col, row)) return city;
    }
    for (final city in rememberedEnemyCities) {
      if (city.occupiesCenter(col, row)) return city;
    }
    return null;
  }

  static int? _unitIndexById(List<GameUnit> units, String unitId) {
    for (var i = 0; i < units.length; i++) {
      if (units[i].id == unitId) return i;
    }
    return null;
  }

  static GameUnit? _unitAt(List<GameUnit> units, int col, int row) {
    for (final unit in units) {
      if (unit.occupies(col, row)) return unit;
    }
    return null;
  }

  static QueuedMovePath _queuedPathFor(UnitMovementPlan plan) {
    return QueuedMovePath(
      targetCol: plan.targetCol,
      targetRow: plan.targetRow,
      steps: plan.steps,
    );
  }
}
