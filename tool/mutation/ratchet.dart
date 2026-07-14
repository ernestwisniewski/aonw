import 'baseline.dart';
import 'failure.dart';
import 'git_repository.dart';
import 'policy.dart';

final class MutationRatchet {
  const MutationRatchet({
    required this.repository,
    required this.policy,
    required this.policyPath,
    required this.baselinePath,
  });

  final MutationGitRepository repository;
  final MutationPolicy policy;
  final String policyPath;
  final String baselinePath;

  List<String> compare(MutationBaseline current, String ratchetRef) {
    final anchor = repository.resolveCommit(
      policy.enforcedSince,
      'mutation rollout anchor',
    );
    final trusted = repository.resolveCommit(
      ratchetRef,
      'mutation ratchet ref',
    );
    final head = repository.resolveCommit('HEAD', 'mutation HEAD');
    final mergeBases = repository.mergeBases(trusted, head);
    if (mergeBases.length != 1) {
      throw MutationFailure(
        'Mutation ratchet ref $ratchetRef and HEAD must have exactly one '
        'merge base; found ${mergeBases.length}.',
      );
    }
    final comparisonRef = mergeBases.single;
    if (!repository.isAncestor(anchor, head)) {
      throw MutationFailure(
        'Mutation rollout anchor ${policy.enforcedSince} is not an ancestor '
        'of HEAD.',
      );
    }
    final comparisonBeforeRollout = repository.isAncestor(
      comparisonRef,
      anchor,
    );
    final comparisonAfterRollout = repository.isAncestor(anchor, comparisonRef);
    if (!comparisonBeforeRollout && !comparisonAfterRollout) {
      throw MutationFailure(
        'Mutation merge base $comparisonRef is not comparable with rollout '
        'anchor ${policy.enforcedSince}.',
      );
    }

    final policyRepositoryPath = repository.repositoryRelativePath(policyPath);
    final baselineRepositoryPath = repository.repositoryRelativePath(
      baselinePath,
    );
    final historicalPolicyText = repository.show(trusted, policyRepositoryPath);
    final historicalBaselineText = repository.show(
      trusted,
      baselineRepositoryPath,
    );
    if (historicalPolicyText == null && historicalBaselineText == null) {
      if (comparisonBeforeRollout) return const [];
      throw MutationFailure(
        'Trusted mutation ratchet ref $ratchetRef has no mutation policy or '
        'baseline after the rollout boundary.',
      );
    }
    if (historicalPolicyText == null || historicalBaselineText == null) {
      throw MutationFailure(
        'Trusted mutation ratchet ref must contain both '
        '$policyRepositoryPath and $baselineRepositoryPath.',
      );
    }
    final historicalPolicy = MutationPolicy.parse(
      historicalPolicyText,
      'historical mutation policy',
    );
    if (historicalPolicy.canonicalRepresentation !=
        policy.canonicalRepresentation) {
      throw const MutationFailure('Mutation policy is immutable for schema 1.');
    }
    final historicalBaseline = MutationBaseline.parse(
      historicalBaselineText,
      historicalPolicy,
      'historical mutation baseline',
    );
    return current.ratchetDifferences(historicalBaseline);
  }
}
