import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/mutation/baseline.dart';
import '../../tool/mutation/failure.dart';
import '../../tool/mutation/git_repository.dart';
import '../../tool/mutation/policy.dart';
import '../../tool/mutation/ratchet.dart';
import '../../tool/mutation/strict_json.dart';

void main() {
  test('allows rollout and rejects a refreshed survivor regression', () {
    final fixture = Directory.systemTemp.createTempSync('aonw-mutation-gate-');
    addTearDown(() => fixture.deleteSync(recursive: true));
    _git(fixture, ['init', '--quiet']);
    _git(fixture, ['config', 'user.name', 'Mutation Test']);
    _git(fixture, ['config', 'user.email', 'mutation@example.invalid']);
    File('${fixture.path}/marker.txt').writeAsStringSync('anchor\n');
    _commitAll(fixture, 'anchor');
    final anchor = _git(fixture, ['rev-parse', 'HEAD']).trim();

    final policyFile = File('${fixture.path}/tool/mutation_policy.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(_policyJson(anchor));
    final policy = MutationPolicy.load(policyFile.path);
    final baselineFile = File('${fixture.path}/tool/mutation_baseline.json')
      ..writeAsStringSync(_baselineJson());
    final current = MutationBaseline.load(baselineFile.path, policy);
    final repository = MutationGitRepository(fixture.path);
    final initial = MutationRatchet(
      repository: repository,
      policy: policy,
      policyPath: policyFile.path,
      baselinePath: baselineFile.path,
    );

    expect(initial.compare(current, anchor), isEmpty);

    _commitAll(fixture, 'establish mutation gate');
    final rollout = _git(fixture, ['rev-parse', 'HEAD']).trim();
    File('${fixture.path}/marker.txt').writeAsStringSync('after rollout\n');
    _commitAll(fixture, 'continue development');

    final regression = MutationBaseline.parse(
      _baselineJson(withSurvivor: true),
      policy,
      'regression',
    );
    expect(
      initial.compare(regression, rollout),
      contains(contains('cannot introduce mutation survivors')),
    );
    expect(initial.compare(current, rollout), isEmpty);
  });

  test('rejects schema-1 policy drift after rollout', () {
    final fixture = Directory.systemTemp.createTempSync(
      'aonw-mutation-policy-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    _git(fixture, ['init', '--quiet']);
    _git(fixture, ['config', 'user.name', 'Mutation Test']);
    _git(fixture, ['config', 'user.email', 'mutation@example.invalid']);
    File('${fixture.path}/marker.txt').writeAsStringSync('anchor\n');
    _commitAll(fixture, 'anchor');
    final anchor = _git(fixture, ['rev-parse', 'HEAD']).trim();
    final policyFile = File('${fixture.path}/tool/mutation_policy.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(_policyJson(anchor));
    final baselineFile = File('${fixture.path}/tool/mutation_baseline.json')
      ..writeAsStringSync(_baselineJson());
    _commitAll(fixture, 'establish mutation gate');
    final rollout = _git(fixture, ['rev-parse', 'HEAD']).trim();

    policyFile.writeAsStringSync(_policyJson(anchor, timeout: 91));
    final changedPolicy = MutationPolicy.load(policyFile.path);
    final ratchet = MutationRatchet(
      repository: MutationGitRepository(fixture.path),
      policy: changedPolicy,
      policyPath: policyFile.path,
      baselinePath: baselineFile.path,
    );

    expect(
      () => ratchet.compare(
        MutationBaseline.load(baselineFile.path, changedPolicy),
        rollout,
      ),
      throwsA(
        isA<MutationFailure>().having(
          (error) => error.message,
          'message',
          contains('immutable'),
        ),
      ),
    );
  });

  test('preserves survivor improvements from a divergent trusted tip', () {
    final fixture = Directory.systemTemp.createTempSync(
      'aonw-mutation-divergent-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    _git(fixture, ['init', '-b', 'dev']);
    _git(fixture, ['config', 'user.name', 'Mutation Test']);
    _git(fixture, ['config', 'user.email', 'mutation@example.invalid']);
    File('${fixture.path}/marker.txt').writeAsStringSync('anchor\n');
    _commitAll(fixture, 'anchor');
    final anchor = _git(fixture, ['rev-parse', 'HEAD']).trim();
    final policyFile = File('${fixture.path}/tool/mutation_policy.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(_policyJson(anchor));
    final baselineFile = File('${fixture.path}/tool/mutation_baseline.json')
      ..writeAsStringSync(_baselineJson(withSurvivor: true));
    _commitAll(fixture, 'establish mutation gate');
    final rollout = _git(fixture, ['rev-parse', 'HEAD']).trim();

    _git(fixture, ['switch', '-c', 'trusted']);
    baselineFile.writeAsStringSync(_baselineJson());
    _commitAll(fixture, 'kill trusted survivor');
    final trusted = _git(fixture, ['rev-parse', 'HEAD']).trim();

    _git(fixture, ['switch', '-c', 'feature', rollout]);
    File('${fixture.path}/feature.txt').writeAsStringSync('feature\n');
    _commitAll(fixture, 'advance feature branch');
    final policy = MutationPolicy.load(policyFile.path);
    final current = MutationBaseline.parse(
      _baselineJson(withSurvivor: true),
      policy,
      'feature mutation baseline',
    );

    expect(
      MutationRatchet(
        repository: MutationGitRepository(fixture.path),
        policy: policy,
        policyPath: policyFile.path,
        baselinePath: baselineFile.path,
      ).compare(current, trusted),
      contains(contains('cannot introduce mutation survivors')),
    );
  });
}

String _policyJson(String anchor, {int timeout = 90}) => canonicalJson({
  'schema': 1,
  'enforcedSince': anchor,
  'perMutantTimeoutSeconds': timeout,
  'operators': supportedMutationOperators,
  'scopes': {
    'root_validator': {
      'architectureScope': 'root_lib',
      'packageRoot': '.',
      'runner': 'flutter',
      'targetFiles': ['lib/validator.dart'],
      'testFiles': ['test/validator_test.dart'],
    },
  },
});

String _baselineJson({bool withSurvivor = false}) => canonicalJson({
  'schema': 1,
  'scopes': {
    'root_validator': {
      'targets': {'lib/validator.dart': withSurvivor ? 1 : 0},
      'operatorTotals': {
        for (final operator in supportedMutationOperators)
          operator: withSurvivor && operator == 'equality_negation' ? 1 : 0,
      },
      'survivors': withSurvivor
          ? {
              'survivor-1': {
                'path': 'lib/validator.dart',
                'operator': 'equality_negation',
                'declaration': 'function:validate',
                'original': '==',
                'replacement': '!=',
              },
            }
          : <String, Object?>{},
    },
  },
});

void _commitAll(Directory repository, String message) {
  _git(repository, ['add', '.']);
  _git(repository, ['commit', '--quiet', '-m', message]);
}

String _git(Directory repository, List<String> arguments) {
  final result = Process.runSync(
    'git',
    ['-C', repository.path, ...arguments],
    stdoutEncoding: systemEncoding,
    stderrEncoding: systemEncoding,
  );
  if (result.exitCode != 0) {
    throw StateError(
      'git ${arguments.join(' ')} failed:\n${result.stdout}\n${result.stderr}',
    );
  }
  return result.stdout as String;
}
