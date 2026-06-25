import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';

class QueuedMovePath {
  final int targetCol;
  final int targetRow;
  final List<UnitMovementStep> steps;

  QueuedMovePath({
    required this.targetCol,
    required this.targetRow,
    required List<UnitMovementStep> steps,
  }) : steps = List.unmodifiable(steps);

  factory QueuedMovePath.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List<dynamic>;
    return QueuedMovePath(
      targetCol: (json['targetCol'] as num).toInt(),
      targetRow: (json['targetRow'] as num).toInt(),
      steps: [
        for (final step in rawSteps)
          _stepFromJson(step as Map<String, dynamic>),
      ],
    );
  }

  static UnitMovementStep _stepFromJson(Map<String, dynamic> json) {
    return UnitMovementStep(
      col: (json['col'] as num).toInt(),
      row: (json['row'] as num).toInt(),
      enterCost: (json['enterCost'] as num).toInt(),
      cumulativeCost: (json['cumulativeCost'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'targetCol': targetCol,
    'targetRow': targetRow,
    'steps': [
      for (final s in steps)
        {
          'col': s.col,
          'row': s.row,
          'enterCost': s.enterCost,
          'cumulativeCost': s.cumulativeCost,
        },
    ],
  };
}
