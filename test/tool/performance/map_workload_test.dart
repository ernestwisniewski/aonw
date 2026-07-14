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

    test('covers the duplicate MapDefinition lookup path', () {
      final result = runMapDefinitionLookupWorkload(
        scales: const [100],
        timingSamples: 2,
      );
      final sizes = result.stable['sizes']! as Map<String, Object?>;
      final stable = sizes['100']! as Map<String, Object?>;

      expect(result.name, 'map.definition-lookup');
      expect(stable['scale'], 100);
      expect(stable['probeCount'], 4);
      expect(stable['tileInspectionsByProbe'], {
        'first': 1,
        'middle': 51,
        'last': 100,
        'miss': 100,
      });
      expect(stable['tileInspections'], 252);
      expect(stable['outputDigest'], hasLength(64));
      expect(result.observations.toString(), contains('p95Micros'));
    });

    test('rejects unsupported scales', () {
      expect(
        () => runMapLookupWorkload(scales: const [999]),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => runMapDefinitionLookupWorkload(scales: const [999]),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
