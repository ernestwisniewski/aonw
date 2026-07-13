import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture/strict_json.dart';

void main() {
  test('CLI snapshots, checks rollout, and rejects refreshed regression', () {
    final fixture = Directory.systemTemp.createTempSync(
      'aonw-architecture-e2e-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    _git(fixture, ['init', '-b', 'dev']);
    _git(fixture, ['config', 'user.email', 'architecture@example.test']);
    _git(fixture, ['config', 'user.name', 'Architecture Fixture']);
    Directory('${fixture.path}/lib').createSync(recursive: true);
    File('${fixture.path}/lib/oversized.dart').writeAsStringSync(
      '''
class Oversized {
  void first() {}
  void second() {}
}
'''
          .trimLeft(),
    );
    _git(fixture, ['add', '.']);
    _git(fixture, ['commit', '-m', 'fixture anchor']);
    final anchor = _git(fixture, ['rev-parse', 'HEAD']).trim();

    Directory('${fixture.path}/tool').createSync(recursive: true);
    File(
      '${fixture.path}/tool/architecture_policy.json',
    ).writeAsStringSync(_policyJson(anchor));
    final snapshot = _cli(fixture, ['snapshot']);
    expect(snapshot.exitCode, 0, reason: snapshot.stderr as String);
    File(
      '${fixture.path}/tool/architecture_baseline.json',
    ).writeAsStringSync(snapshot.stdout as String);
    _git(fixture, ['add', '.']);
    _git(fixture, ['commit', '-m', 'roll out architecture budgets']);
    final rollout = _git(fixture, ['rev-parse', 'HEAD']).trim();

    final rolloutCheck = _cli(fixture, ['check', '--ratchet-ref', anchor]);
    expect(rolloutCheck.exitCode, 0, reason: rolloutCheck.stderr as String);

    File('${fixture.path}/lib/oversized.dart').writeAsStringSync(
      '''
class Oversized {
  void first() {}
  void second() {}
  void regressed() {}
}
'''
          .trimLeft(),
    );
    final regressedSnapshot = _cli(fixture, ['snapshot']);
    expect(regressedSnapshot.exitCode, 0);
    File(
      '${fixture.path}/tool/architecture_baseline.json',
    ).writeAsStringSync(regressedSnapshot.stdout as String);
    _git(fixture, ['add', '.']);
    _git(fixture, ['commit', '-m', 'attempt baseline reset']);

    final regressionCheck = _cli(fixture, ['check', '--ratchet-ref', rollout]);
    expect(regressionCheck.exitCode, 1);
    expect(regressionCheck.stderr, contains('cannot grow'));
  });

  test('CLI compares a divergent branch with the trusted tip baseline', () {
    final fixture = Directory.systemTemp.createTempSync(
      'aonw-architecture-diverged-branch-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    _git(fixture, ['init', '-b', 'dev']);
    _git(fixture, ['config', 'user.email', 'architecture@example.test']);
    _git(fixture, ['config', 'user.name', 'Architecture Fixture']);
    Directory('${fixture.path}/lib').createSync(recursive: true);
    File('${fixture.path}/lib/oversized.dart').writeAsStringSync(
      'class Oversized {\n  void first() {}\n  void second() {}\n}\n',
    );
    _git(fixture, ['add', '.']);
    _git(fixture, ['commit', '-m', 'fixture anchor']);
    final anchor = _git(fixture, ['rev-parse', 'HEAD']).trim();

    Directory('${fixture.path}/tool').createSync(recursive: true);
    File(
      '${fixture.path}/tool/architecture_policy.json',
    ).writeAsStringSync(_policyJson(anchor));
    final snapshot = _cli(fixture, ['snapshot']);
    expect(snapshot.exitCode, 0, reason: snapshot.stderr as String);
    File(
      '${fixture.path}/tool/architecture_baseline.json',
    ).writeAsStringSync(snapshot.stdout as String);
    _git(fixture, ['add', '.']);
    _git(fixture, ['commit', '-m', 'roll out architecture budgets']);
    final rollout = _git(fixture, ['rev-parse', 'HEAD']).trim();

    _git(fixture, ['switch', '-c', 'trusted']);
    File(
      '${fixture.path}/lib/oversized.dart',
    ).writeAsStringSync('class Oversized {\n  void first() {}\n}\n');
    final improvedSnapshot = _cli(fixture, ['snapshot']);
    expect(
      improvedSnapshot.exitCode,
      0,
      reason: improvedSnapshot.stderr as String,
    );
    File(
      '${fixture.path}/tool/architecture_baseline.json',
    ).writeAsStringSync(improvedSnapshot.stdout as String);
    _git(fixture, ['add', '.']);
    _git(fixture, ['commit', '-m', 'reduce trusted architecture debt']);
    final trusted = _git(fixture, ['rev-parse', 'HEAD']).trim();

    _git(fixture, ['switch', '-c', 'feature', rollout]);
    File('${fixture.path}/feature.txt').writeAsStringSync('feature\n');
    _git(fixture, ['add', '.']);
    _git(fixture, ['commit', '-m', 'advance feature branch']);

    final check = _cli(fixture, ['check', '--ratchet-ref', trusted]);
    expect(check.exitCode, 1);
    expect(check.stderr, contains('cannot grow'));
    expect(check.stderr, contains('3 -> 4'));
  });

  test('CLI accepts a divergent trusted ref before the rollout boundary', () {
    final fixture = Directory.systemTemp.createTempSync(
      'aonw-architecture-pre-rollout-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    _git(fixture, ['init', '-b', 'dev']);
    _git(fixture, ['config', 'user.email', 'architecture@example.test']);
    _git(fixture, ['config', 'user.name', 'Architecture Fixture']);
    Directory('${fixture.path}/lib').createSync(recursive: true);
    File('${fixture.path}/lib/oversized.dart').writeAsStringSync(
      'class Oversized {\n  void first() {}\n  void second() {}\n}\n',
    );
    _git(fixture, ['add', '.']);
    _git(fixture, ['commit', '-m', 'common history']);
    final common = _git(fixture, ['rev-parse', 'HEAD']).trim();

    _git(fixture, ['switch', '-c', 'trusted']);
    File('${fixture.path}/trusted.txt').writeAsStringSync('pre-rollout\n');
    _git(fixture, ['add', '.']);
    _git(fixture, ['commit', '-m', 'advance old trusted branch']);
    final trusted = _git(fixture, ['rev-parse', 'HEAD']).trim();

    _git(fixture, ['switch', '-c', 'rollout', common]);
    File('${fixture.path}/rollout.txt').writeAsStringSync('rollout\n');
    _git(fixture, ['add', '.']);
    _git(fixture, ['commit', '-m', 'prepare rollout']);
    final anchor = _git(fixture, ['rev-parse', 'HEAD']).trim();
    Directory('${fixture.path}/tool').createSync(recursive: true);
    File(
      '${fixture.path}/tool/architecture_policy.json',
    ).writeAsStringSync(_policyJson(anchor));
    final snapshot = _cli(fixture, ['snapshot']);
    expect(snapshot.exitCode, 0, reason: snapshot.stderr as String);
    File(
      '${fixture.path}/tool/architecture_baseline.json',
    ).writeAsStringSync(snapshot.stdout as String);

    final check = _cli(fixture, ['check', '--ratchet-ref', trusted]);
    expect(check.exitCode, 0, reason: check.stderr as String);
  });
}

ProcessResult _cli(Directory fixture, List<String> arguments) {
  final packageConfig =
      '${Directory.current.path}/.dart_tool/package_config.json';
  return Process.runSync(
    'dart',
    [
      '--packages=$packageConfig',
      '${Directory.current.path}/tool/check_architecture.dart',
      ...arguments,
      '--repository',
      fixture.path,
    ],
    workingDirectory: Directory.current.path,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
}

String _policyJson(String anchor) => canonicalJson({
  'schema': 1,
  'enforcedSince': anchor,
  'generatedSuffixes': ['.freezed.dart', '.g.dart'],
  'buildRunnerScopes': <String>[],
  'fileLineTargets': {'default': 2},
  'declarationLineTarget': 2,
  'scopes': {
    'root': {
      'sourceRoot': 'lib',
      'generatedPrefixes': <String>[],
      'fileProfiles': {
        'default': {'fallback': true},
      },
    },
  },
});

String _git(Directory repository, List<String> arguments) {
  final result = Process.runSync(
    'git',
    ['-C', repository.path, ...arguments],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    fail('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
  return result.stdout as String;
}
