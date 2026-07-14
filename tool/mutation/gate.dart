import 'baseline.dart';
import 'executor.dart';
import 'failure.dart';
import 'git_repository.dart';
import 'policy.dart';
import 'ratchet.dart';
import 'target_validator.dart';
import 'workspace.dart';

final class MutationGate {
  MutationGate({
    required this.repository,
    required this.policyPath,
    required this.baselinePath,
    required this.architecturePolicyPath,
    this.executor = const MutationExecutor(),
  }) : policy = MutationPolicy.load(policyPath);

  final MutationGitRepository repository;
  final String policyPath;
  final String baselinePath;
  final String architecturePolicyPath;
  final MutationExecutor executor;
  final MutationPolicy policy;

  Future<MutationBaseline> snapshot() async {
    MutationTargetValidator(
      repository: repository,
      architecturePolicyPath: architecturePolicyPath,
    ).validate(policy);
    final workspace = MutationWorkspace.create(
      repository,
      policy.scopes.values.map((scope) => scope.packageRoot),
    );
    try {
      return await executor.execute(policy: policy, workspace: workspace);
    } finally {
      workspace.dispose();
    }
  }

  Future<MutationCheckResult> check(String ratchetRef) async {
    final expected = MutationBaseline.load(baselinePath, policy);
    final actual = await snapshot();
    final failures = actual.exactDifferences(expected)
      ..addAll(
        MutationRatchet(
          repository: repository,
          policy: policy,
          policyPath: policyPath,
          baselinePath: baselinePath,
        ).compare(actual, ratchetRef),
      );
    if (failures.isNotEmpty) {
      throw MutationFailure(failures.join('\n'));
    }
    return MutationCheckResult(
      mutants: actual.mutantCount,
      survivors: actual.survivorCount,
    );
  }
}

final class MutationCheckResult {
  const MutationCheckResult({required this.mutants, required this.survivors});

  final int mutants;
  final int survivors;
}
