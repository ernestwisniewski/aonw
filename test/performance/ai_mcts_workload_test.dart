import 'package:flutter_test/flutter_test.dart';

import '../../tool/performance/ai_mcts_workload.dart';

void main() {
  test('MCTS workload uses an exact deterministic iteration budget', () {
    final result = runAiMctsWorkload(
      iterationCounts: const [12],
      samplesPerCase: 2,
    );
    final sizes = result.stable['sizes']! as Map<String, Object?>;
    final sample = sizes['12']! as Map<String, Object?>;

    expect(result.name, 'ai.mcts.iteration-search');
    expect(sample['iterations'], 12);
    expect(sample['rootChildren'], 3);
    expect(sample['rootChildVisitsTotal'], 12);
    expect(sample['visitedRootChildren'], 3);
    expect(sample['exploredNodes'], greaterThan(1));
    expect(sample['plannedActions'], greaterThan(0));
    expect(result.observations['portableTimingGate'], isFalse);
  });
}
