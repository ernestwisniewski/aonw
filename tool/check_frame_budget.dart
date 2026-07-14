import 'dart:io';

import 'performance/failure.dart';
import 'performance/frame_budget_gate.dart';
import 'performance/frame_budget_report.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    final report = FrameBudgetReport.parse(
      await File(options.reportPath).readAsString(),
    );
    final result = const FrameBudgetGate().check(
      report,
      expectedDeviceId: options.deviceId,
    );
    stdout.writeln(
      'Reference-profile frame budget passes: '
      '${result.metricsChecked} metrics across ${result.sampleFrames} frames '
      'on ${result.deviceId}.',
    );
  } on PerformanceFailure catch (error) {
    stderr.writeln('Frame budget gate failed:\n${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Frame budget gate failed:\n$error');
    exitCode = 1;
  }
}

final class _Options {
  const _Options({required this.reportPath, required this.deviceId});

  factory _Options.parse(List<String> arguments) {
    if (arguments.length != 4 ||
        arguments[0] != '--report' ||
        arguments[2] != '--device-id') {
      throw const PerformanceFailure(_usage);
    }
    final reportPath = arguments[1];
    final deviceId = arguments[3];
    if (reportPath.isEmpty) {
      throw const PerformanceFailure('--report is required.');
    }
    if (deviceId.isEmpty) {
      throw const PerformanceFailure('--device-id is required.');
    }
    return _Options(reportPath: reportPath, deviceId: deviceId);
  }

  final String reportPath;
  final String deviceId;
}

const _usage =
    'Usage: dart run tool/check_frame_budget.dart '
    '--report PATH --device-id ID';
