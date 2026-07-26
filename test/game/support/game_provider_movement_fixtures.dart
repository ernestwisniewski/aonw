part of '../game_providers_test.dart';

WireMovementExecutionList _singleStepMove(String unitId) {
  return WireMovementExecutionList([
    WireMovementExecution(
      unitId: unitId,
      fromCol: 0,
      fromRow: 0,
      steps: const [
        WireMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      ],
    ),
  ]);
}
