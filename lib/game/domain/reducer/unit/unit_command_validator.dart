import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw_core/game/domain/unit.dart';

enum UnitCommandValidationFailureReason {
  missingUnit,
  notControllable,
  working,
  fortified,
  queuedPath,
  noMovement,
  unsupportedUnitType,
}

sealed class UnitCommandValidationResult {
  const UnitCommandValidationResult();
}

final class ValidUnit extends UnitCommandValidationResult {
  final GameUnit unit;

  const ValidUnit(this.unit);
}

final class InvalidUnit extends UnitCommandValidationResult {
  final UnitCommandValidationFailureReason reason;

  const InvalidUnit(this.reason);
}

abstract final class UnitCommandValidator {
  static UnitCommandValidationResult controllableUnit(
    GameClientState state, {
    required String unitId,
    required GameCommandContext context,
  }) {
    final unit = state.unitById(unitId);
    if (unit == null) {
      return const InvalidUnit(UnitCommandValidationFailureReason.missingUnit);
    }
    if (!context.canControlUnit(state, unit)) {
      return const InvalidUnit(
        UnitCommandValidationFailureReason.notControllable,
      );
    }
    return ValidUnit(unit);
  }

  static UnitCommandValidationResult movableUnit(
    GameClientState state, {
    required String unitId,
    required GameCommandContext context,
  }) {
    final result = controllableUnit(state, unitId: unitId, context: context);
    if (result is! ValidUnit) return result;
    final unit = result.unit;
    if (unit.isWorking) {
      return const InvalidUnit(UnitCommandValidationFailureReason.working);
    }
    if (unit.isFortified) {
      return const InvalidUnit(UnitCommandValidationFailureReason.fortified);
    }
    if (unit.type == GameUnitType.merchant) {
      return const InvalidUnit(
        UnitCommandValidationFailureReason.unsupportedUnitType,
      );
    }
    return result;
  }

  static UnitCommandValidationResult fortifiableUnit(
    GameClientState state, {
    required String unitId,
    required GameCommandContext context,
  }) {
    final result = controllableUnit(state, unitId: unitId, context: context);
    if (result is! ValidUnit) return result;
    if (result.unit.isWorking) {
      return const InvalidUnit(UnitCommandValidationFailureReason.working);
    }
    return result;
  }

  static UnitCommandValidationResult autoExplorableScout(
    GameClientState state, {
    required String unitId,
    required GameCommandContext context,
  }) {
    final result = movableUnit(state, unitId: unitId, context: context);
    if (result is! ValidUnit) return result;
    final unit = result.unit;
    if (unit.type != GameUnitType.scout) {
      return const InvalidUnit(
        UnitCommandValidationFailureReason.unsupportedUnitType,
      );
    }
    if (unit.movementPoints <= 0) {
      return const InvalidUnit(UnitCommandValidationFailureReason.noMovement);
    }
    if (unit.queuedPath != null) {
      return const InvalidUnit(UnitCommandValidationFailureReason.queuedPath);
    }
    return result;
  }
}
