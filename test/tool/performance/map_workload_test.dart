import 'package:flutter_test/flutter_test.dart';

import '../../../tool/performance/map_workload.dart';

void main() {
  group('map lookup workload', () {
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
      expect(stable['worldTileHits'], 3);
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

    test('keeps fixed-distance movement work bounded at every scale', () {
      final result = runMovementPathWorkload(timingSamples: 1);
      final sizes = result.stable['sizes']! as Map<String, Object?>;
      final observationSizes =
          result.observations['sizes']! as Map<String, Object?>;
      final structuralDigests = <Object?>{};
      final lookupCalls = <Object?>{};
      final uniqueLookupCoordinates = <Object?>{};

      expect(result.name, 'map.movement-path');
      expect(sizes.keys, ['100', '1000', '10000']);
      for (final entry in sizes.entries) {
        final scale = int.parse(entry.key);
        final stable = entry.value! as Map<String, Object?>;
        expect(stable['indexedTiles'], scale);
        expect(stable['targetDistance'], 3);
        expect(stable['pathSteps'], 4);
        expect(stable['totalCost'], 6);
        expect(stable['uniqueTileLookupCoordinates'], stable['uniqueTileHits']);
        expect(stable['uniqueTileHits'], lessThan(100));
        expect(stable['outputDigest'], hasLength(64));
        expect(stable, isNot(contains('movementPathTiming')));
        expect(observationSizes[entry.key], contains('movementPathTiming'));
        structuralDigests.add(stable['outputDigest']);
        lookupCalls.add(stable['tileLookupCalls']);
        uniqueLookupCoordinates.add(stable['uniqueTileLookupCoordinates']);
      }
      expect(structuralDigests, hasLength(1));
      expect(lookupCalls, hasLength(1));
      expect(uniqueLookupCoordinates, hasLength(1));
    });

    test('repeats the movement path stable result', () {
      final first = runMovementPathWorkload(
        scales: const [100],
        timingSamples: 1,
      );
      final second = runMovementPathWorkload(
        scales: const [100],
        timingSamples: 2,
      );

      expect(second.stable, first.stable);
      expect(second.observations, isNot(first.observations));
    });

    test('bounds auto-explore candidate evaluation at every scale', () {
      final result = runAutoExploreWorkload(timingSamples: 1);
      final sizes = result.stable['sizes']! as Map<String, Object?>;
      final observationSizes =
          result.observations['sizes']! as Map<String, Object?>;
      final digests = <Object?>{};
      var previousLookupCalls = 0;
      var previousUniqueLookupCoordinates = 0;

      expect(result.name, 'map.auto-explore');
      expect(sizes.keys, ['100', '1000', '10000']);
      for (final entry in sizes.entries) {
        final scale = int.parse(entry.key);
        final stable = entry.value! as Map<String, Object?>;
        final lookupCalls = stable['tileLookupCalls']! as int;
        final uniqueLookupCoordinates =
            stable['uniqueTileLookupCoordinates']! as int;
        expect(stable['indexedTiles'], scale);
        expect(stable['growthModel'], 'reachable-index-vision-bound-exit');
        expect(stable['candidateEvaluations'], 1);
        expect(stable['uniqueTileHits'], scale);
        expect(uniqueLookupCoordinates, greaterThanOrEqualTo(scale));
        expect(lookupCalls, greaterThan(previousLookupCalls));
        expect(
          uniqueLookupCoordinates,
          greaterThan(previousUniqueLookupCoordinates),
        );
        expect(stable['outputDigest'], hasLength(64));
        expect(stable, isNot(contains('autoExploreTiming')));
        expect(observationSizes[entry.key], contains('autoExploreTiming'));
        digests.add(stable['outputDigest']);
        previousLookupCalls = lookupCalls;
        previousUniqueLookupCoordinates = uniqueLookupCoordinates;
      }
      expect(digests, hasLength(1));
    });

    test('repeats the auto-explore stable result', () {
      final first = runAutoExploreWorkload(
        scales: const [100],
        timingSamples: 1,
      );
      final second = runAutoExploreWorkload(
        scales: const [100],
        timingSamples: 2,
      );

      expect(second.stable, first.stable);
      expect(second.observations, isNot(first.observations));
    });

    test('rejects unsupported scales', () {
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
      expect(
        () => runMovementPathWorkload(scales: const [999]),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => runMovementPathWorkload(timingSamples: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => runAutoExploreWorkload(scales: const [999]),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => runAutoExploreWorkload(timingSamples: 0),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
