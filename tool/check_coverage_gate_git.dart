part of 'check_coverage.dart';

extension _CoverageGateGit on _CoverageGate {
  String _effectiveDiffBase(String requested) {
    final anchor = policy.enforcedSince;
    _requireCommit(anchor, 'coverage rollout anchor');
    _requireCommit(requested, 'coverage diff base');
    if (!_isAncestor(anchor, 'HEAD')) {
      throw CoverageFailure(
        'Coverage rollout anchor $anchor is not an ancestor of HEAD.',
      );
    }
    final mergeBases = _git([
      'merge-base',
      '--all',
      requested,
      'HEAD',
    ]).stdout.split('\n').where((value) => value.isNotEmpty).toList();
    if (mergeBases.length != 1) {
      throw CoverageFailure(
        'Expected exactly one merge base for $requested and HEAD, found '
        '${mergeBases.length}.',
      );
    }
    final mergeBase = mergeBases.single;
    if (_isAncestor(mergeBase, anchor)) return anchor;
    if (_isAncestor(anchor, mergeBase)) return mergeBase;
    throw CoverageFailure(
      'Coverage diff base $mergeBase and rollout anchor $anchor are '
      'incomparable ancestors of HEAD.',
    );
  }

  void _verifyHistoricalRatchet(
    _CoverageBaseline current,
    List<String> scopeNames,
    String ratchetRef,
  ) {
    _requireCommit(ratchetRef, 'coverage ratchet ref');
    final baselinePath = _repositoryPath(options.baselinePath);
    final policyPath = _repositoryPath(options.policyPath);
    final oldBaselineText = _gitShow(ratchetRef, baselinePath);
    final oldPolicyText = _gitShow(ratchetRef, policyPath);
    if (oldBaselineText == null && oldPolicyText == null) {
      if (_isAncestor(ratchetRef, policy.enforcedSince)) return;
      throw CoverageFailure(
        'Trusted ratchet ref $ratchetRef is newer than the rollout boundary '
        'but has no coverage policy or baseline.',
      );
    }
    if (oldBaselineText == null || oldPolicyText == null) {
      throw CoverageFailure(
        'Trusted ratchet ref $ratchetRef must contain both $baselinePath and '
        '$policyPath.',
      );
    }

    final oldPolicy = _CoveragePolicy.parse(oldPolicyText, 'historical policy');
    final epochAdvanced = validateHistoricalCoveragePolicy(
      oldAnchor: oldPolicy.enforcedSince,
      currentAnchor: policy.enforcedSince,
      oldEpoch: oldPolicy.ratchetEpoch,
      currentEpoch: policy.ratchetEpoch,
      oldStructure: oldPolicy.structuralSignature,
      currentStructure: policy.structuralSignature,
      oldDiffMinimum: oldPolicy.diffLineMinimumBasisPoints,
      currentDiffMinimum: policy.diffLineMinimumBasisPoints,
      oldDiffMinimumPercent: oldPolicy.diffLineMinimumPercent,
      currentDiffMinimumPercent: policy.diffLineMinimumPercent,
    );

    final oldBaseline = _CoverageBaseline.parse(
      oldBaselineText,
      oldPolicy,
      'historical baseline',
    );
    if (epochAdvanced) return;
    final failures = <String>[];
    for (final scopeName in scopeNames) {
      final oldScope = oldBaseline.scopes[scopeName];
      final currentScope = current.scopes[scopeName];
      if (oldScope == null || currentScope == null) continue;
      failures.addAll(currentScope.ratchetDifferences(oldScope, scopeName));
    }
    if (failures.isNotEmpty) {
      throw CoverageFailure(failures.join('\n'));
    }
  }

  String _repositoryPath(String path) {
    final absolute = _resolvePath(options.repository, path);
    return _relativeToRepository(options.repository, absolute);
  }

  String? _gitShow(String ref, String path) {
    final check = Process.runSync(
      'git',
      ['-C', options.repository, 'cat-file', '-e', '$ref:$path'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (check.exitCode != 0) return null;
    return _git(['show', '$ref:$path']).stdout;
  }

  bool _isAncestor(String ancestor, String descendant) {
    final result = Process.runSync(
      'git',
      [
        '-C',
        options.repository,
        'merge-base',
        '--is-ancestor',
        ancestor,
        descendant,
      ],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode == 0) return true;
    if (result.exitCode == 1) return false;
    throw CoverageFailure(
      'git merge-base failed: ${(result.stderr as String).trim()}',
    );
  }

  bool _commitExists(String ref) {
    final result = Process.runSync(
      'git',
      ['-C', options.repository, 'rev-parse', '--verify', '$ref^{commit}'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return result.exitCode == 0;
  }

  void _requireCommit(String ref, String description) {
    if (!_commitExists(ref)) {
      throw CoverageFailure('Unknown $description: $ref');
    }
  }

  _GitOutput _git(List<String> arguments) {
    final result = Process.runSync(
      'git',
      ['-C', options.repository, ...arguments],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      throw CoverageFailure(
        'git ${arguments.join(' ')} failed:\n'
        '${(result.stderr as String).trim()}',
      );
    }
    return _GitOutput(
      stdout: result.stdout as String,
      stderr: result.stderr as String,
    );
  }
}
