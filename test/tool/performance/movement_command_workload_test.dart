import 'package:flutter_test/flutter_test.dart';

import '../../../tool/performance/movement_command_workload.dart';

void main() {
  test(
    'movement command kernel and adapters stay bounded across map scales',
    () {
      final result = runMovementCommandWorkload(timingSamples: 1);
      final sizes = result.stable['sizes']! as Map<String, Object?>;
      final observations =
          result.observations['sizes']! as Map<String, Object?>;
      final digests = <Object?>{};
      final lookupCalls = <Object?>{};

      expect(result.name, 'map.movement-command');
      expect(sizes.keys, ['100', '1000', '10000']);
      for (final entry in sizes.entries) {
        final scale = int.parse(entry.key);
        final stable = entry.value! as Map<String, Object?>;
        expect(stable['indexedTiles'], scale);
        expect(stable['boundaryCount'], 3);
        expect(stable['acceptedBoundaries'], 3);
        expect(stable['eventCount'], 3);
        expect(stable['executedSteps'], 9);
        expect(stable['diplomaticContacts'], 3);
        expect(stable['fogFullRecomputes'], 0);
        expect(stable['fogPlayerRecomputes'], 0);
        expect(stable['fogIncrementalRecomputes'], 3);
        expect(stable['fogFallbackRecomputes'], 0);
        expect(
          stable['tileLookupHits'],
          lessThanOrEqualTo(stable['tileLookupCalls']! as int),
        );
        expect(stable['uniqueTileLookupCoordinates'], lessThan(100));
        expect(stable['outputDigest'], hasLength(64));
        expect(stable, isNot(contains('movementCommandTiming')));
        expect(observations[entry.key], contains('movementCommandTiming'));
        digests.add(stable['outputDigest']);
        lookupCalls.add(stable['tileLookupCalls']);
      }
      expect(digests, hasLength(1));
      expect(lookupCalls, hasLength(1));
    },
  );

  test('movement command workload repeats its stable result', () {
    final first = runMovementCommandWorkload(
      scales: const [100],
      timingSamples: 1,
    );
    final second = runMovementCommandWorkload(
      scales: const [100],
      timingSamples: 2,
    );

    expect(second.stable, first.stable);
    expect(second.observations, isNot(first.observations));
  });

  test('movement command workload rejects invalid inputs', () {
    expect(
      () => runMovementCommandWorkload(scales: const [999]),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => runMovementCommandWorkload(timingSamples: 0),
      throwsA(isA<ArgumentError>()),
    );
  });
}
