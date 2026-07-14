import 'failure.dart';
import 'frame_budget_policy.dart';
import 'frame_budget_report.dart';

final class FrameBudgetGateResult {
  const FrameBudgetGateResult({
    required this.deviceId,
    required this.sampleFrames,
    required this.metricsChecked,
  });

  final String deviceId;
  final int sampleFrames;
  final int metricsChecked;
}

final class FrameBudgetViolation {
  const FrameBudgetViolation({
    required this.metric,
    required this.actual,
    required this.limit,
    required this.unit,
  });

  final String metric;
  final double actual;
  final double limit;
  final String unit;

  String get message =>
      '$metric: ${_format(actual)} $unit exceeds ${_format(limit)} $unit';
}

final class FrameBudgetGate {
  const FrameBudgetGate();

  FrameBudgetGateResult check(
    FrameBudgetReport report, {
    required String expectedDeviceId,
  }) {
    _requireExpectedDevice(report, expectedDeviceId);
    final violations = violationsFor(report);
    if (violations.isNotEmpty) {
      throw PerformanceFailure(
        'Reference-profile frame budget exceeded on ${report.deviceId} '
        '(${report.sampleFrames} frames):\n'
        '${violations.map((violation) => '- ${violation.message}').join('\n')}',
      );
    }
    return FrameBudgetGateResult(
      deviceId: report.deviceId,
      sampleFrames: report.sampleFrames,
      metricsChecked: _metricBudgets.length,
    );
  }

  List<FrameBudgetViolation> violationsFor(FrameBudgetReport report) {
    final metrics = report.metrics;
    final actual = <String, double>{
      'totalFrame.p95Micros': metrics.totalFrameP95Micros,
      'totalFrame.p99Micros': metrics.totalFrameP99Micros,
      'slowFrames.basisPoints': metrics.slowFramesBasisPoints(
        report.sampleFrames,
      ),
      'uiBuild.p95Micros': metrics.uiBuildP95Micros,
      'raster.p95Micros': metrics.rasterP95Micros,
      'flameUpdate.p95Micros': metrics.flameUpdateP95Micros,
      'renderSubmission.p95Micros': metrics.renderSubmissionP95Micros,
    };
    return [
      for (final budget in _metricBudgets)
        if (actual[budget.metric]! > budget.limit)
          FrameBudgetViolation(
            metric: budget.metric,
            actual: actual[budget.metric]!,
            limit: budget.limit.toDouble(),
            unit: budget.unit,
          ),
    ];
  }
}

void _requireExpectedDevice(FrameBudgetReport report, String expectedDeviceId) {
  if (expectedDeviceId.trim().isEmpty ||
      expectedDeviceId != expectedDeviceId.trim()) {
    throw const PerformanceFailure(
      'Expected reference device ID must be a non-empty trimmed string.',
    );
  }
  if (report.deviceId != expectedDeviceId) {
    throw PerformanceFailure(
      'Reference-profile report deviceId "${report.deviceId}" does not match '
      'the expected pinned device "$expectedDeviceId".',
    );
  }
}

const _metricBudgets = <({String metric, num limit, String unit})>[
  (
    metric: 'totalFrame.p95Micros',
    limit: rendererFrameBudgetMicros,
    unit: 'us',
  ),
  (
    metric: 'totalFrame.p99Micros',
    limit: rendererFrameP99BudgetMicros,
    unit: 'us',
  ),
  (
    metric: 'slowFrames.basisPoints',
    limit: rendererMaxSlowFramesBasisPoints,
    unit: 'bp',
  ),
  (metric: 'uiBuild.p95Micros', limit: rendererUiBuildBudgetMicros, unit: 'us'),
  (metric: 'raster.p95Micros', limit: rendererRasterBudgetMicros, unit: 'us'),
  (
    metric: 'flameUpdate.p95Micros',
    limit: rendererFlameUpdateBudgetMicros,
    unit: 'us',
  ),
  (
    metric: 'renderSubmission.p95Micros',
    limit: rendererRenderSubmissionBudgetMicros,
    unit: 'us',
  ),
];

String _format(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
