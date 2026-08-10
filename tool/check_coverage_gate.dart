part of 'check_coverage.dart';

final class _CoverageGate {
  _CoverageGate(this.options)
    : policy = _CoveragePolicy.load(
        _resolvePath(options.repository, options.policyPath),
      );

  final _CliOptions options;
  final _CoveragePolicy policy;

  void check() {
    final baseline = _CoverageBaseline.load(
      _resolvePath(options.repository, options.baselinePath),
      policy,
    );
    final scopeNames = _scopeNames(policy, options.scopes);
    final requestedBase = _requiredRef(options.baseRef, '--base-ref');
    final ratchetRef = _requiredRef(options.ratchetRef, '--ratchet-ref');
    final cumulativeBase = _effectiveDiffBase(requestedBase);
    final incrementalBase = _effectiveDiffBase(ratchetRef);
    _verifyHistoricalRatchet(baseline, scopeNames, ratchetRef);

    final failures = <String>[];
    final summaries = <String>[];
    for (final scopeName in scopeNames) {
      final scope = policy.scopes[scopeName]!;
      final actual = _measureScope(scopeName, scope);
      final expected = baseline.scopes[scopeName]!;
      failures.addAll(actual.baselineDifferences(expected, scopeName));

      final diffs = <String, ({String base, _DiffSnapshot snapshot})>{
        'diff': (
          base: cumulativeBase,
          snapshot: _measureDiff(
            scopeName,
            scope,
            cumulativeBase,
            'diff',
            acknowledgedMissingFiles: expected.missingFiles,
          ),
        ),
      };
      if (incrementalBase != cumulativeBase) {
        diffs['incremental diff'] = (
          base: incrementalBase,
          snapshot: _measureDiff(
            scopeName,
            scope,
            incrementalBase,
            'incremental diff',
            acknowledgedMissingFiles: expected.missingFiles,
          ),
        );
      }
      for (final entry in diffs.entries) {
        failures.addAll(
          entry.value.snapshot.failures(
            policy.diffLineMinimumBasisPoints,
            entry.key,
          ),
        );
      }
      summaries.add(_formatSummary(scopeName, actual, diffs));
    }

    if (failures.isNotEmpty) {
      throw CoverageFailure(failures.join('\n'));
    }
    for (final summary in summaries) {
      stdout.writeln(summary);
    }
  }

  String snapshotJson() {
    final scopes = <String, Object?>{};
    for (final scopeName in _scopeNames(policy, options.scopes)) {
      scopes[scopeName] = _measureScope(
        scopeName,
        policy.scopes[scopeName]!,
      ).toJson();
    }
    return const JsonEncoder.withIndent(
      '  ',
    ).convert({'schema': 1, 'scopes': scopes});
  }
}
