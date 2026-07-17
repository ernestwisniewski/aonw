import 'package:flutter_test/flutter_test.dart';

import '../../tool/performance/turn_finalization_workload.dart';

void main() {
  test('turn finalization workload exercises the canonical boundary', () {
    final result = runTurnFinalizationWorkload(
      entityCounts: const [12],
      timingSamples: 2,
    );
    final sizes = result.stable['sizes']! as Map<String, Object?>;
    final sample = sizes['12']! as Map<String, Object?>;
    final observationSizes =
        result.observations['sizes']! as Map<String, Object?>;
    final observation = observationSizes['12']! as Map<String, Object?>;
    final timing = observation['boundaryRoundTrip']! as Map<String, Object?>;

    expect(result.name, 'turn.finalization');
    expect(result.stable['entityCounts'], [12]);
    expect(sample['inputEntities'], 12);
    expect(sample['outputEntities'], 12);
    expect(sample['inputUnits'], 2);
    expect(sample['outputUnits'], 2);
    expect(sample['inputArtifacts'], 10);
    expect(sample['outputArtifacts'], 10);
    expect(sample['eventCount'], greaterThan(0));
    expect(sample['inputOffset'], 31);
    expect(sample['outputOffset'], 31);
    expect(sample['offsetPreserved'], isTrue);
    expect(sample['inputTurn'], 7);
    expect(sample['outputTurn'], 8);
    expect(
      sample['outputDigest'],
      isA<String>().having((value) => value.length, 'length', 64),
    );
    expect(result.observations['portableTimingGate'], isFalse);
    expect(result.observations['samplesPerCase'], 2);
    expect(timing['samples'], 2);
  });
}
