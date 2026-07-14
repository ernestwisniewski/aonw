import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/performance/measurement.dart';

void main() {
  test('summarizes samples without moving wall-clock into stable output', () {
    final result = PerformanceCaseResult(
      'fixture',
      const {'records': 3},
      {
        'runtime': timingObservation(const [
          Duration(microseconds: 1),
          Duration(microseconds: 2),
          Duration(microseconds: 100),
        ]),
      },
    );

    expect(median([1, 2, 100]), 2);
    expect(p95([1, 2, 100]), 100);
    expect(result.stable, {'records': 3});
    expect(jsonEncode(result.stable), isNot(contains('Micros')));
    expect(result.observations['runtime'], {
      'samples': 3,
      'medianMicros': 2.0,
      'p95Micros': 100.0,
      'minMicros': 1,
      'maxMicros': 100,
    });
  });

  test('median averages the middle pair and empty samples are rejected', () {
    expect(median([1, 3]), 2);
    expect(() => median(const []), throwsArgumentError);
    expect(() => p95(const []), throwsArgumentError);
    expect(() => timingObservation(const []), throwsArgumentError);
  });
}
