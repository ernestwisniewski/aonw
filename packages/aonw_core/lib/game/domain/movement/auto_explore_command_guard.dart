import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_state.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

typedef AutoExploreCommandGuardResult = ({
  int? unitIndex,
  GameUnit? unit,
  String? reason,
});

/// Ordered validation shared by direct and continued auto-exploration.
abstract final class AutoExploreCommandGuard {
  static AutoExploreCommandGuardResult validate({
    required AutoExploreCommandState state,
    required AutoExploreUnitCommand command,
    required String actorPlayerId,
    required MapTraversalView mapData,
    required bool canAct,
  }) {
    final unitIndex = _unitIndexById(state.movement.units, command.unitId);
    if (unitIndex == null) return _rejected('unit_not_found');
    final unit = state.movement.units[unitIndex];
    if (!canAct || unit.ownerPlayerId != actorPlayerId) {
      return _rejected('unit_not_controlled');
    }
    if (unit.type != GameUnitType.scout) {
      return _rejected('unit_not_scout');
    }
    if (unit.isWorking || unit.isFortified) {
      return _rejected('unit_busy');
    }
    if (!unit.hasMovementRemaining) return _rejected('unit_exhausted');
    if (unit.queuedPath != null) return _rejected('unit_has_path');
    if (mapData.tileAt(unit.col, unit.row) == null) {
      return _rejected('unit_out_of_bounds');
    }
    return (unitIndex: unitIndex, unit: unit, reason: null);
  }

  static AutoExploreCommandGuardResult _rejected(String reason) =>
      (unitIndex: null, unit: null, reason: reason);

  static int? _unitIndexById(List<GameUnit> units, String unitId) {
    for (var index = 0; index < units.length; index++) {
      if (units[index].id == unitId) return index;
    }
    return null;
  }
}
