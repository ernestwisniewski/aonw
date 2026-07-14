import 'package:flutter_test/flutter_test.dart';

import '../../../tool/performance/persistence_workload.dart';

void main() {
  test(
    'uses real JSON log and snapshot codec with deterministic output',
    () async {
      final result = await runPersistenceWorkload(timingSamples: 1);
      final sizes = result.stable['sizes']! as Map<String, Object?>;

      expect(result.name, 'persistence');
      expect(sizes.keys, ['100', '1000', '10000']);
      for (final records in persistenceWorkloadScales) {
        final scale = sizes['$records']! as Map<String, Object?>;
        final eventLog = scale['eventLog']! as Map<String, Object?>;
        final snapshot = scale['snapshot']! as Map<String, Object?>;
        final append = eventLog['append']! as Map<String, Object?>;
        expect(eventLog['records'], records);
        expect(eventLog['latestOffset'], records);
        expect(eventLog['readSinceRecords'], 10);
        expect(eventLog['bytes'], greaterThan(0));
        expect(eventLog['digest'], matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(append['appendedOffset'], records + 1);
        expect(append['finalBytes'], greaterThan(eventLog['bytes']! as int));
        expect(append['digest'], matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(snapshot['records'], records);
        expect(snapshot['bytes'], greaterThan(0));
        expect(snapshot['digest'], matches(RegExp(r'^[0-9a-f]{64}$')));
      }
      expect(result.stable.toString(), isNot(contains('Micros')));
      expect(result.observations.toString(), contains('medianMicros'));

      final repeated = await runPersistenceWorkload(
        scales: const [100],
        timingSamples: 2,
      );
      final repeatedSizes = repeated.stable['sizes']! as Map<String, Object?>;
      expect(repeatedSizes['100'], sizes['100']);
    },
  );
}
