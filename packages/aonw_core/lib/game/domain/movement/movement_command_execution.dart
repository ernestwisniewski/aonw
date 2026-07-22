import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';

/// Renderer-neutral description of the exact path executed by one command.
///
/// [steps] excludes the origin and includes only the prefix traversed during
/// this command. Presentation and transport adapters may project this payload
/// without having to run pathfinding again.
final class MovementCommandExecution {
  MovementCommandExecution({
    required this.unitId,
    required this.fromCol,
    required this.fromRow,
    required Iterable<UnitMovementStep> steps,
  }) : steps = List<UnitMovementStep>.unmodifiable(steps) {
    if (this.steps.isEmpty) {
      throw ArgumentError.value(
        steps,
        'steps',
        'An executed movement path must contain at least one travel step.',
      );
    }
  }

  final String unitId;
  final int fromCol;
  final int fromRow;
  final List<UnitMovementStep> steps;

  UnitMovementStep get destination => steps.last;
}
