import 'package:flutter_test/flutter_test.dart';

import '../../../tool/performance/replay_workload.dart';

void main() {
  test('replays contiguous commands through the canonical engine', () async {
    final result = await runReplayWorkload(timingSamples: 1);
    final sizes = result.stable['sizes']! as Map<String, Object?>;

    expect(result.name, 'replay');
    expect(sizes.keys, ['100', '1000', '10000']);
    final stateDigests = <Object?>{};
    for (final events in replayWorkloadScales) {
      final scale = sizes['$events']! as Map<String, Object?>;
      expect(scale['events'], events);
      expect(scale['commandsYielded'], events);
      expect(scale['commandKinds'], {
        'endTurn': events ~/ 4,
        'selectTechnology': events ~/ 4,
        'skipUnitTurn': events ~/ 4,
        'submitTurn': events ~/ 4,
      });
      expect(scale['commandDigest'], matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(scale['steps'], events);
      expect(scale['finalOffset'], events);
      expect(scale['stateDigest'], matches(RegExp(r'^[0-9a-f]{64}$')));
      stateDigests.add(scale['stateDigest']);
    }
    expect(stateDigests, isNotEmpty);
    expect(result.stable.toString(), isNot(contains('Micros')));
    expect(result.observations.toString(), contains('medianMicros'));

    final repeated = await runReplayWorkload(
      scales: const [100],
      timingSamples: 2,
    );
    final repeatedSizes = repeated.stable['sizes']! as Map<String, Object?>;
    expect(repeatedSizes['100'], sizes['100']);
  });
}
