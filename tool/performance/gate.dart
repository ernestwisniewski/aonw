import '../release/canonical_json.dart';
import 'document.dart';
import 'failure.dart';

final class PerformanceGateResult {
  const PerformanceGateResult({required this.cases});

  final int cases;
}

final class PerformanceGate {
  const PerformanceGate();

  PerformanceGateResult check({
    required PerformanceReportDocument report,
    required PerformanceBaselineDocument baseline,
    required PerformancePolicyDocument policy,
  }) {
    final actualCases = report.stable.keys.toSet();
    final baselineCases = baseline.stable.keys.toSet();
    final requiredCases = policy.requiredCases.toSet();
    _requireExactCases(
      actual: actualCases,
      expected: requiredCases,
      name: 'report',
    );
    _requireExactCases(
      actual: baselineCases,
      expected: requiredCases,
      name: 'baseline',
    );
    final differences = <String>[];
    _collectDifferences(
      baseline.stable,
      report.stable,
      path: 'stable',
      output: differences,
    );
    if (differences.isNotEmpty) {
      throw PerformanceFailure(
        'Stable performance baseline drifted:\n${differences.join('\n')}',
      );
    }
    return PerformanceGateResult(cases: requiredCases.length);
  }

  void _requireExactCases({
    required Set<String> actual,
    required Set<String> expected,
    required String name,
  }) {
    final missing = expected.difference(actual).toList()..sort();
    final unknown = actual.difference(expected).toList()..sort();
    if (missing.isEmpty && unknown.isEmpty) return;
    final details = <String>[
      if (missing.isNotEmpty) 'missing: ${missing.join(', ')}',
      if (unknown.isNotEmpty) 'unknown: ${unknown.join(', ')}',
    ];
    throw PerformanceFailure(
      'Performance $name cases do not match policy (${details.join('; ')}).',
    );
  }
}

void _collectDifferences(
  Object? expected,
  Object? actual, {
  required String path,
  required List<String> output,
}) {
  if (expected is Map<String, Object?> && actual is Map<String, Object?>) {
    final keys = {...expected.keys, ...actual.keys}.toList()..sort();
    for (final key in keys) {
      if (!expected.containsKey(key)) {
        output.add('$path.$key: unexpected value ${_render(actual[key])}');
      } else if (!actual.containsKey(key)) {
        output.add('$path.$key: missing; expected ${_render(expected[key])}');
      } else {
        _collectDifferences(
          expected[key],
          actual[key],
          path: '$path.$key',
          output: output,
        );
      }
    }
    return;
  }
  if (expected is List<Object?> && actual is List<Object?>) {
    if (encodeCanonicalJson(expected) != encodeCanonicalJson(actual)) {
      output.add(
        '$path: expected ${_render(expected)}, found ${_render(actual)}',
      );
    }
    return;
  }
  if (expected != actual || expected.runtimeType != actual.runtimeType) {
    output.add(
      '$path: expected ${_render(expected)}, found ${_render(actual)}',
    );
  }
}

String _render(Object? value) => encodeCanonicalJson(value);
