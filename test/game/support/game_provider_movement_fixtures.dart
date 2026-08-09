import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> waitForGameProviderCondition(bool Function() condition) async {
  for (var i = 0; i < 50; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition was not met in time.');
}

WireMovementExecutionList singleStepMovement(String unitId) {
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
