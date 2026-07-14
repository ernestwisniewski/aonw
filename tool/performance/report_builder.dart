import 'document.dart';
import 'failure.dart';
import 'measurement.dart';

PerformanceReportDocument buildPerformanceReport(
  Iterable<PerformanceCaseResult> results,
) {
  final stable = <String, Object?>{};
  final observations = <String, Object?>{};
  for (final result in results) {
    if (stable.containsKey(result.name)) {
      throw PerformanceFailure(
        'Performance case name is duplicated: ${result.name}.',
      );
    }
    stable[result.name] = result.stable;
    observations[result.name] = result.observations;
  }
  return PerformanceReportDocument(
    stable: Map.unmodifiable(stable),
    observations: Map.unmodifiable(observations),
  );
}
