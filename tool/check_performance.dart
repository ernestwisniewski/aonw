import 'dart:io';

import 'performance/document.dart';
import 'performance/failure.dart';
import 'performance/gate.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    final report = PerformanceReportDocument.parseCanonical(
      await File(options.reportPath).readAsString(),
    );
    switch (options.command) {
      case _Command.snapshot:
        stdout.writeln(report.baseline.canonicalJson);
      case _Command.check:
        final baseline = PerformanceBaselineDocument.parseCanonical(
          await File(options.baselinePath!).readAsString(),
        );
        final policy = PerformancePolicyDocument.parseCanonical(
          await File(options.policyPath!).readAsString(),
        );
        final result = const PerformanceGate().check(
          report: report,
          baseline: baseline,
          policy: policy,
        );
        stdout.writeln(
          'Performance structural gate passes: ${result.cases} cases.',
        );
    }
  } on PerformanceFailure catch (error) {
    stderr.writeln('Performance gate failed:\n${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Performance gate failed:\n$error');
    exitCode = 1;
  }
}

enum _Command { snapshot, check }

final class _Options {
  const _Options({
    required this.command,
    required this.reportPath,
    required this.baselinePath,
    required this.policyPath,
  });

  factory _Options.parse(List<String> arguments) {
    if (arguments.isEmpty) throw const PerformanceFailure(_usage);
    final command = _parseCommand(arguments.first);
    final paths = _PathOptions.parse(arguments.sublist(1))
      ..validateFor(command);
    return _Options(
      command: command,
      reportPath: paths.report!,
      baselinePath: paths.baseline,
      policyPath: paths.policy,
    );
  }

  final _Command command;
  final String reportPath;
  final String? baselinePath;
  final String? policyPath;
}

_Command _parseCommand(String value) => switch (value) {
  'snapshot' => _Command.snapshot,
  'check' => _Command.check,
  _ => throw PerformanceFailure('Unknown command "$value".\n$_usage'),
};

final class _PathOptions {
  const _PathOptions(this.values);

  factory _PathOptions.parse(List<String> arguments) {
    final values = <String, String>{};
    for (var index = 0; index < arguments.length;) {
      final option = _parsePathOption(arguments, index);
      if (!const {'--report', '--baseline', '--policy'}.contains(option.name)) {
        throw PerformanceFailure('Unknown argument "${option.name}".');
      }
      if (values.containsKey(option.name)) {
        throw PerformanceFailure('Duplicate argument "${option.name}".');
      }
      values[option.name] = option.value;
      index += option.consumed;
    }
    return _PathOptions(Map.unmodifiable(values));
  }

  final Map<String, String> values;

  String? get report => values['--report'];
  String? get baseline => values['--baseline'];
  String? get policy => values['--policy'];

  void validateFor(_Command command) {
    if (report == null) {
      throw const PerformanceFailure('--report is required.');
    }
    if (command == _Command.snapshot && (baseline != null || policy != null)) {
      throw const PerformanceFailure('snapshot accepts --report only.');
    }
    if (command == _Command.check && (baseline == null || policy == null)) {
      throw const PerformanceFailure('check requires --baseline and --policy.');
    }
  }
}

_ParsedPathOption _parsePathOption(List<String> arguments, int index) {
  final argument = arguments[index];
  final separator = argument.indexOf('=');
  if (separator >= 0) {
    return _parsedPathOption(
      name: argument.substring(0, separator),
      value: argument.substring(separator + 1),
      consumed: 1,
    );
  }
  if (index + 1 >= arguments.length) {
    throw PerformanceFailure('Missing value for $argument.');
  }
  return _parsedPathOption(
    name: argument,
    value: arguments[index + 1],
    consumed: 2,
  );
}

_ParsedPathOption _parsedPathOption({
  required String name,
  required String value,
  required int consumed,
}) {
  if (value.isEmpty) throw PerformanceFailure('Missing value for $name.');
  return _ParsedPathOption(name: name, value: value, consumed: consumed);
}

final class _ParsedPathOption {
  const _ParsedPathOption({
    required this.name,
    required this.value,
    required this.consumed,
  });

  final String name;
  final String value;
  final int consumed;
}

const _usage =
    'Usage: dart run tool/check_performance.dart '
    '<snapshot|check> --report PATH [--baseline PATH --policy PATH]';
