import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import '../../tool/architecture/baseline.dart';
import '../../tool/architecture/git_repository.dart';
import '../../tool/architecture/policy.dart';
import '../../tool/architecture/source_census.dart';

const _policyPath = 'tool/architecture_policy.json';
const _baselinePath = 'tool/architecture_baseline.json';

void main() {
  test('architecture policy owns every Dart source with coherent targets', () {
    final policy = ArchitecturePolicy.load(_policyPath);
    const expectedRoots = {
      'client_lib': 'packages/aonw_server_client/lib',
      'client_test': 'packages/aonw_server_client/test',
      'core_lib': 'packages/aonw_core/lib',
      'core_test': 'packages/aonw_core/test',
      'core_tool': 'packages/aonw_core/tool',
      'root_lib': 'lib',
      'root_test': 'test',
      'root_tool': 'tool',
      'server_bin': 'server/bin',
      'server_lib': 'server/lib',
      'server_test': 'server/test',
      'vendor_sign_in_with_apple': 'third_party/sign_in_with_apple/lib',
    };

    expect(policy.scopes.keys.toSet(), expectedRoots.keys.toSet());
    expect(policy.fileLineTargets, {
      'default': 500,
      'flutter_frontend': 350,
      'use_case': 180,
    });
    expect(policy.declarationLineTarget, 350);
    expect(policy.buildRunnerScopes, ['core_lib', 'root_lib']);
    for (final entry in expectedRoots.entries) {
      final scope = policy.scopes[entry.key]!;
      expect(scope.sourceRoot, entry.value, reason: entry.key);
      expect(scope.declarationLineTarget, 350, reason: entry.key);
      expect(scope.fileProfiles['default']!.isFallback, isTrue);
      expect(scope.fileProfiles['default']!.lineTarget, 500);
    }

    final root = policy.scopes['root_lib']!;
    expect(root.fileProfiles.keys.toSet(), {
      'default',
      'flutter_frontend',
      'use_case',
    });
    expect(root.fileProfiles['flutter_frontend']!.lineTarget, 350);
    expect(root.fileProfiles['flutter_frontend']!.paths, [
      'lib/app/',
      'lib/developer/',
      'lib/editor/',
      'lib/game/presentation/input/gamepad/',
      'lib/game/presentation/providers/hud/',
      'lib/game/presentation/screens/',
      'lib/game/presentation/widgets/',
      'lib/map/widgets/',
      'lib/menu/',
      'lib/shared/performance/',
      'lib/shared/widgets/',
    ]);
    expect(root.fileProfiles['use_case']!.lineTarget, 180);
    expect(root.fileProfiles['use_case']!.paths, [
      'lib/game/application/use_cases/',
    ]);

    expect(policy.scopes['client_lib']!.generatedPrefixes, [
      'packages/aonw_server_client/lib/src/protocol/',
    ]);
    expect(policy.scopes['root_lib']!.generatedPrefixes, [
      'lib/l10n/generated/',
    ]);
    expect(policy.scopes['server_lib']!.generatedPrefixes, [
      'server/lib/src/generated/',
    ]);
    expect(policy.scopes['server_test']!.generatedPrefixes, [
      'server/test/integration/test_tools/',
    ]);

    SourceCensus(
      repository: GitRepository(Directory.current.path),
      policy: policy,
    ).validateRepositoryCoverage();
    expect(
      ArchitectureBaseline.load(_baselinePath, policy).scopes.keys.toSet(),
      expectedRoots.keys.toSet(),
    );
  });

  test('one centralized gate replaces every scattered size baseline', () {
    const retiredGuards = [
      'test/architecture/widgets_max_lines_test.dart',
      'test/architecture/game_size_guard_test.dart',
      'test/architecture/engine_file_size_test.dart',
      'packages/aonw_core/test/architecture/ai_file_size_test.dart',
      'server/test/architecture/server_file_size_test.dart',
    ];

    for (final path in retiredGuards) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }
  });

  test('AST dependency, Make targets, and CI delegation cannot drift', () {
    final manifest =
        loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    expect((manifest['dev_dependencies'] as YamlMap)['analyzer'], '12.1.0');

    final lockfile =
        loadYaml(File('pubspec.lock').readAsStringSync()) as YamlMap;
    final analyzer = (lockfile['packages'] as YamlMap)['analyzer'] as YamlMap;
    final description = analyzer['description'] as YamlMap;
    expect(analyzer.keys.toSet(), {
      'dependency',
      'description',
      'source',
      'version',
    });
    expect(analyzer['dependency'], 'direct dev');
    expect(analyzer['source'], 'hosted');
    expect(analyzer['version'], '12.1.0');
    expect(description.keys.toSet(), {'name', 'sha256', 'url'});
    expect(description['name'], 'analyzer');
    expect(description['url'], 'https://pub.dev');
    expect(
      description['sha256'],
      '663efa951fb8a45e06f491223a604c93820598f20e6a99c25617a1576065e8b7',
    );

    final makefile = File('Makefile').readAsStringSync();
    expect(
      _makeTarget(makefile, 'architecture'),
      const _MakeTarget(prerequisites: ['architecture-check']),
    );
    expect(
      _makeTarget(makefile, 'architecture-check'),
      const _MakeTarget(
        prerequisites: ['root-dependencies'],
        recipes: [
          '@dart run tool/check_architecture.dart check --ratchet-ref '
              '"\$(ARCHITECTURE_RATCHET_REF)"',
        ],
      ),
    );
    expect(
      _makeTarget(makefile, 'architecture-snapshot'),
      const _MakeTarget(
        prerequisites: ['root-dependencies'],
        recipes: [
          '@dart run tool/check_architecture.dart snapshot > '
              '"\$(ARCHITECTURE_SNAPSHOT_PATH)"',
          '@echo "Wrote architecture baseline candidate to '
              '\$(ARCHITECTURE_SNAPSHOT_PATH)"',
        ],
      ),
    );
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
      _makeTarget(makefile, '.PHONY').prerequisites.toSet(),
      containsAll({
        'architecture',
        'architecture-check',
        'architecture-snapshot',
      }),
    );
    expect(
      _singleVariable(makefile, 'ARCHITECTURE_RATCHET_REF'),
      '@{upstream}',
    );
    expect(
      _singleVariable(makefile, 'ARCHITECTURE_SNAPSHOT_PATH'),
      '/tmp/aonw-architecture-baseline.json',
    );

    final workflow =
        loadYaml(File('.github/workflows/ci.yml').readAsStringSync())
            as YamlMap;
    final qualityGate =
        (workflow['jobs'] as YamlMap)['quality-gate'] as YamlMap;
    final environment = qualityGate['env'] as YamlMap;
    expect(
      environment['ARCHITECTURE_RATCHET_REF'],
      r"${{ github.event_name == 'pull_request' && github.event.pull_request.base.sha || github.event.before }}",
    );
    final steps = (qualityGate['steps'] as YamlList).cast<YamlMap>();
    final architectureStep = steps.singleWhere(
      (step) => step['name'] == 'Check architecture budgets',
    );
    expect(architectureStep.keys.toSet(), {'name', 'if', 'run'});
    expect(architectureStep['if'], "matrix.package == 'root'");
    expect(
      architectureStep['run'],
      'make --no-print-directory architecture-check',
    );
  });

  test(
    'architecture budget contract is documented at contributor surfaces',
    () {
      final policy = File('docs/architecture-budgets.md').readAsStringSync();
      expect(policy, contains('make architecture'));
      expect(policy, contains('make architecture-snapshot'));
      expect(policy, contains('180 lines'));
      expect(policy, contains('350 lines'));
      expect(policy, contains('500 lines'));
      expect(policy, contains('There are no inline'));

      expect(
        File('README.md').readAsStringSync(),
        contains('docs/architecture-budgets.md'),
      );
      expect(
        File('CONTRIBUTING.md').readAsStringSync(),
        contains('make architecture'),
      );
      expect(
        File('.github/PULL_REQUEST_TEMPLATE.md').readAsStringSync(),
        contains('`make architecture` passes'),
      );
    },
  );
}

_MakeTarget _makeTarget(String source, String name) {
  final lines = source.split('\n');
  final prefix = '$name:';
  final matches = <int>[
    for (var index = 0; index < lines.length; index++)
      if (lines[index].startsWith(prefix)) index,
  ];
  expect(matches, hasLength(1), reason: 'Make target $name');
  final header = lines[matches.single];
  final prerequisites = header
      .substring(prefix.length)
      .trim()
      .split(RegExp(r'\s+'))
      .where((value) => value.isNotEmpty)
      .toList();
  final recipes = <String>[];
  for (var index = matches.single + 1; index < lines.length; index++) {
    final line = lines[index];
    if (!line.startsWith('\t')) break;
    recipes.add(line.substring(1));
  }
  return _MakeTarget(prerequisites: prerequisites, recipes: recipes);
}

String _singleVariable(String makefile, String name) {
  final prefix = '$name ?= ';
  final lines = makefile
      .split('\n')
      .where((line) => line.startsWith(prefix))
      .toList();
  expect(lines, hasLength(1), reason: name);
  return lines.single.substring(prefix.length);
}

final class _MakeTarget {
  const _MakeTarget({required this.prerequisites, this.recipes = const []});

  final List<String> prerequisites;
  final List<String> recipes;

  @override
  bool operator ==(Object other) =>
      other is _MakeTarget &&
      _sameList(prerequisites, other.prerequisites) &&
      _sameList(recipes, other.recipes);

  @override
  int get hashCode => Object.hashAll([...prerequisites, null, ...recipes]);

  @override
  String toString() =>
      '_MakeTarget(prerequisites: $prerequisites, recipes: $recipes)';
}

bool _sameList<T>(List<T> first, List<T> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
