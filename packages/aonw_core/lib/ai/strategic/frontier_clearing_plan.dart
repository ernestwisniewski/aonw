import 'package:aonw_core/game/domain/hex.dart';

class FrontierClearingPlan {
  final Map<String, StrategicFrontierClearingAssignment> assignments;

  FrontierClearingPlan({
    required Map<String, StrategicFrontierClearingAssignment> assignments,
  }) : assignments = Map.unmodifiable(assignments);

  static final empty = FrontierClearingPlan(assignments: const {});
}

class StrategicFrontierClearingAssignment {
  final String unitId;
  final String founderId;
  final String targetPlayerId;
  final HexCoordinate targetHex;
  final int founderDistance;
  final double priority;

  const StrategicFrontierClearingAssignment({
    required this.unitId,
    required this.founderId,
    required this.targetPlayerId,
    required this.targetHex,
    required this.founderDistance,
    required this.priority,
  });

  @override
  bool operator ==(Object other) {
    return other is StrategicFrontierClearingAssignment &&
        other.unitId == unitId &&
        other.founderId == founderId &&
        other.targetPlayerId == targetPlayerId &&
        other.targetHex == targetHex &&
        other.founderDistance == founderDistance &&
        other.priority == priority;
  }

  @override
  int get hashCode {
    return Object.hash(
      unitId,
      founderId,
      targetPlayerId,
      targetHex,
      founderDistance,
      priority,
    );
  }
}
