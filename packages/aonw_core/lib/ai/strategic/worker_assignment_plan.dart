import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/util/collection_equality.dart';

class WorkerAssignmentPlan {
  final Map<String, StrategicWorkerAssignment> assignments;

  WorkerAssignmentPlan({
    required Map<String, StrategicWorkerAssignment> assignments,
  }) : assignments = Map.unmodifiable(assignments);

  static final empty = WorkerAssignmentPlan(assignments: const {});
}

class StrategicWorkerAssignment {
  final String workerId;
  final String cityId;
  final List<StrategicWorkerTarget> targets;

  StrategicWorkerAssignment({
    required this.workerId,
    required this.cityId,
    required Iterable<StrategicWorkerTarget> targets,
  }) : targets = List.unmodifiable(targets);

  StrategicWorkerTarget? get primaryTarget =>
      targets.isEmpty ? null : targets.first;

  @override
  bool operator ==(Object other) {
    return other is StrategicWorkerAssignment &&
        other.workerId == workerId &&
        other.cityId == cityId &&
        listEquals(other.targets, targets);
  }

  @override
  int get hashCode => Object.hash(workerId, cityId, Object.hashAll(targets));
}

class StrategicWorkerTarget {
  final String cityId;
  final CityHex targetHex;
  final FieldImprovementType improvementType;
  final int score;
  final int buildTurns;
  final bool existingImprovement;

  const StrategicWorkerTarget({
    required this.cityId,
    required this.targetHex,
    required this.improvementType,
    required this.score,
    required this.buildTurns,
    required this.existingImprovement,
  });

  @override
  bool operator ==(Object other) {
    return other is StrategicWorkerTarget &&
        other.cityId == cityId &&
        other.targetHex == targetHex &&
        other.improvementType == improvementType &&
        other.score == score &&
        other.buildTurns == buildTurns &&
        other.existingImprovement == existingImprovement;
  }

  @override
  int get hashCode {
    return Object.hash(
      cityId,
      targetHex,
      improvementType,
      score,
      buildTurns,
      existingImprovement,
    );
  }
}
