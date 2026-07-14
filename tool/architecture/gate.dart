import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'baseline.dart';
import 'dart_metrics.dart';
import 'failure.dart';
import 'git_repository.dart';
import 'legacy_v1.dart';
import 'policy.dart';
import 'source_census.dart';
import 'strict_json.dart';

final class ArchitectureGate {
  ArchitectureGate({
    required this.repository,
    required this.policyPath,
    required this.baselinePath,
  }) : policy = ArchitecturePolicy.load(policyPath) {
    census = SourceCensus(repository: repository, policy: policy);
    measurer = ArchitectureMeasurer(
      repository: repository,
      policy: policy,
      census: census,
    );
  }

  final GitRepository repository;
  final String policyPath;
  final String baselinePath;
  final ArchitecturePolicy policy;
  late final SourceCensus census;
  late final ArchitectureMeasurer measurer;

  ArchitectureBaseline snapshot() =>
      measurer.measure(legacyFileTargets: _currentLegacyFileTargets());

  ArchitectureCheckResult check(String ratchetRef) {
    final legacyFileTargets = _currentLegacyFileTargets();
    final expected = ArchitectureBaseline.load(
      baselinePath,
      policy,
      legacyFileTargets: legacyFileTargets,
    );
    final actual = measurer.measure(legacyFileTargets: legacyFileTargets);
    final failures = actual.exactDifferences(expected)
      ..addAll(_historicalRatchetFailures(expected, ratchetRef));
    if (failures.isNotEmpty) {
      throw ArchitectureFailure(failures.join('\n'));
    }
    return ArchitectureCheckResult(
      fileDebt: actual.fileDebtCount,
      declarationDebt: actual.declarationDebtCount,
      callableLineDebt: actual.callableLineDebtCount,
      nestingDebt: actual.nestingDebtCount,
      cyclomaticDebt: actual.cyclomaticDebtCount,
      cognitiveDebt: actual.cognitiveDebtCount,
    );
  }

  Map<String, int> _currentLegacyFileTargets() => policy.migration
      .legacyFileTargetsAfter(repository.renamesFrom(policy.enforcedSince));

  List<String> _historicalRatchetFailures(
    ArchitectureBaseline current,
    String ratchetRef,
  ) {
    repository
      ..requireCommit(policy.enforcedSince, 'architecture rollout anchor')
      ..requireCommit(ratchetRef, 'architecture ratchet ref');
    final mergeBases = repository.mergeBases(ratchetRef, 'HEAD');
    if (mergeBases.length != 1) {
      throw ArchitectureFailure(
        'Architecture ratchet ref $ratchetRef and HEAD must have exactly one '
        'merge base; found ${mergeBases.length}.',
      );
    }
    final comparisonRef = mergeBases.single;
    if (!repository.isAncestor(policy.enforcedSince, 'HEAD')) {
      throw ArchitectureFailure(
        'Architecture rollout anchor ${policy.enforcedSince} is not an '
        'ancestor of HEAD.',
      );
    }
    final comparisonBeforeRollout = repository.isAncestor(
      comparisonRef,
      policy.enforcedSince,
    );
    final comparisonAfterRollout = repository.isAncestor(
      policy.enforcedSince,
      comparisonRef,
    );
    if (!comparisonBeforeRollout && !comparisonAfterRollout) {
      throw ArchitectureFailure(
        'Architecture merge base $comparisonRef is not comparable with '
        'rollout anchor ${policy.enforcedSince}.',
      );
    }
    final policyRepositoryPath = repository.repositoryRelativePath(policyPath);
    final baselineRepositoryPath = repository.repositoryRelativePath(
      baselinePath,
    );
    final historicalPolicyText = repository.show(
      ratchetRef,
      policyRepositoryPath,
    );
    final historicalBaselineText = repository.show(
      ratchetRef,
      baselineRepositoryPath,
    );
    if (historicalPolicyText == null && historicalBaselineText == null) {
      if (comparisonBeforeRollout && comparisonRef != policy.enforcedSince) {
        return [];
      }
      throw ArchitectureFailure(
        'Trusted architecture ratchet ref $ratchetRef has no architecture '
        'policy or baseline after the rollout boundary.',
      );
    }
    if (historicalPolicyText == null || historicalBaselineText == null) {
      throw ArchitectureFailure(
        'Trusted ratchet ref must contain both $policyRepositoryPath and '
        '$baselineRepositoryPath.',
      );
    }
    final historicalRoot = decodeObject(
      historicalPolicyText,
      'historical architecture policy',
    );
    final historicalSchema = readInt(
      historicalRoot,
      'schema',
      'historical architecture policy',
    );
    if (historicalSchema == policy.migration.fromSchema) {
      if (repository.resolveCommit(ratchetRef) != policy.enforcedSince) {
        throw const ArchitectureFailure(
          'Schema-1 migration requires the exact reviewed rollout anchor.',
        );
      }
      _verifyMigrationDigest(
        historicalPolicyText,
        policy.migration.policySha256,
        'policy',
      );
      _verifyMigrationDigest(
        historicalBaselineText,
        policy.migration.baselineSha256,
        'baseline',
      );
      return legacySchemaOneRatchetFailures(
        repository: repository,
        currentPolicy: policy,
        currentCensus: census,
        policyContents: historicalPolicyText,
        baselineContents: historicalBaselineText,
      );
    }
    if (historicalSchema != ArchitecturePolicy.schema) {
      throw ArchitectureFailure(
        'Trusted architecture policy has unsupported schema '
        '$historicalSchema.',
      );
    }
    final historicalPolicy = ArchitecturePolicy.parse(
      historicalPolicyText,
      'historical architecture policy',
    );
    if (historicalPolicy.canonicalRepresentation !=
        policy.canonicalRepresentation) {
      throw const ArchitectureFailure(
        'Architecture policy is immutable for schema 2.',
      );
    }
    final historicalBaseline = ArchitectureBaseline.parse(
      historicalBaselineText,
      historicalPolicy,
      'historical architecture baseline',
    );
    return current.ratchetDifferences(historicalBaseline);
  }
}

final class ArchitectureCheckResult {
  const ArchitectureCheckResult({
    required this.fileDebt,
    required this.declarationDebt,
    required this.callableLineDebt,
    required this.nestingDebt,
    required this.cyclomaticDebt,
    required this.cognitiveDebt,
  });

  final int fileDebt;
  final int declarationDebt;
  final int callableLineDebt;
  final int nestingDebt;
  final int cyclomaticDebt;
  final int cognitiveDebt;
}

void _verifyMigrationDigest(
  String contents,
  String expected,
  String description,
) {
  final actual = sha256.convert(utf8.encode(contents)).toString();
  if (actual != expected) {
    throw ArchitectureFailure(
      'Trusted schema-1 architecture $description does not match the '
      'reviewed migration digest.',
    );
  }
}
