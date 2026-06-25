import 'package:aonw_core/game/domain/unit/game_unit_type.dart';

abstract final class UnitMovementBalance {
  static const commanderMovementPointsPerTurn = 5;
  static const footUnitMovementPointsPerTurn = 3;
  static const merchantMovementPointsPerTurn = 3;
  static const slowUnitMovementPointsPerTurn = 2;
  static const artifactCarrierMovementPointsPerTurn = 2;
  static const fastUnitMovementPointsPerTurn = 5;
  static const airUnitMovementPointsPerTurn = 7;

  static int maxMovementPointsFor({
    required GameUnitType type,
    String? carriedArtifactId,
  }) {
    if (carriedArtifactId != null && carriedArtifactId.isNotEmpty) {
      return artifactCarrierMovementPointsPerTurn;
    }
    return maxMovementPointsForType(type);
  }

  static int maxMovementPointsForType(GameUnitType type) {
    return switch (type) {
      GameUnitType.commander => commanderMovementPointsPerTurn,
      GameUnitType.warrior ||
      GameUnitType.archer ||
      GameUnitType.settler ||
      GameUnitType.worker ||
      GameUnitType.scout ||
      GameUnitType.spearman ||
      GameUnitType.heavyInfantry ||
      GameUnitType.rifleman => footUnitMovementPointsPerTurn,
      GameUnitType.merchant => merchantMovementPointsPerTurn,
      GameUnitType.catapult ||
      GameUnitType.fieldCannon => slowUnitMovementPointsPerTurn,
      GameUnitType.cavalry ||
      GameUnitType.tank ||
      GameUnitType.scoutShip ||
      GameUnitType.warship => fastUnitMovementPointsPerTurn,
      GameUnitType.reconPlane => airUnitMovementPointsPerTurn,
    };
  }
}
