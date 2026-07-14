import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture/strict_json.dart';

const _policyPath = 'tool/architecture_policy.json';
const _baselinePath = 'tool/architecture_baseline.json';
const _sourcePath = 'lib/subject.dart';
const _simpleSource = 'class Subject {\n  void existing() {}\n}\n';

void main() {
  test('CLI migrates schema 1 by digest and preserves its ratchet', () {
    const source = _simpleSource;
    final fixture = _fixture('migration', source);
    addTearDown(() => fixture.deleteSync(recursive: true));
    final rollout = _rollOutSchemaTwo(fixture, source);

    final valid = _check(fixture, rollout.migrationAnchor);
    expect(valid.exitCode, 0, reason: valid.stderr as String);

    _write(
      fixture,
      _policyPath,
      _schemaTwoPolicyJson(
        rollout.migrationAnchor,
        policySha256: rollout.schemaOnePolicySha256,
        baselineSha256: '0' * 64,
      ),
    );
    final wrongDigest = _check(fixture, rollout.migrationAnchor);
    expect(wrongDigest.exitCode, 1);
    expect(
      wrongDigest.stderr,
      contains('does not match the reviewed migration digest'),
    );

    _write(fixture, _policyPath, rollout.schemaTwoPolicy);
    const regressedSource = '''
class Subject {
  void existing() {}
  void regressed() {}
}
''';
    _write(fixture, _sourcePath, regressedSource);
    _snapshotIntoBaseline(fixture);
    _commit(fixture, 'attempt schema-1 debt reset');

    final legacyRegression = _check(fixture, rollout.migrationAnchor);
    expect(legacyRegression.exitCode, 1);
    expect(legacyRegression.stderr, contains('schema-1 file debt cannot grow'));
    expect(
      legacyRegression.stderr,
      contains('schema-1 declaration debt cannot grow'),
    );
  });

  test('CLI keeps a schema-2 policy immutable after rollout', () {
    const source = '''
class Subject {
  void existing(bool condition) {
    if (condition) {}
  }
}
''';
    final fixture = _fixture('immutable-policy', source);
    addTearDown(() => fixture.deleteSync(recursive: true));
    final rollout = _rollOutSchemaTwo(fixture, source);

    final weakenedTargets = _defaultTargets.copyWith(cyclomaticComplexity: 99);
    _write(
      fixture,
      _policyPath,
      _schemaTwoPolicyJson(
        rollout.migrationAnchor,
        policySha256: rollout.schemaOnePolicySha256,
        baselineSha256: rollout.schemaOneBaselineSha256,
        targets: weakenedTargets,
      ),
    );
    _snapshotIntoBaseline(fixture);
    _commit(fixture, 'weaken architecture policy');

    final check = _check(fixture, rollout.rollout);
    expect(check.exitCode, 1);
    expect(check.stderr, contains('policy is immutable for schema 2'));
  });

  test('CLI rejects a reset plus new and growing schema-2 complexity debt', () {
    const source = '''
class Subject {
  void existing(bool first, bool second) {
    if (first) {
      if (second) {}
    }
  }

  void introduced(bool first, bool second) {}
}
''';
    final fixture = _fixture('complexity-ratchet', source);
    addTearDown(() => fixture.deleteSync(recursive: true));
    final rollout = _rollOutSchemaTwo(fixture, source);
    final reviewedBaseline = _read(fixture, _baselinePath);

    _write(fixture, _baselinePath, _emptySchemaTwoBaselineJson());
    final reset = _check(fixture, rollout.rollout);
    expect(reset.exitCode, 1);
    expect(reset.stderr, contains('nesting debt added'));
    expect(reset.stderr, contains('cyclomatic complexity debt added'));
    expect(reset.stderr, contains('cognitive complexity debt added'));

    _write(fixture, _baselinePath, reviewedBaseline);
    const regressedSource = '''
class Subject {
  void existing(bool first, bool second, bool third) {
    if (first) {
      if (second) {
        if (third) {}
      }
    }
  }

  void introduced(bool first, bool second) {
    if (first) {
      if (second) {}
    }
  }
}
''';
    _write(fixture, _sourcePath, regressedSource);
    _snapshotIntoBaseline(fixture);
    _commit(fixture, 'refresh complexity baseline');

    final refreshed = _check(fixture, rollout.rollout);
    expect(refreshed.exitCode, 1);
    expect(refreshed.stderr, contains('nesting debt cannot be introduced'));
    expect(refreshed.stderr, contains('nesting debt cannot grow'));
    expect(
      refreshed.stderr,
      contains('cyclomatic complexity debt cannot be introduced'),
    );
    expect(
      refreshed.stderr,
      contains('cyclomatic complexity debt cannot grow'),
    );
    expect(refreshed.stderr, contains('migrated file debt cannot grow'));
    expect(refreshed.stderr, contains('cognitive complexity debt cannot grow'));
  });

  test('CLI keeps a migrated file target after a Git rename', () {
    const source = _simpleSource;
    final fixture = _fixture('legacy-rename', source);
    addTearDown(() => fixture.deleteSync(recursive: true));
    final rollout = _rollOutSchemaTwo(fixture, source);

    const renamedPath = 'lib/renamed_subject.dart';
    _git(fixture, ['mv', _sourcePath, renamedPath]);
    _snapshotIntoBaseline(fixture);
    _commit(fixture, 'rename migrated debt');

    final check = _check(fixture, rollout.rollout);
    expect(check.exitCode, 1);
    expect(check.stderr, contains('migrated file debt cannot be introduced'));
    expect(check.stderr, contains(renamedPath));
  });

  test('CLI compares a divergent branch with the trusted schema-2 tip', () {
    const source = '''
class Subject {
  void existing(bool first, bool second) {
    if (first) {
      if (second) {}
    }
  }
}
''';
    const targets = _Targets(
      fileLines: 100,
      declarationLines: 100,
      callableLines: 100,
      nesting: 10,
      cyclomaticComplexity: 1,
      cognitiveComplexity: 100,
    );
    final fixture = _fixture('diverged-branch', source);
    addTearDown(() => fixture.deleteSync(recursive: true));
    final rollout = _rollOutSchemaTwo(fixture, source, targets: targets);

    _git(fixture, ['switch', '-c', 'trusted']);
    const improvedSource = '''
class Subject {
  void existing(bool first) {
    if (first) {}
  }
}
''';
    _write(fixture, _sourcePath, improvedSource);
    _snapshotIntoBaseline(fixture);
    final trusted = _commit(fixture, 'reduce trusted complexity debt');

    _git(fixture, ['switch', '-c', 'feature', rollout.rollout]);
    _write(fixture, 'feature.txt', 'feature\n');
    _commit(fixture, 'advance feature branch');

    final check = _check(fixture, trusted);
    expect(check.exitCode, 1);
    expect(check.stderr, contains('cyclomatic complexity debt cannot grow'));
    expect(check.stderr, contains('2 -> 3'));
  });

  test('CLI accepts a divergent trusted ref before the rollout boundary', () {
    const source = _simpleSource;
    final fixture = _fixture('pre-rollout', source);
    addTearDown(() => fixture.deleteSync(recursive: true));
    final common = _head(fixture);

    _git(fixture, ['switch', '-c', 'trusted']);
    _write(fixture, 'trusted.txt', 'pre-rollout\n');
    final trusted = _commit(fixture, 'advance old trusted branch');

    _git(fixture, ['switch', '-c', 'rollout', common]);
    _write(fixture, 'rollout.txt', 'rollout\n');
    final anchor = _commit(fixture, 'prepare rollout');
    _write(
      fixture,
      _policyPath,
      _schemaTwoPolicyJson(
        anchor,
        policySha256: '0' * 64,
        baselineSha256: '1' * 64,
      ),
    );
    _snapshotIntoBaseline(fixture);

    final check = _check(fixture, trusted);
    expect(check.exitCode, 0, reason: check.stderr as String);
  });
}

const _defaultTargets = _Targets(
  fileLines: 100,
  declarationLines: 100,
  callableLines: 100,
  nesting: 1,
  cyclomaticComplexity: 2,
  cognitiveComplexity: 2,
);

final class _Targets {
  const _Targets({
    required this.fileLines,
    required this.declarationLines,
    required this.callableLines,
    required this.nesting,
    required this.cyclomaticComplexity,
    required this.cognitiveComplexity,
  });

  final int fileLines;
  final int declarationLines;
  final int callableLines;
  final int nesting;
  final int cyclomaticComplexity;
  final int cognitiveComplexity;

  _Targets copyWith({int? cyclomaticComplexity}) => _Targets(
    fileLines: fileLines,
    declarationLines: declarationLines,
    callableLines: callableLines,
    nesting: nesting,
    cyclomaticComplexity: cyclomaticComplexity ?? this.cyclomaticComplexity,
    cognitiveComplexity: cognitiveComplexity,
  );

  Map<String, Object?> toJson() => {
    'fileLines': fileLines,
    'declarationLines': declarationLines,
    'callableLines': callableLines,
    'nesting': nesting,
    'cyclomaticComplexity': cyclomaticComplexity,
    'cognitiveComplexity': cognitiveComplexity,
  };
}

final class _Rollout {
  const _Rollout({
    required this.migrationAnchor,
    required this.rollout,
    required this.schemaOnePolicySha256,
    required this.schemaOneBaselineSha256,
    required this.schemaTwoPolicy,
  });

  final String migrationAnchor;
  final String rollout;
  final String schemaOnePolicySha256;
  final String schemaOneBaselineSha256;
  final String schemaTwoPolicy;
}

Directory _fixture(String name, String source) {
  final fixture = Directory.systemTemp.createTempSync(
    'aonw-architecture-$name-',
  );
  _git(fixture, ['init', '-b', 'dev']);
  _git(fixture, ['config', 'user.email', 'architecture@example.test']);
  _git(fixture, ['config', 'user.name', 'Architecture Fixture']);
  _write(fixture, _sourcePath, source);
  _commit(fixture, 'fixture source');
  return fixture;
}

_Rollout _rollOutSchemaTwo(
  Directory fixture,
  String source, {
  _Targets targets = _defaultTargets,
}) {
  final schemaOnePolicy = _schemaOnePolicyJson(_head(fixture));
  final schemaOneBaseline = _schemaOneBaselineJson(source);
  _write(fixture, _policyPath, schemaOnePolicy);
  _write(fixture, _baselinePath, schemaOneBaseline);
  final migrationAnchor = _commit(fixture, 'record schema-1 ratchet');
  final policySha256 = _sha256(schemaOnePolicy);
  final baselineSha256 = _sha256(schemaOneBaseline);
  final schemaTwoPolicy = _schemaTwoPolicyJson(
    migrationAnchor,
    policySha256: policySha256,
    baselineSha256: baselineSha256,
    targets: targets,
  );
  _write(fixture, _policyPath, schemaTwoPolicy);
  _snapshotIntoBaseline(fixture);
  final rollout = _commit(fixture, 'roll out schema-2 budgets');
  return _Rollout(
    migrationAnchor: migrationAnchor,
    rollout: rollout,
    schemaOnePolicySha256: policySha256,
    schemaOneBaselineSha256: baselineSha256,
    schemaTwoPolicy: schemaTwoPolicy,
  );
}

String _schemaOnePolicyJson(String anchor) => canonicalJson({
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

String _schemaOneBaselineJson(String source) {
  final lines = const LineSplitter().convert(source).length;
  return canonicalJson({
    'schema': 1,
    'scopes': {
      'root': {
        'files': {_sourcePath: lines},
        'declarations': {'$_sourcePath::class:Subject': lines},
      },
    },
  });
}

String _schemaTwoPolicyJson(
  String anchor, {
  required String policySha256,
  required String baselineSha256,
  _Targets targets = _defaultTargets,
}) => canonicalJson({
  'schema': 2,
  'enforcedSince': anchor,
  'migration': {
    'fromSchema': 1,
    'policySha256': policySha256,
    'baselineSha256': baselineSha256,
    'legacyFileTargets': {_sourcePath: 2},
  },
  'generatedSuffixes': ['.freezed.dart', '.g.dart'],
  'buildRunnerScopes': <String>[],
  'roles': {
    'flame_rendering': targets.toJson(),
    'production': targets.toJson(),
    'test': targets.toJson(),
    'tool': targets.toJson(),
  },
  'scopes': {
    'root': {
      'sourceRoot': 'lib',
      'generatedPrefixes': <String>[],
      'defaultRole': 'production',
      'roleAssignments': {
        'flame_rendering': {
          'paths': ['lib/flame_support.dart'],
        },
        'test': {
          'paths': ['lib/test_support.dart'],
        },
        'tool': {
          'paths': ['lib/tool_support.dart'],
        },
      },
    },
  },
});

String _emptySchemaTwoBaselineJson() => canonicalJson({
  'schema': 2,
  'scopes': {
    'root': {
      'files': <String, int>{},
      'legacyFiles': <String, int>{},
      'declarations': <String, int>{},
      'callableLines': <String, int>{},
      'nesting': <String, int>{},
      'cyclomaticComplexity': <String, int>{},
      'cognitiveComplexity': <String, int>{},
    },
  },
});

void _snapshotIntoBaseline(Directory fixture) {
  final snapshot = _cli(fixture, ['snapshot']);
  expect(snapshot.exitCode, 0, reason: snapshot.stderr as String);
  _write(fixture, _baselinePath, snapshot.stdout as String);
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

ProcessResult _check(Directory fixture, String ref) =>
    _cli(fixture, ['check', '--ratchet-ref', ref]);

String _commit(Directory repository, String message) {
  _git(repository, ['add', '.']);
  _git(repository, ['commit', '-m', message]);
  return _head(repository);
}

String _head(Directory repository) =>
    _git(repository, ['rev-parse', 'HEAD']).trim();

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

void _write(Directory repository, String path, String contents) {
  final file = File('${repository.path}/$path');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

String _read(Directory repository, String path) =>
    File('${repository.path}/$path').readAsStringSync();

String _sha256(String contents) =>
    sha256.convert(utf8.encode(contents)).toString();
