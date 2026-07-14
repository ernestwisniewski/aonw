import '../architecture/failure.dart' as architecture;
import '../architecture/git_repository.dart' as architecture;
import '../architecture/policy.dart' as architecture;
import '../architecture/source_census.dart' as architecture;
import 'failure.dart';
import 'git_repository.dart';
import 'policy.dart';

final class MutationTargetValidator {
  const MutationTargetValidator({
    required this.repository,
    required this.architecturePolicyPath,
  });

  final MutationGitRepository repository;
  final String architecturePolicyPath;

  void validate(MutationPolicy policy) {
    try {
      final architecturePolicyRepositoryPath = repository
          .repositoryRelativePath(architecturePolicyPath);
      repository.requireRegularFile(
        architecturePolicyRepositoryPath,
        'architecture policy',
      );
      for (final entry in policy.scopes.entries) {
        for (final path in entry.value.targetFiles) {
          repository.requireRegularFile(path, '${entry.key} mutation target');
        }
        for (final path in entry.value.testFiles) {
          repository.requireRegularFile(path, '${entry.key} mutation test');
        }
      }
      final architectureRepository = architecture.GitRepository(
        repository.repository,
      );
      final architecturePolicy = architecture.ArchitecturePolicy.load(
        architecturePolicyPath,
      );
      final census = architecture.SourceCensus(
        repository: architectureRepository,
        policy: architecturePolicy,
      )..validateRepositoryCoverage();
      final handwrittenByScope = <String, Set<String>>{};

      for (final entry in policy.scopes.entries) {
        final scope = entry.value;
        final handwritten = handwrittenByScope.putIfAbsent(
          scope.architectureScope,
          () => census.handwrittenFiles(scope.architectureScope).toSet(),
        );
        final invalidTargets = scope.targetFiles
            .where((path) => !handwritten.contains(path))
            .toList();
        if (invalidTargets.isNotEmpty) {
          throw MutationFailure(
            '${entry.key} mutation targets must be handwritten files in '
            '${scope.architectureScope}: $invalidTargets',
          );
        }
      }
    } on architecture.ArchitectureFailure catch (error) {
      throw MutationFailure(
        'Mutation target validation failed against the architecture census:\n'
        '${error.message}',
      );
    }
  }
}
