import 'dart:convert';

import 'failure.dart';
import 'frame_budget_policy.dart';

final class FrameBudgetReport {
  const FrameBudgetReport._({
    required this.buildMode,
    required this.deviceId,
    required this.scenario,
    required this.assetMode,
    required this.sampleFrames,
    required this.metrics,
  });

  factory FrameBudgetReport.parse(String contents) {
    final Object? decoded;
    try {
      decoded = jsonDecode(contents);
    } on FormatException catch (error) {
      throw PerformanceFailure(
        'Invalid frame budget report JSON: ${error.message}',
      );
    }
    final root = _object(decoded, 'frame budget report');
    _requireKeys(root, 'frame budget report', const {
      'metadata',
      'metrics',
      'schemaVersion',
    });
    final schemaVersion = _integer(
      root['schemaVersion'],
      'frame budget report.schemaVersion',
    );
    if (schemaVersion != 1) {
      throw const PerformanceFailure(
        'frame budget report.schemaVersion must be 1.',
      );
    }
    final metadata = _parseMetadata(root['metadata']);
    return FrameBudgetReport._(
      buildMode: metadata.buildMode,
      deviceId: metadata.deviceId,
      scenario: metadata.scenario,
      assetMode: metadata.assetMode,
      sampleFrames: metadata.sampleFrames,
      metrics: FrameBudgetMetrics.parse(
        root['metrics'],
        sampleFrames: metadata.sampleFrames,
      ),
    );
  }

  static const schemaVersion = 1;

  final String buildMode;
  final String deviceId;
  final String scenario;
  final String assetMode;
  final int sampleFrames;
  final FrameBudgetMetrics metrics;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'metadata': {
      'buildMode': buildMode,
      'deviceId': deviceId,
      'scenario': scenario,
      'assetMode': assetMode,
      'sampleFrames': sampleFrames,
    },
    'metrics': metrics.toJson(),
  };
}

final class FrameBudgetMetrics {
  const FrameBudgetMetrics._({
    required this.totalFrameP95Micros,
    required this.totalFrameP99Micros,
    required this.slowFrameThresholdMicros,
    required this.slowFrameCount,
    required this.uiBuildP95Micros,
    required this.rasterP95Micros,
    required this.flameUpdateP95Micros,
    required this.renderSubmissionP95Micros,
  });

  factory FrameBudgetMetrics.parse(Object? value, {required int sampleFrames}) {
    final metrics = _object(value, 'frame budget report.metrics');
    _requireKeys(metrics, 'frame budget report.metrics', const {
      'flameUpdate',
      'raster',
      'renderSubmission',
      'slowFrames',
      'totalFrame',
      'uiBuild',
    });
    final totalFrame = _totalFrameMetric(metrics['totalFrame']);
    final slowFrames = _slowFrameMetric(
      metrics['slowFrames'],
      sampleFrames: sampleFrames,
    );
    return FrameBudgetMetrics._(
      totalFrameP95Micros: totalFrame.p95Micros,
      totalFrameP99Micros: totalFrame.p99Micros,
      slowFrameThresholdMicros: slowFrames.thresholdMicros,
      slowFrameCount: slowFrames.count,
      uiBuildP95Micros: _p95Metric(metrics['uiBuild'], 'uiBuild'),
      rasterP95Micros: _p95Metric(metrics['raster'], 'raster'),
      flameUpdateP95Micros: _p95Metric(metrics['flameUpdate'], 'flameUpdate'),
      renderSubmissionP95Micros: _p95Metric(
        metrics['renderSubmission'],
        'renderSubmission',
      ),
    );
  }

  final double totalFrameP95Micros;
  final double totalFrameP99Micros;
  final int slowFrameThresholdMicros;
  final int slowFrameCount;
  final double uiBuildP95Micros;
  final double rasterP95Micros;
  final double flameUpdateP95Micros;
  final double renderSubmissionP95Micros;

  double slowFramesBasisPoints(int sampleFrames) =>
      slowFrameCount * 10000 / sampleFrames;

  Map<String, Object?> toJson() => {
    'totalFrame': {
      'p95Micros': totalFrameP95Micros,
      'p99Micros': totalFrameP99Micros,
    },
    'slowFrames': {
      'thresholdMicros': slowFrameThresholdMicros,
      'count': slowFrameCount,
    },
    'uiBuild': {'p95Micros': uiBuildP95Micros},
    'raster': {'p95Micros': rasterP95Micros},
    'flameUpdate': {'p95Micros': flameUpdateP95Micros},
    'renderSubmission': {'p95Micros': renderSubmissionP95Micros},
  };
}

({
  String buildMode,
  String deviceId,
  String scenario,
  String assetMode,
  int sampleFrames,
})
_parseMetadata(Object? value) {
  final metadata = _object(value, 'frame budget report.metadata');
  _requireKeys(metadata, 'frame budget report.metadata', const {
    'assetMode',
    'buildMode',
    'deviceId',
    'sampleFrames',
    'scenario',
  });
  final buildMode = _exactString(
    metadata,
    'buildMode',
    rendererReferenceBuildMode,
  );
  final deviceId = _nonEmptyString(metadata['deviceId'], 'metadata.deviceId');
  final scenario = _exactString(
    metadata,
    'scenario',
    rendererReferenceScenario,
  );
  final assetMode = _exactString(
    metadata,
    'assetMode',
    rendererReferenceAssetMode,
  );
  final sampleFrames = _integer(
    metadata['sampleFrames'],
    'metadata.sampleFrames',
  );
  if (sampleFrames < rendererReferenceMinimumSampleFrames) {
    throw const PerformanceFailure(
      'metadata.sampleFrames must be at least '
      '$rendererReferenceMinimumSampleFrames.',
    );
  }
  return (
    buildMode: buildMode,
    deviceId: deviceId,
    scenario: scenario,
    assetMode: assetMode,
    sampleFrames: sampleFrames,
  );
}

({double p95Micros, double p99Micros}) _totalFrameMetric(Object? value) {
  const path = 'metrics.totalFrame';
  final metric = _object(value, path);
  _requireKeys(metric, path, const {'p95Micros', 'p99Micros'});
  final p95 = _number(metric['p95Micros'], '$path.p95Micros');
  final p99 = _number(metric['p99Micros'], '$path.p99Micros');
  if (p95 > p99) {
    throw const PerformanceFailure(
      'metrics.totalFrame.p95Micros must not exceed p99Micros.',
    );
  }
  return (p95Micros: p95, p99Micros: p99);
}

({int thresholdMicros, int count}) _slowFrameMetric(
  Object? value, {
  required int sampleFrames,
}) {
  const path = 'metrics.slowFrames';
  final metric = _object(value, path);
  _requireKeys(metric, path, const {'count', 'thresholdMicros'});
  final threshold = _integer(
    metric['thresholdMicros'],
    '$path.thresholdMicros',
  );
  if (threshold != rendererFrameBudgetMicros) {
    throw const PerformanceFailure(
      '$path.thresholdMicros must be $rendererFrameBudgetMicros.',
    );
  }
  final count = _integer(metric['count'], '$path.count');
  if (count < 0 || count > sampleFrames) {
    throw PerformanceFailure(
      'metrics.slowFrames.count must be between 0 and $sampleFrames.',
    );
  }
  return (thresholdMicros: threshold, count: count);
}

double _p95Metric(Object? value, String name) {
  final path = 'metrics.$name';
  final metric = _object(value, path);
  _requireKeys(metric, path, const {'p95Micros'});
  return _number(metric['p95Micros'], '$path.p95Micros');
}

String _exactString(
  Map<String, Object?> values,
  String field,
  String expected,
) {
  final value = _nonEmptyString(values[field], 'metadata.$field');
  if (value != expected) {
    throw PerformanceFailure('metadata.$field must be "$expected".');
  }
  return value;
}

String _nonEmptyString(Object? value, String path) {
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw PerformanceFailure('$path must be a non-empty trimmed string.');
  }
  return value;
}

int _integer(Object? value, String path) {
  if (value is! int) throw PerformanceFailure('$path must be an integer.');
  return value;
}

double _number(Object? value, String path) {
  if (value is! num || !value.isFinite || value < 0) {
    throw PerformanceFailure('$path must be a finite non-negative number.');
  }
  return value.toDouble();
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is! Map<Object?, Object?> ||
      value.keys.any((key) => key is! String)) {
    throw PerformanceFailure('$path must be a JSON object.');
  }
  return {for (final entry in value.entries) entry.key! as String: entry.value};
}

void _requireKeys(
  Map<String, Object?> value,
  String path,
  Set<String> expected,
) {
  final actual = value.keys.toSet();
  final missing = expected.difference(actual).toList()..sort();
  final unknown = actual.difference(expected).toList()..sort();
  if (missing.isEmpty && unknown.isEmpty) return;
  final details = [
    if (missing.isNotEmpty) 'missing: ${missing.join(', ')}',
    if (unknown.isNotEmpty) 'unknown: ${unknown.join(', ')}',
  ];
  throw PerformanceFailure('$path has invalid fields (${details.join('; ')}).');
}
