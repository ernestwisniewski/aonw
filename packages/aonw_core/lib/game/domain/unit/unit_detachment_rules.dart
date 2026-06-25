import 'package:aonw_core/game/domain/movement/unit_movement_balance.dart';
import 'package:aonw_core/game/domain/unit/army_troop.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';

class UnitDetachmentResult {
  final GameUnit updatedSource;
  final GameUnit detachedUnit;

  const UnitDetachmentResult({
    required this.updatedSource,
    required this.detachedUnit,
  });
}

abstract final class UnitDetachmentRules {
  static UnitDetachmentResult? detachTroop({
    required GameUnit source,
    required TroopType troopType,
    required String detachedUnitId,
    required int destinationCol,
    required int destinationRow,
  }) {
    if (!source.canDetachTroop(troopType)) return null;

    final detachedType = troopType.detachedUnitType;
    final detachedMovement = UnitMovementBalance.maxMovementPointsForType(
      detachedType,
    );

    return UnitDetachmentResult(
      updatedSource: source.detachTroop(troopType),
      detachedUnit: GameUnit(
        id: detachedUnitId,
        ownerPlayerId: source.ownerPlayerId,
        type: detachedType,
        name: troopType.detachedUnitNameToken,
        col: destinationCol,
        row: destinationRow,
        movementPoints: detachedMovement,
      ),
    );
  }

  static bool isDetachedTroop(GameUnit unit) {
    return unit.type == GameUnitType.warrior ||
        unit.type == GameUnitType.archer ||
        unit.type == GameUnitType.settler;
  }
}
