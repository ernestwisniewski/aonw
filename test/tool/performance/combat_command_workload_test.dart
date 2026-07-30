import 'package:flutter_test/flutter_test.dart';

import '../../../tool/performance/combat_command_workload.dart';

void main() {
  test('combat command boundaries stay deterministic and bounded by scale', () {
    final result = runCombatCommandWorkload(timingSamples: 1);
    final sizes = result.stable['sizes']! as Map<String, Object?>;
    final observations = result.observations['sizes']! as Map<String, Object?>;
    final outputDigests = <Object?>{};
    final eventDigests = <Object?>{};
    final outcomeDigests = <Object?>{};
    final contactDigests = <Object?>{};
    final lookupCalls = <Object?>{};

    expect(result.name, 'map.combat-command');
    expect(result.observations['samplesPerBoundary'], 1);
    expect(sizes.keys, ['100', '1000', '10000']);
    for (final entry in sizes.entries) {
      final scale = int.parse(entry.key);
      final stable = entry.value! as Map<String, Object?>;
      final boundaryDigests =
          stable['boundaryOutputDigests']! as Map<String, Object?>;
      final fogFullRecomputes =
          stable['fogFullRecomputesByBoundary']! as Map<String, Object?>;
      final fogPlayerRecomputes =
          stable['fogPlayerRecomputesByBoundary']! as Map<String, Object?>;
      final calls =
          stable['tileLookupCallsByBoundary']! as Map<String, Object?>;
      final hits = stable['tileLookupHitsByBoundary']! as Map<String, Object?>;
      final timing = observations[entry.key]! as Map<String, Object?>;

      expect(stable['inputEntities'], scale);
      expect(stable['inputArtifacts'], scale - 2);
      expect(stable['boundaryCount'], 3);
      expect(stable['acceptedBoundaries'], 3);
      expect(stable['combatResolvedEvents'], 3);
      expect(stable['eventCount'], greaterThanOrEqualTo(6));
      expect(stable['diplomaticContacts'], 3);
      expect(boundaryDigests.keys, ['kernel', 'engine', 'domain']);
      expect(boundaryDigests.values.toSet(), hasLength(1));
      expect(fogFullRecomputes.values.toSet(), {0, 1});
      expect(fogPlayerRecomputes.values.toSet(), {0});
      expect(calls.values.toSet(), hasLength(1));
      expect(hits.values.toSet(), hasLength(1));
      for (final boundary in calls.keys) {
        expect(hits[boundary], lessThanOrEqualTo(calls[boundary]! as int));
      }
      expect(timing.keys, {
        'kernelTiming',
        'engineTiming',
        'domainAdapterTiming',
      });
      for (final value in timing.values) {
        expect(value, containsPair('samples', 1));
      }
      for (final digestName in const [
        'eventDigest',
        'outcomeDigest',
        'contactDigest',
        'outputDigest',
      ]) {
        expect(stable[digestName], hasLength(64));
      }

      outputDigests.add(stable['outputDigest']);
      eventDigests.add(stable['eventDigest']);
      outcomeDigests.add(stable['outcomeDigest']);
      contactDigests.add(stable['contactDigest']);
      lookupCalls.add(
        '${calls['kernel']}:${calls['persistent']}:${calls['domain']}',
      );
    }

    expect(outputDigests, hasLength(1));
    expect(eventDigests, hasLength(1));
    expect(outcomeDigests, hasLength(1));
    expect(contactDigests, hasLength(1));
    expect(lookupCalls, hasLength(1));
  });

  test('combat command workload repeats its stable result', () {
    final first = runCombatCommandWorkload(
      scales: const [100],
      timingSamples: 1,
    );
    final second = runCombatCommandWorkload(
      scales: const [100],
      timingSamples: 2,
    );

    expect(second.stable, first.stable);
    expect(second.observations['samplesPerBoundary'], 2);
  });

  test('combat command workload rejects invalid inputs', () {
    expect(
      () => runCombatCommandWorkload(scales: const [999]),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => runCombatCommandWorkload(timingSamples: 0),
      throwsA(isA<ArgumentError>()),
    );
  });
}
