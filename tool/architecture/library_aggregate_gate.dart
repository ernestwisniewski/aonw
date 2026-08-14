import 'failure.dart';
import 'git_repository.dart';
import 'library_aggregate_baseline.dart';
import 'library_aggregate_metrics.dart';
import 'library_aggregate_policy.dart';
import 'policy.dart';
import 'source_census.dart';

final class LibraryAggregateGate {
  LibraryAggregateGate({
    required this.repository,
    required this.architecturePolicyPath,
    required this.aggregatePolicyPath,
    required this.baselinePath,
  }) : architecturePolicy = ArchitecturePolicy.load(architecturePolicyPath) {
    aggregatePolicy = LibraryAggregatePolicy.load(
      aggregatePolicyPath,
      architecturePolicy,
    );
    measurer = LibraryAggregateMeasurer(
      repository: repository,
      policy: architecturePolicy,
      census: SourceCensus(repository: repository, policy: architecturePolicy),
    );
  }

  final GitRepository repository;
  final String architecturePolicyPath;
  final String aggregatePolicyPath;
  final String baselinePath;
  final ArchitecturePolicy architecturePolicy;
  late final LibraryAggregatePolicy aggregatePolicy;
  late final LibraryAggregateMeasurer measurer;

  LibraryAggregateBaseline snapshot() => LibraryAggregateBaseline.fromMetrics(
    architecturePolicy,
    aggregatePolicy,
    measurer.measure(),
  );

  LibraryAggregateCheckResult check(String ratchetRef) {
    final expected = LibraryAggregateBaseline.load(
      baselinePath,
      architecturePolicy,
      aggregatePolicy,
    );
    final actual = snapshot();
    final failures = actual.exactDifferences(expected)
      ..addAll(_historicalRatchetFailures(expected, ratchetRef));
    if (failures.isNotEmpty) {
      throw ArchitectureFailure(failures.join('\n'));
    }
    return LibraryAggregateCheckResult(libraryDebt: actual.debtCount);
  }

  List<String> _historicalRatchetFailures(
    LibraryAggregateBaseline current,
    String ratchetRef,
  ) {
    repository.requireCommit(ratchetRef, 'architecture aggregate ratchet ref');
    final policyPath = repository.repositoryRelativePath(aggregatePolicyPath);
    final architecturePolicyRepositoryPath = repository.repositoryRelativePath(
      architecturePolicyPath,
    );
    final aggregateBaselinePath = repository.repositoryRelativePath(
      baselinePath,
    );
    final historicalPolicyText = repository.show(ratchetRef, policyPath);
    final historicalArchitecturePolicyText = repository.show(
      ratchetRef,
      architecturePolicyRepositoryPath,
    );
    final historicalBaselineText = repository.show(
      ratchetRef,
      aggregateBaselinePath,
    );
    if (historicalPolicyText == null &&
        historicalBaselineText == null &&
        historicalArchitecturePolicyText == null) {
      return const [];
    }
    if (historicalPolicyText == null ||
        historicalBaselineText == null ||
        historicalArchitecturePolicyText == null) {
      throw ArchitectureFailure(
        'Trusted aggregate ratchet ref must contain $policyPath, '
        '$aggregateBaselinePath, and $architecturePolicyRepositoryPath.',
      );
    }
    final historicalArchitecturePolicy = ArchitecturePolicy.parse(
      historicalArchitecturePolicyText,
      'historical architecture policy',
    );
    if (!architecturePolicy.isMonotonicExtensionOf(
      historicalArchitecturePolicy,
    )) {
      throw const ArchitectureFailure(
        'Architecture policy is immutable for schema 2; only new scopes are allowed.',
      );
    }
    final historicalPolicy = LibraryAggregatePolicy.parse(
      historicalPolicyText,
      historicalArchitecturePolicy,
      'historical architecture aggregate policy',
    );
    if (historicalPolicy.canonicalRepresentation !=
        aggregatePolicy.canonicalRepresentation) {
      throw const ArchitectureFailure(
        'Architecture aggregate policy is immutable after rollout.',
      );
    }
    final historicalBaseline = LibraryAggregateBaseline.parse(
      historicalBaselineText,
      historicalArchitecturePolicy,
      historicalPolicy,
      'historical architecture aggregate baseline',
    );
    return current.ratchetDifferencesAllowingNewScopes(historicalBaseline);
  }
}

final class LibraryAggregateCheckResult {
  const LibraryAggregateCheckResult({required this.libraryDebt});

  final int libraryDebt;
}
