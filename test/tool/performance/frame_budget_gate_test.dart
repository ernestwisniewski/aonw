import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/performance/failure.dart';
import '../../../tool/performance/frame_budget_gate.dart';
import '../../../tool/performance/frame_budget_report.dart';

void main() {
  group('reference-profile frame budget', () {
    test('accepts every metric at its boundary', () {
      final report = FrameBudgetReport.parse(jsonEncode(_validReport()));

      final result = const FrameBudgetGate().check(
        report,
        expectedDeviceId: _deviceId,
      );

      expect(result.deviceId, 'pixel-8-pro-reference-01');
      expect(result.sampleFrames, 600);
      expect(result.metricsChecked, 7);
      expect(report.metrics.slowFrameThresholdMicros, 16667);
      expect(report.metrics.slowFrameCount, 6);
    });

    test('rejects malformed reports and invalid metadata', () {
      final cases = <({Map<String, Object?> report, String message})>[
        (report: _reportWith('schemaVersion', 2), message: 'must be 1'),
        (
          report: _metadataWith('buildMode', 'release'),
          message: 'metadata.buildMode must be "profile"',
        ),
        (
          report: _metadataWith('deviceId', '  '),
          message: 'metadata.deviceId must be a non-empty',
        ),
        (
          report: _metadataWith('scenario', 'renderer.frame.600'),
          message: 'metadata.scenario must be "renderer.frame.1000"',
        ),
        (
          report: _metadataWith('assetMode', 'fallback-no-assets'),
          message: 'metadata.assetMode must be "bundled-assets"',
        ),
        (
          report: _metadataWith('sampleFrames', 599),
          message: 'metadata.sampleFrames must be at least 600',
        ),
        (
          report: _slowFramesWith('thresholdMicros', 16000),
          message: 'metrics.slowFrames.thresholdMicros must be 16667',
        ),
        (
          report: _slowFramesWith('count', 601),
          message: 'metrics.slowFrames.count must be between 0 and 600',
        ),
        (
          report: _metricWith('uiBuild', 'p95Micros', -1),
          message: 'metrics.uiBuild.p95Micros must be a finite non-negative',
        ),
      ];

      for (final fixture in cases) {
        expect(
          () => FrameBudgetReport.parse(jsonEncode(fixture.report)),
          _failsContaining(fixture.message),
          reason: fixture.message,
        );
      }
      expect(
        () => FrameBudgetReport.parse('{not-json'),
        _failsContaining('Invalid frame budget report JSON'),
      );
    });

    test('rejects unknown fields and inconsistent percentiles', () {
      final unknown = _validReport()..['unknown'] = true;
      final inconsistent = _validReport();
      final metrics = inconsistent['metrics']! as Map<String, Object?>;
      (metrics['totalFrame']! as Map<String, Object?>)
        ..['p95Micros'] = 33001
        ..['p99Micros'] = 33000;

      expect(
        () => FrameBudgetReport.parse(jsonEncode(unknown)),
        _failsContaining('unknown: unknown'),
      );
      expect(
        () => FrameBudgetReport.parse(jsonEncode(inconsistent)),
        _failsContaining('p95Micros must not exceed p99Micros'),
      );
    });

    test('reports every exceeded metric in one failure', () {
      final report = FrameBudgetReport.parse(jsonEncode(_exceededReport()));
      const gate = FrameBudgetGate();

      expect(gate.violationsFor(report), hasLength(7));
      try {
        gate.check(report, expectedDeviceId: _deviceId);
        fail('Expected the frame budget gate to fail.');
      } on PerformanceFailure catch (error) {
        expect(error.message, contains('pixel-8-pro-reference-01'));
        for (final metric in const [
          'totalFrame.p95Micros',
          'totalFrame.p99Micros',
          'slowFrames.basisPoints',
          'uiBuild.p95Micros',
          'raster.p95Micros',
          'flameUpdate.p95Micros',
          'renderSubmission.p95Micros',
        ]) {
          expect(error.message, contains(metric));
        }
      }
    });

    test('rejects a report from a different device', () {
      final report = FrameBudgetReport.parse(jsonEncode(_validReport()));

      expect(
        () => const FrameBudgetGate().check(
          report,
          expectedDeviceId: 'pixel-8-pro-reference-02',
        ),
        _failsContaining('does not match the expected pinned device'),
      );
    });
  });
}

Map<String, Object?> _validReport() => {
  'schemaVersion': 1,
  'metadata': <String, Object?>{
    'buildMode': 'profile',
    'deviceId': _deviceId,
    'scenario': 'renderer.frame.1000',
    'assetMode': 'bundled-assets',
    'sampleFrames': 600,
  },
  'metrics': <String, Object?>{
    'totalFrame': <String, Object?>{'p95Micros': 16667, 'p99Micros': 33300},
    'slowFrames': <String, Object?>{'thresholdMicros': 16667, 'count': 6},
    'uiBuild': <String, Object?>{'p95Micros': 8000},
    'raster': <String, Object?>{'p95Micros': 8000},
    'flameUpdate': <String, Object?>{'p95Micros': 2000},
    'renderSubmission': <String, Object?>{'p95Micros': 4000},
  },
};

Map<String, Object?> _exceededReport() {
  final report = _validReport();
  final metrics = report['metrics']! as Map<String, Object?>;
  (metrics['totalFrame']! as Map<String, Object?>)
    ..['p95Micros'] = 20000
    ..['p99Micros'] = 40000;
  (metrics['slowFrames']! as Map<String, Object?>)['count'] = 7;
  for (final entry in const {
    'uiBuild': 8001,
    'raster': 8001,
    'flameUpdate': 2001,
    'renderSubmission': 4001,
  }.entries) {
    (metrics[entry.key]! as Map<String, Object?>)['p95Micros'] = entry.value;
  }
  return report;
}

Map<String, Object?> _reportWith(String field, Object? value) =>
    _validReport()..[field] = value;

Map<String, Object?> _metadataWith(String field, Object? value) {
  final report = _validReport();
  (report['metadata']! as Map<String, Object?>)[field] = value;
  return report;
}

Map<String, Object?> _slowFramesWith(String field, Object? value) =>
    _metricWith('slowFrames', field, value);

Map<String, Object?> _metricWith(String metric, String field, Object? value) {
  final report = _validReport();
  final metrics = report['metrics']! as Map<String, Object?>;
  (metrics[metric]! as Map<String, Object?>)[field] = value;
  return report;
}

Matcher _failsContaining(String text) => throwsA(
  isA<PerformanceFailure>().having(
    (error) => error.message,
    'message',
    contains(text),
  ),
);

const _deviceId = 'pixel-8-pro-reference-01';
