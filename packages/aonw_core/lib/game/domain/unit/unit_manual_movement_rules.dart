import 'package:aonw_core/game/domain/movement/unit_movement_balance.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';

/// Canonical unit-state policy shared by manual-movement planning and
/// authoritative command execution.
abstract final class UnitManualMovementRules {
  static bool canStartTargeting(GameUnit unit) {
    return !unit.isWorking &&
        unit.type != GameUnitType.merchant &&
        unit.queuedPath == null &&
        !unit.isAutoExploring &&
        availableMovementPoints(unit) > 0;
  }

  static int availableMovementPoints(GameUnit unit) {
    return unit.isFortified
        ? UnitMovementBalance.maxMovementPointsFor(
            type: unit.type,
            carriedArtifactId: unit.carriedArtifactId,
          )
        : unit.movementPoints;
  }

  /// Wakes a fortified unit as part of an accepted manual move.
  ///
  /// Callers must not persist this projection before the command has passed
  /// all validation. This keeps rejected moves atomic.
  static GameUnit prepareForCommand(GameUnit unit) {
    if (!unit.isFortified) return unit;
    return unit
        .copyWith(
          movementPoints: availableMovementPoints(unit),
          posture: UnitPosture.active,
        )
        .copyWithQueuedPath(null);
  }
}
