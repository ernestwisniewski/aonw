import 'package:flutter_test/flutter_test.dart';

import '../../tool/performance/document.dart';
import '../../tool/performance/failure.dart';
import '../../tool/performance/gate.dart';
import '../../tool/release/canonical_json.dart';

void main() {
  const stable = <String, Object?>{
    'map.lookup': <String, Object?>{
      'sizes': <String, Object?>{
        '100': <String, Object?>{'maxProbes': 100},
      },
    },
  };
  final report = PerformanceReportDocument(
    stable: stable,
    observations: const {
      'map.lookup': <String, Object?>{'p95Micros': 10},
    },
  );
  final baseline = PerformanceBaselineDocument(stable: stable);
  final policy = PerformancePolicyDocument(requiredCases: const ['map.lookup']);

  test('snapshot excludes timing observations', () {
    expect(report.baseline.canonicalJson, baseline.canonicalJson);
    expect(report.baseline.canonicalJson, isNot(contains('p95Micros')));
  });

  test('passes exact stable metrics and ignores observation drift', () {
    final driftedObservations = PerformanceReportDocument(
      stable: stable,
      observations: const {
        'map.lookup': <String, Object?>{'p95Micros': 999999},
      },
    );
    final result = const PerformanceGate().check(
      report: driftedObservations,
      baseline: baseline,
      policy: policy,
    );
    expect(result.cases, 1);
  });

  test('rejects missing, unknown, and drifted stable cases', () {
    expect(
      () => const PerformanceGate().check(
        report: PerformanceReportDocument(
          stable: const {'other': <String, Object?>{}},
          observations: const {'other': <String, Object?>{}},
        ),
        baseline: baseline,
        policy: policy,
      ),
      _failsContaining('missing: map.lookup'),
    );
    final drifted = PerformanceReportDocument(
      stable: const {
        'map.lookup': <String, Object?>{
          'sizes': <String, Object?>{
            '100': <String, Object?>{'maxProbes': 101},
          },
        },
      },
      observations: const {'map.lookup': <String, Object?>{}},
    );
    expect(
      () => const PerformanceGate().check(
        report: drifted,
        baseline: baseline,
        policy: policy,
      ),
      _failsContaining('stable.map.lookup.sizes.100.maxProbes'),
    );
  });

  test('report requires exact stable and observation case sets', () {
    expect(
      () => PerformanceReportDocument(stable: stable, observations: const {}),
      _failsContaining('missing: map.lookup'),
    );
    expect(
      () => PerformanceReportDocument(
        stable: stable,
        observations: const {
          'map.lookup': <String, Object?>{},
          'unknown': <String, Object?>{},
        },
      ),
      _failsContaining('unknown: unknown'),
    );
  });

  test('strict documents allow one file newline only', () {
    final canonical = report.canonicalJson;
    expect(
      PerformanceReportDocument.parseCanonical('$canonical\n').canonicalJson,
      canonical,
    );
    expect(
      () => PerformanceReportDocument.parseCanonical('$canonical\n\n'),
      _failsContaining('must be canonical'),
    );
  });

  test('strict documents reject unknown fields and unsorted policy', () {
    expect(
      () => PerformanceReportDocument.parseCanonical(
        encodeCanonicalJson({...report.toJson(), 'unknown': true}),
      ),
      _failsContaining('unknown: unknown'),
    );
    expect(
      () => PerformancePolicyDocument(requiredCases: const ['z', 'a']),
      _failsContaining('strictly sorted'),
    );
  });
}

Matcher _failsContaining(String text) => throwsA(
  isA<PerformanceFailure>().having(
    (error) => error.message,
    'message',
    contains(text),
  ),
);
