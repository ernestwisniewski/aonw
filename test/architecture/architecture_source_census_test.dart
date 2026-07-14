import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture/failure.dart';
import '../../tool/architecture/git_repository.dart';
import '../../tool/architecture/policy.dart';
import '../../tool/architecture/source_census.dart';
import '../../tool/architecture/strict_json.dart';

void main() {
  test('generated suffix requires canonical header and sibling input', () {
    final fixture = Directory.systemTemp.createTempSync(
      'aonw-architecture-census-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    _git(fixture, ['init', '-b', 'dev']);
    Directory('${fixture.path}/lib').createSync(recursive: true);
    File(
      '${fixture.path}/lib/model.dart',
    ).writeAsStringSync('class Model {}\n');
    final generated = File('${fixture.path}/lib/model.g.dart')
      ..writeAsStringSync(
        '''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';
'''
            .trimLeft(),
      );
    final policy = ArchitecturePolicy.parse(_policyJson(), 'policy');
    final census = SourceCensus(
      repository: GitRepository(fixture.path),
      policy: policy,
    );

    expect(census.handwrittenFiles('root'), ['lib/model.dart']);

    final measuredOutsideBuildRunnerScope = SourceCensus(
      repository: GitRepository(fixture.path),
      policy: ArchitecturePolicy.parse(
        _policyJson(buildRunnerScopes: const []),
        'policy',
      ),
    );
    expect(measuredOutsideBuildRunnerScope.handwrittenFiles('root'), [
      'lib/model.dart',
      'lib/model.g.dart',
    ]);

    generated.writeAsStringSync('// hand-written masquerade\n');
    expect(
      () => census.handwrittenFiles('root'),
      throwsA(isA<ArchitectureFailure>()),
    );
  });

  test('NUL census is stable across quoting and user-global ignores', () {
    final fixture = _fixture('aonw-architecture-path-census-');
    File(
      '${fixture.path}/.gitignore',
    ).writeAsStringSync('lib/repository_ignored.dart\n');
    Directory('${fixture.path}/lib').createSync(recursive: true);
    final unicode = File('${fixture.path}/lib/żółć.dart')
      ..writeAsStringSync('class Unicode {}\n');
    _git(fixture, ['add', '.gitignore', 'lib/żółć.dart']);
    _git(fixture, ['commit', '-m', 'tracked unicode source']);
    final untracked = File('${fixture.path}/lib/untracked.dart')
      ..writeAsStringSync('class Untracked {}\n');
    File(
      '${fixture.path}/lib/repository_ignored.dart',
    ).writeAsStringSync('class RepositoryIgnored {}\n');
    final globalIgnore = File('${fixture.path}/global-ignore')
      ..writeAsStringSync('*.dart\n');
    _git(fixture, ['config', 'core.excludesFile', globalIgnore.path]);

    final census = SourceCensus(
      repository: GitRepository(fixture.path),
      policy: ArchitecturePolicy.parse(_policyJson(), 'policy'),
    );
    for (final quotePaths in ['true', 'false']) {
      _git(fixture, ['config', 'core.quotePath', quotePaths]);
      expect(census.handwrittenFiles('root'), [
        'lib/untracked.dart',
        'lib/żółć.dart',
      ]);
      census.validateRepositoryCoverage();
    }

    unicode.deleteSync();
    expect(census.handwrittenFiles('root'), ['lib/untracked.dart']);
    expect(untracked.existsSync(), isTrue);
  });

  test('control characters and backslashes fail as non-portable paths', () {
    if (Platform.isWindows) return;
    final fixture = _fixture('aonw-architecture-invalid-path-');
    Directory('${fixture.path}/lib').createSync(recursive: true);
    File(
      '${fixture.path}/lib/model.dart',
    ).writeAsStringSync('class Model {}\n');
    final census = SourceCensus(
      repository: GitRepository(fixture.path),
      policy: ArchitecturePolicy.parse(_policyJson(), 'policy'),
    );

    final newline = File('${fixture.path}/lib/line\nbreak.dart')
      ..writeAsStringSync('class Newline {}\n');
    expect(
      census.validateRepositoryCoverage,
      throwsA(isA<ArchitectureFailure>()),
    );
    newline.deleteSync();

    final backslash = File('${fixture.path}/lib/back\\slash.dart')
      ..writeAsStringSync('class Backslash {}\n');
    expect(
      census.validateRepositoryCoverage,
      throwsA(isA<ArchitectureFailure>()),
    );
    backslash.deleteSync();
    census.validateRepositoryCoverage();
  });

  test('source and generated-input symlinks fail closed', () {
    if (Platform.isWindows) return;
    final fixture = _fixture('aonw-architecture-symlink-');
    Directory('${fixture.path}/lib').createSync(recursive: true);
    File('${fixture.path}/lib/real.dart').writeAsStringSync('class Real {}\n');
    Link('${fixture.path}/lib/link.dart').createSync('real.dart');
    final census = SourceCensus(
      repository: GitRepository(fixture.path),
      policy: ArchitecturePolicy.parse(_policyJson(), 'policy'),
    );

    expect(
      census.validateRepositoryCoverage,
      throwsA(isA<ArchitectureFailure>()),
    );

    Link('${fixture.path}/lib/link.dart').deleteSync();
    File('${fixture.path}/.gitignore').writeAsStringSync('lib/input.dart\n');
    Link('${fixture.path}/lib/input.dart').createSync('real.dart');
    File(
      '${fixture.path}/lib/input.g.dart',
    ).writeAsStringSync('// GENERATED CODE - DO NOT MODIFY BY HAND\n');
    expect(
      () => census.handwrittenFiles('root'),
      throwsA(isA<ArchitectureFailure>()),
    );
  });

  test('reserved role prefixes survive deletion of their last source', () {
    final fixture = _fixture('aonw-architecture-reserved-role-');
    Directory('${fixture.path}/lib').createSync(recursive: true);
    File(
      '${fixture.path}/lib/model.dart',
    ).writeAsStringSync('class Model {}\n');
    final policy = ArchitecturePolicy.parse(
      _policyJson(
        roleAssignments: const {
          'flame_rendering': {
            'paths': ['lib/deleted_rendering/'],
          },
          'test': {
            'paths': ['lib/test_support/'],
          },
          'tool': {
            'paths': ['lib/tooling/'],
          },
        },
      ),
      'policy',
    );

    expect(
      SourceCensus(
        repository: GitRepository(fixture.path),
        policy: policy,
      ).handwrittenFiles('root'),
      ['lib/model.dart'],
    );
    expect(
      policy.scopes['root']!.roleFor('lib/deleted_rendering/scene.dart').name,
      'flame_rendering',
    );
  });
}

String _policyJson({
  List<String> buildRunnerScopes = const ['root'],
  Map<String, Object?> roleAssignments = const {
    'flame_rendering': {
      'paths': ['lib/flame/'],
    },
    'test': {
      'paths': ['lib/test_support/'],
    },
    'tool': {
      'paths': ['lib/tooling/'],
    },
  },
}) => canonicalJson({
  'schema': 2,
  'enforcedSince': '0123456789abcdef0123456789abcdef01234567',
  'migration': {
    'fromSchema': 1,
    'policySha256':
        '0000000000000000000000000000000000000000000000000000000000000000',
    'baselineSha256':
        '1111111111111111111111111111111111111111111111111111111111111111',
    'legacyFileTargets': <String, int>{},
  },
  'generatedSuffixes': ['.freezed.dart', '.g.dart'],
  'buildRunnerScopes': buildRunnerScopes,
  'roles': {
    'flame_rendering': {
      'fileLines': 500,
      'declarationLines': 350,
      'callableLines': 80,
      'nesting': 4,
      'cyclomaticComplexity': 12,
      'cognitiveComplexity': 18,
    },
    'production': {
      'fileLines': 500,
      'declarationLines': 350,
      'callableLines': 60,
      'nesting': 3,
      'cyclomaticComplexity': 10,
      'cognitiveComplexity': 15,
    },
    'test': {
      'fileLines': 500,
      'declarationLines': 350,
      'callableLines': 120,
      'nesting': 4,
      'cyclomaticComplexity': 15,
      'cognitiveComplexity': 20,
    },
    'tool': {
      'fileLines': 500,
      'declarationLines': 350,
      'callableLines': 100,
      'nesting': 4,
      'cyclomaticComplexity': 15,
      'cognitiveComplexity': 20,
    },
  },
  'scopes': {
    'root': {
      'sourceRoot': 'lib',
      'generatedPrefixes': <String>[],
      'defaultRole': 'production',
      'roleAssignments': roleAssignments,
    },
  },
});

void _git(Directory repository, List<String> arguments) {
  final result = Process.runSync('git', ['-C', repository.path, ...arguments]);
  if (result.exitCode != 0) {
    fail('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
}

Directory _fixture(String prefix) {
  final fixture = Directory.systemTemp.createTempSync(prefix);
  addTearDown(() => fixture.deleteSync(recursive: true));
  _git(fixture, ['init', '-b', 'dev']);
  _git(fixture, ['config', 'user.email', 'architecture@example.test']);
  _git(fixture, ['config', 'user.name', 'Architecture Fixture']);
  return fixture;
}
