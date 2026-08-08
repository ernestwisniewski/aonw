import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/field_improvement_type.dart';

sealed class WorkerAutomationTarget {
  const WorkerAutomationTarget({
    required this.cityId,
    required this.hex,
    required this.movementCost,
  });

  final String cityId;
  final CityHex hex;
  final int movementCost;
}

final class WorkerAutomationBuildTarget extends WorkerAutomationTarget {
  const WorkerAutomationBuildTarget({
    required super.cityId,
    required super.hex,
    required super.movementCost,
    required this.improvementType,
    required this.recommendationScore,
    required this.buildTurns,
  });

  final FieldImprovementType improvementType;
  final int recommendationScore;
  final int buildTurns;
}

final class WorkerAutomationAssignmentTarget extends WorkerAutomationTarget {
  const WorkerAutomationAssignmentTarget({
    required super.cityId,
    required super.hex,
    required super.movementCost,
    required this.yieldScore,
  });

  final int yieldScore;
}
