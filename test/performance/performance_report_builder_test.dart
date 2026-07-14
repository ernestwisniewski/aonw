import 'package:flutter_test/flutter_test.dart';

import '../../tool/performance/failure.dart';
import '../../tool/performance/measurement.dart';
import '../../tool/performance/report_builder.dart';

void main() {
  test('builds one strict report from unique workload results', () {
    final report = buildPerformanceReport([
      PerformanceCaseResult(
        'map.lookup',
        const {'reads': 4},
        const {'p95Micros': 12},
      ),
      PerformanceCaseResult(
        'replay',
        const {'events': 100},
        const {'p95Micros': 30},
      ),
    ]);

    expect(report.stable.keys, ['map.lookup', 'replay']);
    expect(report.observations.keys, ['map.lookup', 'replay']);
    expect(report.baseline.canonicalJson, isNot(contains('p95Micros')));
  });

  test('rejects duplicate workload names', () {
    final duplicate = PerformanceCaseResult(
      'map.lookup',
      const {'reads': 4},
      const {'p95Micros': 12},
    );

    expect(
      () => buildPerformanceReport([duplicate, duplicate]),
      throwsA(
        isA<PerformanceFailure>().having(
          (error) => error.message,
          'message',
          contains('duplicated: map.lookup'),
        ),
      ),
    );
  });
}
