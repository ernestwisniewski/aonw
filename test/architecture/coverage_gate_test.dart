import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/coverage_gate_fixtures.dart';

final _checkerPath = File('tool/check_coverage.dart').absolute.path;

void main() {
  test('repository coverage policy pins scopes, layers, and exclusions', () {
    final policy = jsonDecode(
      File('tool/coverage_policy.json').readAsStringSync(),
    );

    expect(policy, _expectedRepositoryPolicy);
  });

  test('accepts baseline floors and fully covered changed lines', () {
    final fixture = _CoverageFixture.create();
    addTearDown(fixture.dispose);
    fixture.writePrimarySource(answer: 43);

    final result = fixture.check();

    expect(result.exitCode, 0, reason: fixture.output(result));
    expect(result.stdout, contains('Coverage root'));
    expect(result.stdout, contains('changed coverable lines: 1/1 (100.00%)'));
  });

  test('allows the initial rollout when the trusted ref is the anchor', () {
    final fixture = _CoverageFixture.create();
    addTearDown(fixture.dispose);

    final result = fixture.check(ratchetRef: fixture.anchor);

    expect(result.exitCode, 0, reason: fixture.output(result));
  });

  test('normalizes Windows LCOV separators', () {
    final fixture = _CoverageFixture.create();
    addTearDown(fixture.dispose);
    fixture.writeRawLcov('''
SF:lib\\domain\\logic.dart
DA:1,1
DA:2,1
LF:2
LH:2
end_of_record
''');

    final result = fixture.check();

    expect(result.exitCode, 0, reason: fixture.output(result));
  });

  test('accepts CRLF only for the canonical excluded composition root', () {
    final fixture = _CoverageFixture.create(
      manualMainContents: canonicalCoverageMain.replaceAll('\n', '\r\n'),
    );
    addTearDown(fixture.dispose);

    final canonicalResult = fixture.check();

    expect(
      canonicalResult.exitCode,
      0,
      reason: fixture.output(canonicalResult),
    );

    fixture.writeSource(
      'lib/main.dart',
      canonicalCoverageMain.replaceFirst('HexApp()', 'ChangedApp()'),
    );

    final changedResult = fixture.check();

    expect(
      changedResult.exitCode,
      isNot(0),
      reason: fixture.output(changedResult),
    );
    expect(changedResult.stderr, contains('canonical thin composition root'));
  });

  test('rejects malformed and duplicate LCOV records', () {
    final fixture = _CoverageFixture.create();
    addTearDown(fixture.dispose);

    for (final testCase in const <_InvalidLcovCase>[
      _InvalidLcovCase(
        description: 'malformed line record',
        contents: '''
SF:lib/domain/logic.dart
DA:not-a-line,1
LF:1
LH:1
end_of_record
''',
        expectedError: 'invalid or duplicate DA record',
      ),
      _InvalidLcovCase(
        description: 'duplicate line record',
        contents: '''
SF:lib/domain/logic.dart
DA:1,1
DA:1,1
LF:1
LH:1
end_of_record
''',
        expectedError: 'invalid or duplicate DA record',
      ),
      _InvalidLcovCase(
        description: 'duplicate source record',
        contents: '''
SF:lib/domain/logic.dart
DA:1,1
LF:1
LH:1
end_of_record
SF:lib/domain/logic.dart
DA:2,1
LF:1
LH:1
end_of_record
''',
        expectedError: 'empty or duplicate SF',
      ),
      _InvalidLcovCase(
        description: 'totals before source record',
        contents: '''
LF:0
LH:0
SF:lib/domain/logic.dart
end_of_record
''',
        expectedError: 'LF appears outside its record order',
      ),
      _InvalidLcovCase(
        description: 'line outside the current source file',
        contents: '''
SF:lib/domain/logic.dart
DA:3,1
LF:1
LH:1
end_of_record
''',
        expectedError: 'LCOV references lines outside lib/domain/logic.dart',
      ),
    ]) {
      fixture.writeRawLcov(testCase.contents);

      final result = fixture.check();

      expect(
        result.exitCode,
        isNot(0),
        reason: '${testCase.description}\n${fixture.output(result)}',
      );
      expect(
        result.stderr,
        contains(testCase.expectedError),
        reason: testCase.description,
      );
    }
  });

  test('rejects an unclassified handwritten source file', () {
    final fixture = _CoverageFixture.create();
    addTearDown(fixture.dispose);
    fixture.writeSource('lib/orphan.dart', 'int orphan() => 1;\n');

    final result = fixture.check();

    expect(result.exitCode, isNot(0), reason: fixture.output(result));
    expect(
      result.stderr,
      contains(
        'lib/orphan.dart must match exactly one coverage layer; matched none',
      ),
    );
  });

  test('rejects coverage ignore markers in handwritten sources', () {
    final fixture = _CoverageFixture.create();
    addTearDown(fixture.dispose);
    fixture.writePrimarySource(extra: '// coverage:ignore\n');

    final result = fixture.check();

    expect(result.exitCode, isNot(0), reason: fixture.output(result));
    expect(
      result.stderr,
      contains(
        'handwritten source uses a coverage ignore marker: '
        'lib/domain/logic.dart',
      ),
    );
  });

  test('rejects handwritten files disguised by a generated suffix', () {
    final fixture = _CoverageFixture.create();
    addTearDown(fixture.dispose);
    fixture.writeSource(
      'lib/domain/escape.g.dart',
      '// GENERATED CODE - DO NOT MODIFY BY HAND\n'
          'int uncoveredEscape() => 1;\n',
    );

    final result = fixture.check();

    expect(result.exitCode, isNot(0), reason: fixture.output(result));
    expect(
      result.stderr,
      contains(
        'generated suffix requires the canonical build_runner header and '
        'sibling input: lib/domain/escape.g.dart',
      ),
    );
  });

  test('allows file and line coverage above the reviewed baseline floors', () {
    final fixture = _CoverageFixture.create(
      firstLineHits: 0,
      baselineFilesHit: 0,
    );
    addTearDown(fixture.dispose);
    fixture.writeLcov();

    final result = fixture.check();

    expect(result.exitCode, 0, reason: fixture.output(result));
  });

  test('rejects coverage below the reviewed baseline floor', () {
    final fixture = _CoverageFixture.create();
    addTearDown(fixture.dispose);
    fixture.writeLcov(firstLineHits: 0);

    final result = fixture.check();

    expect(result.exitCode, isNot(0), reason: fixture.output(result));
    expect(
      result.stderr,
      contains('root/domain lines covered count regressed: 2 -> 1'),
    );
  });

  test('rejects a changed instrumentation total', () {
    final fixture = _CoverageFixture.create();
    addTearDown(fixture.dispose);
    fixture.writeRawLcov('''
SF:lib/domain/logic.dart
DA:1,1
LF:1
LH:1
end_of_record
''');

    final result = fixture.check();

    expect(result.exitCode, isNot(0), reason: fixture.output(result));
    expect(result.stderr, contains('root/domain lines total changed: 2 -> 1'));
  });

  test('rejects changed-line coverage below ninety percent', () {
    final fixture = _CoverageFixture.create(firstLineHits: 0);
    addTearDown(fixture.dispose);
    fixture.writePrimarySource(answer: 43);

    final result = fixture.check();

    expect(result.exitCode, isNot(0), reason: fixture.output(result));
    expect(
      result.stderr,
      contains('diff/domain line coverage is 0.00%; minimum is 90.00%'),
    );
  });

  test('rejects a changed source file that is absent from LCOV', () {
    final fixture = _CoverageFixture.create(includeMissingSource: true);
    addTearDown(fixture.dispose);
    fixture.writeSource(
      'lib/domain/missing.dart',
      'int deliberatelyMissing() => 2;\n',
    );

    final result = fixture.check();

    expect(result.exitCode, isNot(0), reason: fixture.output(result));
    expect(
      result.stderr,
      contains(
        'root diff: changed source is absent from LCOV: '
        'lib/domain/missing.dart',
      ),
    );
  });

  test(
    'rejects historical ratio, uncovered, and missing-source regressions',
    () {
      final fixture = _CoverageFixture.create();
      addTearDown(fixture.dispose);
      fixture
        ..writeSource(
          'lib/domain/missing.dart',
          'int deliberatelyMissing() => 1;\n',
        )
        ..writeBaseline(
          filesHit: 1,
          filesFound: 2,
          linesHit: 2,
          missingFiles: const ['lib/domain/missing.dart'],
        )
        ..commitCurrentBaselineAndSources('Regress coverage baseline')
        ..commitUnrelatedChange('Hide regression in a later commit');

      final result = fixture.check();

      expect(result.exitCode, isNot(0), reason: fixture.output(result));
      expect(result.stderr, contains('root/domain files ratio decreased'));
      expect(
        result.stderr,
        contains('files uncovered count increased: 0 -> 1'),
      );
      expect(
        result.stderr,
        contains(
          'the missing-source set may only shrink; added '
          'lib/domain/missing.dart',
        ),
      );
    },
  );

  test('rejects uncommitted policy weakening against the trusted ref', () {
    final fixture = _CoverageFixture.create();
    addTearDown(fixture.dispose);
    fixture.writePolicy(diffMinimumBasisPoints: 8000);

    final lowerThreshold = fixture.check();

    expect(
      lowerThreshold.exitCode,
      isNot(0),
      reason: fixture.output(lowerThreshold),
    );
    expect(
      lowerThreshold.stderr,
      contains('Diff coverage minimum cannot decrease'),
    );

    fixture.writePolicy(excludeFiles: const ['lib/domain/logic.dart']);

    final broaderExclusion = fixture.check();

    expect(
      broaderExclusion.exitCode,
      isNot(0),
      reason: fixture.output(broaderExclusion),
    );
    expect(
      broaderExclusion.stderr,
      contains('Coverage scope, layer, and exclusion policy is immutable'),
    );
  });
}

const _expectedRepositoryPolicy = <String, Object?>{
  'schema': 2,
  'enforcedSince': 'ee7ecf961f2d27b0ac9ea0f3ba0d1d4768fa7189',
  'ratchetEpoch': 8,
  'diffLineMinimumBasisPoints': 9000,
  'excludeSuffixes': <String>['.freezed.dart', '.g.dart'],
  'scopes': <String, Object?>{
    'root': <String, Object?>{
      'packageRoot': '.',
      'sourceRoot': 'lib',
      'lcov': 'coverage/root.lcov.info',
      'excludePrefixes': <String>['lib/l10n/generated/'],
      'excludeFiles': <String>['lib/main.dart'],
      'layers': <String, Object?>{
        'api': <String>['lib/api/'],
        'app': <String>['lib/app/'],
        'developer': <String>['lib/developer/'],
        'editor': <String>['lib/editor/'],
        'game_analysis': <String>['lib/game/analysis/'],
        'game_application': <String>['lib/game/application/'],
        'game_domain': <String>['lib/game/domain/'],
        'game_infrastructure': <String>['lib/game/infrastructure/'],
        'game_presentation_engine': <String>[
          'lib/game/presentation/engine.dart',
          'lib/game/presentation/engine/',
        ],
        'game_presentation_screens': <String>[
          'lib/game/presentation/screens.dart',
          'lib/game/presentation/screens/',
        ],
        'game_presentation_widgets': <String>[
          'lib/game/presentation/widgets.dart',
          'lib/game/presentation/widgets/',
        ],
        'game_presentation_support': <String>[
          'lib/game/presentation/providers.dart',
          'lib/game/presentation/audio/',
          'lib/game/presentation/controllers/',
          'lib/game/presentation/formatters/',
          'lib/game/presentation/input/',
          'lib/game/presentation/providers/',
          'lib/game/presentation/replay/',
          'lib/game/presentation/services/',
        ],
        'l10n': <String>['lib/l10n/'],
        'map': <String>['lib/map/'],
        'menu': <String>['lib/menu/'],
        'shared': <String>['lib/shared/'],
      },
    },
    'core': <String, Object?>{
      'packageRoot': 'packages/aonw_core',
      'sourceRoot': 'packages/aonw_core/lib',
      'lcov': 'coverage/core.lcov.info',
      'excludePrefixes': <String>[],
      'excludeFiles': <String>[],
      'layers': <String, Object?>{
        'ai': <String>[
          'packages/aonw_core/lib/ai.dart',
          'packages/aonw_core/lib/ai/',
        ],
        'domain': <String>[
          'packages/aonw_core/lib/domain.dart',
          'packages/aonw_core/lib/domain/',
          'packages/aonw_core/lib/game/',
        ],
        'map': <String>['packages/aonw_core/lib/map/'],
        'protocol': <String>[
          'packages/aonw_core/lib/protocol.dart',
          'packages/aonw_core/lib/protocol/',
        ],
        'util': <String>['packages/aonw_core/lib/util/'],
      },
    },
    'server': <String, Object?>{
      'packageRoot': 'server',
      'sourceRoot': 'server/lib',
      'lcov': 'coverage/server.lcov.info',
      'excludePrefixes': <String>['server/lib/src/generated/'],
      'excludeFiles': <String>[],
      'layers': <String, Object?>{
        'bootstrap_and_status': <String>[
          'server/lib/server.dart',
          'server/lib/src/app_status/',
        ],
        'auth': <String>['server/lib/src/auth/'],
        'multiplayer': <String>['server/lib/src/multiplayer/'],
        'public_stats': <String>['server/lib/src/public_stats/'],
        'scheduling': <String>['server/lib/src/scheduling/'],
        'observability': <String>['server/lib/src/observability/'],
      },
    },
  },
};

final class _InvalidLcovCase {
  const _InvalidLcovCase({
    required this.description,
    required this.contents,
    required this.expectedError,
  });

  final String description;
  final String contents;
  final String expectedError;
}

final class _CoverageFixture {
  _CoverageFixture._(this.directory);

  factory _CoverageFixture.create({
    int firstLineHits = 1,
    int baselineFilesHit = 1,
    bool includeMissingSource = false,
    String? manualMainContents,
  }) {
    final directory = Directory.systemTemp.createTempSync(
      'aonw-coverage-gate-',
    );
    final fixture = _CoverageFixture._(directory)
      .._initializeRepository()
      ..writeSource('tool/coverage_gate/main.dart.txt', canonicalCoverageMain)
      ..writePrimarySource();
    if (manualMainContents != null) {
      fixture.writeSource('lib/main.dart', manualMainContents);
    }
    if (includeMissingSource) {
      fixture.writeSource(
        'lib/domain/missing.dart',
        'int deliberatelyMissing() => 1;\n',
      );
    }
    fixture
      .._git(const ['add', 'lib'])
      .._git(const ['commit', '--quiet', '-m', 'Add source'])
      ..anchor = fixture._git(const ['rev-parse', 'HEAD']).trim()
      ..writePolicy(
        excludeFiles: manualMainContents == null
            ? const []
            : const ['lib/main.dart'],
      )
      ..writeBaseline(
        filesHit: baselineFilesHit,
        filesFound: includeMissingSource ? 2 : 1,
        linesHit: firstLineHits > 0 ? 2 : 1,
        missingFiles: includeMissingSource
            ? const ['lib/domain/missing.dart']
            : const [],
      )
      ..writeLcov(firstLineHits: firstLineHits)
      .._git(const [
        'add',
        'tool/coverage_policy.json',
        'tool/coverage_baseline.json',
        'tool/coverage_gate/main.dart.txt',
      ])
      .._git(const ['commit', '--quiet', '-m', 'Add coverage policy'])
      ..captureBaselineRef();
    return fixture;
  }

  final Directory directory;
  late final String anchor;
  late final String baselineRef;

  void dispose() => directory.deleteSync(recursive: true);

  void writePrimarySource({int answer = 42, String extra = ''}) {
    writeSource(
      'lib/domain/logic.dart',
      'int answer() => $answer;\nint anotherAnswer() => 7;\n$extra',
    );
  }

  void writeSource(String path, String contents) {
    final file = File('${directory.path}/$path');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  }

  void writePolicy({
    int diffMinimumBasisPoints = 9000,
    int ratchetEpoch = 0,
    List<String> excludeFiles = const [],
  }) {
    _writeJson('tool/coverage_policy.json', <String, Object?>{
      'schema': 2,
      'enforcedSince': anchor,
      'ratchetEpoch': ratchetEpoch,
      'diffLineMinimumBasisPoints': diffMinimumBasisPoints,
      'excludeSuffixes': <String>['.freezed.dart', '.g.dart'],
      'scopes': <String, Object?>{
        'root': <String, Object?>{
          'packageRoot': '.',
          'sourceRoot': 'lib',
          'lcov': 'coverage/root.lcov.info',
          'excludePrefixes': <String>[],
          'excludeFiles': excludeFiles,
          'layers': <String, Object?>{
            'domain': <String>['lib/domain/'],
          },
        },
      },
    });
  }

  void writeBaseline({
    required int filesHit,
    required int filesFound,
    required int linesHit,
    required List<String> missingFiles,
  }) {
    _writeJson('tool/coverage_baseline.json', <String, Object?>{
      'schema': 1,
      'scopes': <String, Object?>{
        'root': <String, Object?>{
          'layers': <String, Object?>{
            'domain': <String, Object?>{
              'files': <String, Object?>{'hit': filesHit, 'found': filesFound},
              'lines': <String, Object?>{'hit': linesHit, 'found': 2},
            },
          },
          'missingFiles': missingFiles,
        },
      },
    });
  }

  void writeLcov({int firstLineHits = 1}) {
    writeRawLcov('''
SF:lib/domain/logic.dart
DA:1,$firstLineHits
DA:2,1
LF:2
LH:${firstLineHits > 0 ? 2 : 1}
end_of_record
''');
  }

  void writeRawLcov(String contents) {
    writeSource('coverage/root.lcov.info', contents.trimLeft());
  }

  void commitCurrentBaselineAndSources(String message) {
    _git(const ['add', 'lib', 'tool/coverage_baseline.json']);
    _git(['commit', '--quiet', '-m', message]);
  }

  void captureBaselineRef() {
    baselineRef = _git(const ['rev-parse', 'HEAD']).trim();
  }

  void commitUnrelatedChange(String message) {
    writeSource('README.md', 'Later commit in the same push.\n');
    _git(const ['add', 'README.md']);
    _git(['commit', '--quiet', '-m', message]);
  }

  ProcessResult check({String? ratchetRef}) => Process.runSync(
    'dart',
    [
      _checkerPath,
      'check',
      '--repository',
      directory.path,
      '--policy',
      'tool/coverage_policy.json',
      '--baseline',
      'tool/coverage_baseline.json',
      '--base-ref',
      anchor,
      '--ratchet-ref',
      ratchetRef ?? baselineRef,
    ],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );

  String output(ProcessResult result) =>
      'stdout:\n${result.stdout}\nstderr:\n${result.stderr}';

  void _initializeRepository() {
    _git(const ['init', '--quiet', '--initial-branch=main']);
    _git(const ['config', 'user.name', 'Coverage Gate Test']);
    _git(const ['config', 'user.email', 'coverage-gate@example.test']);
    _git(const ['config', 'commit.gpgsign', 'false']);
  }

  void _writeJson(String path, Map<String, Object?> value) {
    writeSource(path, '${const JsonEncoder.withIndent('  ').convert(value)}\n');
  }

  String _git(List<String> arguments) {
    final result = Process.runSync(
      'git',
      ['-C', directory.path, ...arguments],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      throw StateError(
        'git ${arguments.join(' ')} failed:\n'
        '${result.stdout}\n${result.stderr}',
      );
    }
    return result.stdout as String;
  }
}
