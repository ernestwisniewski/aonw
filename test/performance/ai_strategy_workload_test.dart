import 'package:flutter_test/flutter_test.dart';

import '../../tool/performance/ai_strategy_workload.dart';

void main() {
  test('strategy-aware workload runs the production MCTS planning path', () {
    final result = runAiStrategyWorkload(
      iterationCounts: const [12],
      samplesPerCase: 2,
    );
    final sizes = result.stable['sizes']! as Map<String, Object?>;
    final sample = sizes['12']! as Map<String, Object?>;

    expect(result.name, 'ai.mcts.strategy-aware-plan');
    expect(sample['iterations'], 12);
    expect(sample['candidateCalls'], greaterThan(0));
    expect(sample['rawCandidates'], greaterThan(0));
    expect(sample['commandDigest'], hasLength(64));
    expect(result.observations['portableTimingGate'], isFalse);
  });
}
