import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

const _basePath = 'analysis_options_base.yaml';

const _sharedRules = <String>{
  'always_use_package_imports',
  'avoid_dynamic_calls',
  'avoid_returning_this',
  'avoid_void_async',
  'cascade_invocations',
  'directives_ordering',
  'discarded_futures',
  'prefer_const_constructors',
  'prefer_const_declarations',
  'prefer_final_in_for_each',
  'prefer_final_locals',
  'require_trailing_commas',
  'unawaited_futures',
};

const _leafProfiles = <String, _LeafProfile>{
  'analysis_options.yaml': _LeafProfile(
    includes: ['package:flutter_lints/flutter.yaml', _basePath],
    analyzerErrors: {'invalid_annotation_target': 'ignore'},
    excludes: {
      '**/*.g.dart',
      '**/*.freezed.dart',
      'server/**',
      'third_party/**',
    },
  ),
  'packages/aonw_core/analysis_options.yaml': _LeafProfile(
    includes: [
      'package:lints/recommended.yaml',
      '../../analysis_options_base.yaml',
    ],
  ),
  'packages/aonw_server_client/analysis_options.yaml': _LeafProfile(
    includes: [
      'package:lints/recommended.yaml',
      '../../analysis_options_base.yaml',
    ],
    excludes: {'build/**', 'lib/src/protocol/**'},
  ),
  'server/analysis_options.yaml': _LeafProfile(
    includes: [
      'package:lints/recommended.yaml',
      '../analysis_options_base.yaml',
    ],
    excludes: {
      'build/**',
      'lib/src/generated/**',
      'test/integration/test_tools/serverpod_test_tools.dart',
    },
  ),
};

void main() {
  test('every non-ignored analysis configuration is classified', () {
    final configurations = _gitPaths(const [
      'analysis_options.yaml',
      '**/analysis_options.yaml',
      _basePath,
      '**/analysis_options_base.yaml',
    ]);

    expect(configurations, {_basePath, ..._leafProfiles.keys});
  });

  test('shared base owns the exact strict workspace policy', () {
    final base = _loadMap(_basePath);

    expect(_keys(base), {'analyzer', 'linter'});
    final analyzer = _asMap(base['analyzer'], '$_basePath analyzer');
    expect(_keys(analyzer), {'language'});
    final language = _asMap(
      analyzer['language'],
      '$_basePath analyzer.language',
    );
    expect(_keys(language), {
      'strict-casts',
      'strict-inference',
      'strict-raw-types',
    });
    expect(language.values, everyElement(isTrue));

    final linter = _asMap(base['linter'], '$_basePath linter');
    expect(_keys(linter), {'rules'});
    final rules = _asMap(linter['rules'], '$_basePath linter.rules');
    expect(_keys(rules), _sharedRules);
    expect(rules.values, everyElement(isTrue));
  });

  test('all four packages compose upstream, shared, then local policy', () {
    for (final entry in _leafProfiles.entries) {
      final path = entry.key;
      final profile = entry.value;
      final options = _loadMap(path);
      final expectedTopLevel = {
        'include',
        if (profile.hasAnalyzerOptions) 'analyzer',
      };

      expect(_keys(options), expectedTopLevel, reason: path);
      expect(
        _stringList(options['include'], '$path include'),
        profile.includes,
      );
      expect(
        options['linter'],
        isNull,
        reason: '$path duplicates shared rules',
      );
      expect(
        options['language'],
        isNull,
        reason: '$path bypasses the shared strict policy',
      );

      if (!profile.hasAnalyzerOptions) continue;
      final analyzer = _asMap(options['analyzer'], '$path analyzer');
      final expectedAnalyzerKeys = {
        if (profile.analyzerErrors != null) 'errors',
        if (profile.excludes != null) 'exclude',
      };
      expect(_keys(analyzer), expectedAnalyzerKeys, reason: path);
      if (profile.analyzerErrors case final expectedErrors?) {
        final errors = _asMap(analyzer['errors'], '$path analyzer.errors');
        expect(
          {for (final key in errors.keys) key as String: errors[key]},
          expectedErrors,
          reason: path,
        );
      }
      if (profile.excludes case final expectedExcludes?) {
        expect(
          _stringList(analyzer['exclude'], '$path analyzer.exclude').toSet(),
          expectedExcludes,
          reason: path,
        );
      }
    }
  });

  test('every non-vendor Dart workspace maps to one leaf policy', () {
    const vendorManifests = {'third_party/sign_in_with_apple/pubspec.yaml'};
    final manifests = _gitPaths(const ['pubspec.yaml', '**/pubspec.yaml']);
    final workspaceManifests = manifests.difference(vendorManifests);
    final mappedPolicies = workspaceManifests
        .map(_analysisOptionsForManifest)
        .toSet();

    expect(
      manifests.where((path) => path.startsWith('third_party/')).toSet(),
      vendorManifests,
    );
    expect(mappedPolicies, _leafProfiles.keys.toSet());
    expect(workspaceManifests, hasLength(_leafProfiles.length));
  });

  test('lint packages and resolved lint versions cannot drift', () {
    const directLintPackages = {
      'pubspec.yaml': ('flutter_lints', '^6.0.0'),
      'packages/aonw_core/pubspec.yaml': ('lints', '^6.0.0'),
      'packages/aonw_server_client/pubspec.yaml': ('lints', '^6.0.0'),
      'server/pubspec.yaml': ('lints', '^6.0.0'),
    };
    const lockfiles = [
      'pubspec.lock',
      'packages/aonw_core/pubspec.lock',
      'packages/aonw_server_client/pubspec.lock',
      'server/pubspec.lock',
    ];

    for (final entry in directLintPackages.entries) {
      final manifest = _loadMap(entry.key);
      final dependencies = _optionalMap(manifest['dependencies']);
      final devDependencies = _asMap(
        manifest['dev_dependencies'],
        '${entry.key} dev_dependencies',
      );
      expect(
        devDependencies[entry.value.$1],
        entry.value.$2,
        reason: entry.key,
      );
      expect(
        devDependencies.containsKey(
          entry.value.$1 == 'lints' ? 'flutter_lints' : 'lints',
        ),
        isFalse,
        reason: entry.key,
      );
      expect(dependencies.containsKey('analyzer'), isFalse, reason: entry.key);
      expect(
        devDependencies['analyzer'],
        entry.key == 'pubspec.yaml' ? '12.1.0' : isNull,
        reason: entry.key,
      );
    }

    final resolvedLintFingerprints = <String>{};
    for (final path in lockfiles) {
      final lock = _loadMap(path);
      final packages = _asMap(lock['packages'], '$path packages');
      final lints = _asMap(packages['lints'], '$path packages.lints');
      final version = lints['version'];
      final source = lints['source'];
      final description = _asMap(
        lints['description'],
        '$path packages.lints.description',
      );
      final sha256 = description['sha256'];

      expect(version, isA<String>(), reason: path);
      expect(version, matches(RegExp(r'^\d+\.\d+\.\d+$')), reason: path);
      expect(source, 'hosted', reason: path);
      expect(_keys(description), {'name', 'sha256', 'url'}, reason: path);
      expect(description['name'], 'lints', reason: path);
      expect(description['url'], 'https://pub.dev', reason: path);
      expect(sha256, isA<String>(), reason: path);
      expect(sha256, matches(RegExp(r'^[0-9a-f]{64}$')), reason: path);

      resolvedLintFingerprints.add(
        '$version|$source|${description['url']}|$sha256',
      );
    }
    expect(
      resolvedLintFingerprints,
      hasLength(1),
      reason: 'All lockfiles must resolve the same hosted lints artifact.',
    );
  });

  test('Make owns fatal analyzers and CI delegates without command drift', () {
    final makefile = File('Makefile').readAsStringSync();
    const dependencyTargets = {
      'root-dependencies': (
        'toolchain-check',
        'flutter pub get --enforce-lockfile',
      ),
      'core-dependencies': (
        'toolchain-check',
        'cd packages/aonw_core && dart pub get --enforce-lockfile',
      ),
      'client-dependencies': (
        'toolchain-check',
        'cd packages/aonw_server_client && dart pub get --enforce-lockfile',
      ),
      'server-dependencies': (
        'toolchain-check',
        'cd server && dart pub get --enforce-lockfile',
      ),
    };
    const analyzerTargets = {
      'flutter-analyze': (
        'root-dependencies',
        'flutter analyze --no-pub --fatal-infos --fatal-warnings',
      ),
      'core-analyze': (
        'core-dependencies',
        'cd packages/aonw_core && dart analyze --fatal-infos --fatal-warnings',
      ),
      'client-analyze': (
        'client-dependencies',
        'cd packages/aonw_server_client && dart analyze --fatal-infos --fatal-warnings',
      ),
      'server-analyze': (
        'server-dependencies',
        'cd server && dart analyze --fatal-infos --fatal-warnings',
      ),
    };
    const testTargets = {
      'flutter-test': ('flutter-analyze', 'flutter test --no-pub'),
      'core-test': ('core-analyze', 'cd packages/aonw_core && dart test'),
      'client-test': (
        'client-analyze',
        'cd packages/aonw_server_client && dart test',
      ),
      'server-test': ('server-analyze', 'cd server && dart test'),
    };
    const coverageReportTargets = {
      'flutter-coverage-report': (
        ['root-dependencies', 'coverage-directory'],
        "@flutter test --no-pub --concurrency=1 --coverage --coverage-package='^aonw\$\$' --coverage-path=\"\$(CURDIR)/coverage/root.lcov.info\" --reporter=failures-only",
      ),
      'core-coverage-report': (
        ['core-dependencies', 'coverage-directory'],
        "@cd packages/aonw_core && dart test --concurrency=1 --coverage-package='^aonw_core\$\$' --coverage-path=\"\$(CURDIR)/coverage/core.lcov.info\" --reporter=failures-only",
      ),
      'server-coverage-report': (
        ['server-dependencies', 'coverage-directory'],
        "@cd server && dart test --concurrency=1 --coverage-package='^aonw_server\$\$' --coverage-path=\"\$(CURDIR)/coverage/server.lcov.info\" --reporter=failures-only",
      ),
    };
    const focusedCoverageTargets = {
      'flutter-coverage': (
        'flutter-coverage-report',
        '@dart run tool/check_coverage.dart check --scope root --base-ref '
            '"\$(COVERAGE_BASE_REF)" --ratchet-ref '
            '"\$(COVERAGE_RATCHET_REF)"',
      ),
      'core-coverage': (
        'core-coverage-report',
        '@dart run tool/check_coverage.dart check --scope core --base-ref '
            '"\$(COVERAGE_BASE_REF)" --ratchet-ref '
            '"\$(COVERAGE_RATCHET_REF)"',
      ),
      'server-coverage': (
        'server-coverage-report',
        '@dart run tool/check_coverage.dart check --scope server --base-ref '
            '"\$(COVERAGE_BASE_REF)" --ratchet-ref '
            '"\$(COVERAGE_RATCHET_REF)"',
      ),
    };
    for (final entry in dependencyTargets.entries) {
      final target = _makeTarget(makefile, entry.key);
      expect(target.prerequisites, [entry.value.$1], reason: entry.key);
      expect(target.recipes, ['@${entry.value.$2}'], reason: entry.key);
    }
    for (final entry in analyzerTargets.entries) {
      final target = _makeTarget(makefile, entry.key);
      expect(target.prerequisites, [entry.value.$1], reason: entry.key);
      expect(target.recipes, ['@${entry.value.$2}'], reason: entry.key);
    }
    for (final entry in testTargets.entries) {
      final target = _makeTarget(makefile, entry.key);
      expect(target.prerequisites, [entry.value.$1], reason: entry.key);
      expect(target.recipes, ['@${entry.value.$2}'], reason: entry.key);
    }
    for (final entry in coverageReportTargets.entries) {
      final target = _makeTarget(makefile, entry.key);
      expect(target.prerequisites, entry.value.$1, reason: entry.key);
      expect(target.recipes, [
        if (entry.key == 'flutter-coverage-report')
          '@rm -rf "\$(CURDIR)/build/test_cache"',
        entry.value.$2,
      ], reason: entry.key);
    }
    for (final entry in focusedCoverageTargets.entries) {
      final target = _makeTarget(makefile, entry.key);
      expect(target.prerequisites, [entry.value.$1], reason: entry.key);
      expect(target.recipes, [entry.value.$2], reason: entry.key);
    }
    expect(
      _makeTarget(makefile, 'dependencies'),
      const _MakeTarget(
        prerequisites: [
          'root-dependencies',
          'core-dependencies',
          'client-dependencies',
          'server-dependencies',
        ],
      ),
    );
    expect(
      _makeTarget(makefile, 'analyze'),
      const _MakeTarget(
        prerequisites: [
          'flutter-analyze',
          'core-analyze',
          'client-analyze',
          'server-analyze',
        ],
      ),
    );
    expect(_makeTarget(makefile, 'format-check').prerequisites, [
      'dependencies',
    ]);
    expect(_makeTarget(makefile, 'ci').prerequisites, [
      'generated-code-check',
      'format-check',
      'analyze',
      'architecture-check',
      'mutation-check',
      'coverage-check',
      'client-test',
    ]);
    expect(
      _makeTarget(makefile, 'coverage'),
      const _MakeTarget(prerequisites: ['coverage-check']),
    );
    expect(_makeTarget(makefile, 'coverage-directory').recipes, [
      '@mkdir -p coverage',
    ]);
    expect(
      _makeTarget(makefile, 'coverage-reports'),
      const _MakeTarget(
        prerequisites: [
          'flutter-coverage-report',
          'core-coverage-report',
          'server-coverage-report',
        ],
      ),
    );
    expect(
      _makeTarget(makefile, 'coverage-check'),
      const _MakeTarget(
        prerequisites: ['coverage-reports'],
        recipes: [
          '@dart run tool/check_coverage.dart check --base-ref '
              '"\$(COVERAGE_BASE_REF)" --ratchet-ref '
              '"\$(COVERAGE_RATCHET_REF)"',
        ],
      ),
    );
    expect(
      _makeTarget(makefile, 'coverage-snapshot'),
      const _MakeTarget(
        prerequisites: ['coverage-reports'],
        recipes: [
          '@dart run tool/check_coverage.dart snapshot > '
              '"\$(COVERAGE_SNAPSHOT_PATH)"',
          '@echo "Wrote coverage baseline candidate to '
              '\$(COVERAGE_SNAPSHOT_PATH)"',
        ],
      ),
    );
    final phonyTargets = _makeTarget(makefile, '.PHONY').prerequisites.toSet();
    expect(
      phonyTargets,
      containsAll({
        'dependencies',
        'analyze',
        ...dependencyTargets.keys,
        ...analyzerTargets.keys,
        ...testTargets.keys,
        ...coverageReportTargets.keys,
        ...focusedCoverageTargets.keys,
        'coverage',
        'coverage-directory',
        'coverage-reports',
        'coverage-check',
        'coverage-snapshot',
      }),
    );
    expect(
      makefile
          .split('\n')
          .where((line) => line.startsWith('COVERAGE_BASE_REF'))
          .toList(),
      ['COVERAGE_BASE_REF ?= origin/main'],
    );
    expect(
      makefile
          .split('\n')
          .where((line) => line.startsWith('COVERAGE_RATCHET_REF'))
          .toList(),
      ['COVERAGE_RATCHET_REF ?= @{upstream}'],
    );
    expect(
      makefile
          .split('\n')
          .where((line) => line.startsWith('COVERAGE_SNAPSHOT_PATH'))
          .toList(),
      ['COVERAGE_SNAPSHOT_PATH ?= /tmp/aonw-coverage-baseline.json'],
    );
    expect(
      RegExp(r'^\s*\.IGNORE\s*:', multiLine: true).hasMatch(makefile),
      isFalse,
    );
    expect(
      makefile.split('\n').where((line) => line.startsWith('SHELL')).toList(),
      ['SHELL := /bin/sh'],
    );
    expect(
      RegExp(r'\b(?:flutter|dart) analyze\b').allMatches(makefile),
      hasLength(4),
    );
    final workflow = _loadMap('.github/workflows/ci.yml');
    final jobs = _asMap(workflow['jobs'], 'CI jobs');
    final qualityGate = _asMap(jobs['quality-gate'], 'CI quality-gate');
    expect(workflow.containsKey('defaults'), isFalse);
    expect(qualityGate.containsKey('defaults'), isFalse);
    expect(qualityGate.containsKey('continue-on-error'), isFalse);
    final qualityEnvironment = _asMap(
      qualityGate['env'],
      'CI quality-gate.env',
    );
    expect(_keys(qualityEnvironment), {
      'ARCHITECTURE_RATCHET_REF',
      'COVERAGE_BASE_REF',
      'COVERAGE_RATCHET_REF',
    });
    expect(
      qualityEnvironment,
      containsPair(
        'COVERAGE_BASE_REF',
        r"${{ github.event_name == 'pull_request' && github.event.pull_request.base.sha || github.ref_name == 'dev' && 'origin/main' || github.event.before }}",
      ),
    );
    expect(
      qualityEnvironment,
      containsPair(
        'COVERAGE_RATCHET_REF',
        r"${{ github.event_name == 'pull_request' && github.event.pull_request.base.sha || github.event.before }}",
      ),
    );
    final strategy = _asMap(qualityGate['strategy'], 'CI strategy');
    final matrix = _asMap(strategy['matrix'], 'CI matrix');
    expect(_keys(matrix), {'include'});
    final rows = _mapList(matrix['include'], 'CI matrix.include');
    final normalizedRows = rows
        .map(
          (row) => <String, Object?>{
            for (final key in row.keys.cast<String>()) key: row[key],
          },
        )
        .toList();
    expect(normalizedRows, const [
      {
        'package': 'root',
        'analyze': 'make --no-print-directory flutter-analyze',
        'test': 'make --no-print-directory flutter-coverage',
        'format': 'make --no-print-directory format-check',
      },
      {
        'package': 'core',
        'analyze': 'make --no-print-directory core-analyze',
        'test': 'make --no-print-directory core-coverage',
        'format': '',
      },
      {
        'package': 'server_client',
        'analyze': 'make --no-print-directory client-analyze',
        'test': 'make --no-print-directory client-test',
        'format': '',
      },
      {
        'package': 'server',
        'analyze': 'make --no-print-directory server-analyze',
        'test': 'make --no-print-directory server-coverage',
        'format': '',
      },
    ]);

    final steps = _mapList(qualityGate['steps'], 'CI quality-gate.steps');
    expect(
      steps.where((step) => step.containsKey('working-directory')),
      isEmpty,
    );
    final checkoutStep = steps.singleWhere(
      (step) => step['name'] == 'Checkout repository',
    );
    expect(
      _asMap(checkoutStep['with'], 'CI checkout.with'),
      containsPair('fetch-depth', 0),
    );
    final analyzeStep = steps.singleWhere((step) => step['name'] == 'Analyze');
    expect(_keys(analyzeStep), {'name', 'run'});
    expect(analyzeStep, containsPair('run', r'${{ matrix.analyze }}'));
    final testStep = steps.singleWhere((step) => step['name'] == 'Test');
    expect(_keys(testStep), {'name', 'run'});
    expect(testStep, containsPair('run', r'${{ matrix.test }}'));
    expect(steps.any((step) => step['name'] == 'Get dependencies'), isFalse);
  });

  test('Make propagates recipe failures instead of masking them globally', () {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'aonw-make-failure-guard-',
    );
    addTearDown(() => temporaryDirectory.deleteSync(recursive: true));
    final failingTarget = File('${temporaryDirectory.path}/failure.mk')
      ..writeAsStringSync('__lint_guard_failure:\n\t@false\n');

    final result = Process.runSync('make', [
      '--no-print-directory',
      '-f',
      'Makefile',
      '-f',
      failingTarget.path,
      '__lint_guard_failure',
    ]);

    expect(
      result.exitCode,
      isNot(0),
      reason:
          'The repository Makefile masked a failing recipe.\n'
          'stdout:\n${result.stdout}\n'
          'stderr:\n${result.stderr}',
    );
  });

  test('static-analysis contract is documented for contributors', () {
    final policy = File('docs/static-analysis.md').readAsStringSync();
    expect(policy, contains(_basePath));
    expect(policy, contains('make analyze'));
    expect(policy, contains('pub get --enforce-lockfile'));
    expect(policy, contains('server/**'));
    expect(policy, contains('routing boundary'));
    expect(policy, contains('make server-analyze'));
    expect(policy, contains('lib/src/protocol/**'));
    expect(policy, contains('lib/src/generated/**'));

    for (final entry in const {
      'README.md': 'docs/static-analysis.md',
      'CONTRIBUTING.md': 'docs/static-analysis.md',
      'docs/README.md': 'static-analysis.md',
    }.entries) {
      expect(
        File(entry.key).readAsStringSync(),
        contains(entry.value),
        reason: entry.key,
      );
    }
  });
}

final class _LeafProfile {
  const _LeafProfile({
    required this.includes,
    this.analyzerErrors,
    this.excludes,
  });

  final List<String> includes;
  final Map<String, String>? analyzerErrors;
  final Set<String>? excludes;

  bool get hasAnalyzerOptions => analyzerErrors != null || excludes != null;
}

final class _MakeTarget {
  const _MakeTarget({required this.prerequisites, this.recipes = const []});

  final List<String> prerequisites;
  final List<String> recipes;

  @override
  bool operator ==(Object other) =>
      other is _MakeTarget &&
      _listEquals(prerequisites, other.prerequisites) &&
      _listEquals(recipes, other.recipes);

  @override
  int get hashCode => Object.hashAll([...prerequisites, null, ...recipes]);

  @override
  String toString() =>
      '_MakeTarget(prerequisites: $prerequisites, recipes: $recipes)';
}

YamlMap _loadMap(String path) {
  final value = loadYaml(File(path).readAsStringSync());
  return _asMap(value, path);
}

YamlMap _asMap(Object? value, String description) {
  expect(value, isA<YamlMap>(), reason: description);
  return value! as YamlMap;
}

YamlMap _optionalMap(Object? value) =>
    value == null ? YamlMap() : _asMap(value, 'map');

Set<String> _keys(YamlMap map) => map.keys.cast<String>().toSet();

List<String> _stringList(Object? value, String description) {
  expect(value, isA<YamlList>(), reason: description);
  return (value! as YamlList).cast<String>().toList();
}

List<YamlMap> _mapList(Object? value, String description) {
  expect(value, isA<YamlList>(), reason: description);
  return (value! as YamlList).map((item) => _asMap(item, description)).toList();
}

Set<String> _gitPaths(List<String> pathspecs) {
  final result = Process.runSync('git', [
    'ls-files',
    '--cached',
    '--others',
    '--exclude-standard',
    '--',
    ...pathspecs,
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return (result.stdout as String)
      .split('\n')
      .where((path) => path.isNotEmpty)
      .toSet();
}

String _analysisOptionsForManifest(String manifest) {
  if (manifest == 'pubspec.yaml') return 'analysis_options.yaml';
  const manifestName = 'pubspec.yaml';
  expect(manifest.endsWith(manifestName), isTrue, reason: manifest);
  return '${manifest.substring(0, manifest.length - manifestName.length)}'
      'analysis_options.yaml';
}

_MakeTarget _makeTarget(String makefile, String name) {
  final lines = makefile.split('\n');
  final headerPattern = RegExp('^${RegExp.escape(name)}:\\s*(.*)\$');
  final indexes = <int>[];
  for (var index = 0; index < lines.length; index++) {
    if (headerPattern.hasMatch(lines[index])) indexes.add(index);
  }
  expect(
    indexes,
    hasLength(1),
    reason: 'Expected exactly one Make target: $name',
  );

  final index = indexes.single;
  final header = headerPattern.firstMatch(lines[index])!;
  final rawPrerequisites = header.group(1)!.trim();
  final prerequisites = rawPrerequisites.isEmpty
      ? <String>[]
      : rawPrerequisites.split(RegExp(r'\s+'));
  final recipes = <String>[];
  for (var lineIndex = index + 1; lineIndex < lines.length; lineIndex++) {
    final line = lines[lineIndex];
    if (!line.startsWith('\t')) break;
    recipes.add(line.substring(1));
  }
  return _MakeTarget(prerequisites: prerequisites, recipes: recipes);
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
