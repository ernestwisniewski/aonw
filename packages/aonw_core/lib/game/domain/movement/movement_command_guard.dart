import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/movement/movement_command_state.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

typedef MovementCommandGuardResult = ({
  int? unitIndex,
  GameUnit? unit,
  MapTileView? targetTile,
  String? reason,
});

typedef _MovementUnitGuardResult = ({
  int? unitIndex,
  GameUnit? unit,
  String? reason,
});

/// Validation that must precede pathfinding for a manual move.
abstract final class MovementCommandGuard {
  static MovementCommandGuardResult validate({
    required MovementCommandState state,
    required MoveUnitCommand command,
    required String actorPlayerId,
    required MapTraversalView mapData,
    required bool canAct,
  }) {
    final guardedUnit = _validateUnit(
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      mapData: mapData,
      canAct: canAct,
    );
    if (guardedUnit.reason case final reason?) return _rejected(reason);
    return _validateTarget(
      command: command,
      unitIndex: guardedUnit.unitIndex!,
      unit: guardedUnit.unit!,
      mapData: mapData,
    );
  }

  static _MovementUnitGuardResult _validateUnit({
    required MovementCommandState state,
    required MoveUnitCommand command,
    required String actorPlayerId,
    required MapTraversalView mapData,
    required bool canAct,
  }) {
    final unitIndex = _unitIndexById(state.units, command.unitId);
    if (unitIndex == null) return _rejectedUnit('unit_not_found');
    final unit = state.units[unitIndex];
    if (!canAct || unit.ownerPlayerId != actorPlayerId) {
      return _rejectedUnit('unit_not_controlled');
    }
    if (unit.isWorking || unit.isFortified) {
      return _rejectedUnit('unit_unavailable');
    }
    if (unit.type == GameUnitType.merchant) {
      return _rejectedUnit('unit_uses_trade_routes');
    }
    if (mapData.tileAt(unit.col, unit.row) == null) {
      return _rejectedUnit('unit_out_of_bounds');
    }
    return (unitIndex: unitIndex, unit: unit, reason: null);
  }

  static MovementCommandGuardResult _validateTarget({
    required MoveUnitCommand command,
    required int unitIndex,
    required GameUnit unit,
    required MapTraversalView mapData,
  }) {
    final targetTile = mapData.tileAt(command.targetCol, command.targetRow);
    if (targetTile == null) return _rejected('move_target_out_of_bounds');
    if (unit.occupies(targetTile.col, targetTile.row)) {
      return _rejected('move_target_is_current_tile');
    }
    return (
      unitIndex: unitIndex,
      unit: unit,
      targetTile: targetTile,
      reason: null,
    );
  }

  static bool canCarryArtifactIntoTargetCity({
    required MovementCommandState state,
    required GameUnit unit,
    required MapTileView targetTile,
    required UnitMovementStep step,
  }) {
    if (unit.carriedArtifactId == null) return false;
    if (step.col != targetTile.col || step.row != targetTile.row) return false;
    for (final city in state.cities) {
      if (!city.occupiesCenter(step.col, step.row)) continue;
      return city.ownerPlayerId == unit.ownerPlayerId;
    }
    return false;
  }

  static MovementCommandGuardResult _rejected(String reason) =>
      (unitIndex: null, unit: null, targetTile: null, reason: reason);

  static _MovementUnitGuardResult _rejectedUnit(String reason) =>
      (unitIndex: null, unit: null, reason: reason);

  static int? _unitIndexById(List<GameUnit> units, String unitId) {
    for (var index = 0; index < units.length; index++) {
      if (units[index].id == unitId) return index;
    }
    return null;
  }
}
