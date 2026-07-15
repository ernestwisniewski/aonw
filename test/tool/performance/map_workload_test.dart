import 'package:flutter_test/flutter_test.dart';

import '../../../tool/performance/map_workload.dart';

void main() {
  group('map lookup workload', () {
    test(
      'covers the canonical scales with deterministic structural metrics',
      () {
        final result = runMapLookupWorkload(timingSamples: 2);
        final sizes = result.stable['sizes']! as Map<String, Object?>;
        final observationSizes =
            result.observations['sizes']! as Map<String, Object?>;

        expect(result.name, 'map.lookup');
        expect(sizes.keys, ['100', '1000', '10000']);
        for (final entry in sizes.entries) {
          final scale = int.parse(entry.key);
          final stable = entry.value! as Map<String, Object?>;
          expect(stable['probeCount'], 4);
          expect(stable['elementReadsByProbe'], {
            'first': 1,
            'middle': scale ~/ 2 + 1,
            'last': scale,
            'miss': scale,
          });
          expect(stable['elementReads'], scale * 2 + scale ~/ 2 + 2);
          expect(stable['outputDigest'], hasLength(64));
          expect(stable, isNot(contains('lookupBatchTiming')));
          expect(observationSizes[entry.key], contains('lookupBatchTiming'));
        }
      },
    );

    test('repeats with the same stable result', () {
      final first = runMapLookupWorkload(scales: const [100], timingSamples: 1);
      final second = runMapLookupWorkload(
        scales: const [100],
        timingSamples: 3,
      );

      expect(second.stable, first.stable);
      expect(second.observations, isNot(first.observations));
    });

    test('covers the canonical indexed WorldMap lookup path', () {
      final result = runWorldMapLookupWorkload(
        scales: const [100],
        timingSamples: 2,
      );
      final sizes = result.stable['sizes']! as Map<String, Object?>;
      final stable = sizes['100']! as Map<String, Object?>;

      expect(result.name, 'map.world-lookup');
      expect(stable['scale'], 100);
      expect(stable['dimensions'], {'cols': 10, 'rows': 10});
      expect(stable['probeCount'], 4);
      expect(stable['indexedTiles'], 100);
      expect(stable['lookupCalls'], 4);
      expect(stable['lookupCallsByProbe'], {
        'first': 1,
        'middle': 1,
        'last': 1,
        'miss': 1,
      });
      expect(
        stable['outputDigest'],
        'ca5f766ce3cb02db3c2168c7dff0278f9d6000baa538d37503192091edc835ac',
      );
      expect(result.observations.toString(), contains('p95Micros'));
    });

    test('repeats the WorldMap stable result', () {
      final first = runWorldMapLookupWorkload(
        scales: const [100],
        timingSamples: 1,
      );
      final second = runWorldMapLookupWorkload(
        scales: const [100],
        timingSamples: 3,
      );

      expect(second.stable, first.stable);
      expect(second.observations, isNot(first.observations));
    });

    test('covers bounded WorldMap-backed fog reveal at every scale', () {
      final result = runFogRevealWorkload(timingSamples: 2);
      final sizes = result.stable['sizes']! as Map<String, Object?>;
      final observationSizes =
          result.observations['sizes']! as Map<String, Object?>;
      final digests = <Object?>{};

      expect(result.name, 'map.fog-reveal');
      expect(sizes.keys, ['100', '1000', '10000']);
      for (final entry in sizes.entries) {
        final scale = int.parse(entry.key);
        final stable = entry.value! as Map<String, Object?>;
        expect(stable['indexedTiles'], scale);
        expect(stable['sourceCount'], 1);
        expect(stable['visionRange'], 3);
        expect(stable['visibleHexes'], 37);
        expect(stable['tileLookupCalls'], 223);
        expect(stable['tileLookupHits'], 223);
        expect(stable['outputDigest'], hasLength(64));
        expect(stable, isNot(contains('fogRevealTiming')));
        expect(observationSizes[entry.key], contains('fogRevealTiming'));
        digests.add(stable['outputDigest']);
      }
      expect(digests, {
        '15068531a02338cd87d989ed252edc11b218c549fec7dafaf3f94f18c59d0bb2',
      });
    });

    test('repeats the fog reveal stable result', () {
      final first = runFogRevealWorkload(scales: const [100], timingSamples: 1);
      final second = runFogRevealWorkload(
        scales: const [100],
        timingSamples: 3,
      );

      expect(second.stable, first.stable);
      expect(second.observations, isNot(first.observations));
    });

    test('rejects unsupported scales', () {
      expect(
        () => runMapLookupWorkload(scales: const [999]),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => runWorldMapLookupWorkload(scales: const [999]),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => runWorldMapLookupWorkload(timingSamples: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => runFogRevealWorkload(scales: const [999]),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => runFogRevealWorkload(timingSamples: 0),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
