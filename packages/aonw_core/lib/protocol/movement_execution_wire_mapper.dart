import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/protocol/wire_movement_execution.dart';

abstract final class MovementExecutionWireMapper {
  static WireMovementExecution encode(MovementCommandExecution execution) {
    return WireMovementExecution(
      unitId: execution.unitId,
      fromCol: execution.fromCol,
      fromRow: execution.fromRow,
      steps: [
        for (final step in execution.steps)
          WireMovementStep(
            col: step.col,
            row: step.row,
            enterCost: step.enterCost,
            cumulativeCost: step.cumulativeCost,
          ),
      ],
    );
  }

  static MovementCommandExecution decode(WireMovementExecution execution) {
    return MovementCommandExecution(
      unitId: execution.unitId,
      fromCol: execution.fromCol,
      fromRow: execution.fromRow,
      steps: [
        for (final step in execution.steps)
          UnitMovementStep(
            col: step.col,
            row: step.row,
            enterCost: step.enterCost,
            cumulativeCost: step.cumulativeCost,
          ),
      ],
    );
  }
}
