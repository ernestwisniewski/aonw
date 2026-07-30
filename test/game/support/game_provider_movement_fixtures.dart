part of '../game_providers_test.dart';

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 50; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition was not met in time.');
}

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
