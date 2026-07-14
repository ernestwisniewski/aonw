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
    const expectedDefaultRoles = {
      'client_lib': 'production',
      'client_test': 'test',
      'core_lib': 'production',
      'core_test': 'test',
      'core_tool': 'tool',
      'root_lib': 'production',
      'root_test': 'test',
      'root_tool': 'tool',
      'server_bin': 'production',
      'server_lib': 'production',
      'server_test': 'test',
      'vendor_sign_in_with_apple': 'production',
    };
    const expectedRoles = {
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
    };

    expect(ArchitecturePolicy.schema, 2);
    expect(policy.enforcedSince, '601d2e9cfb523dd367443662a4f298bd065a77ef');
    expect(policy.migration.fromSchema, 1);
    expect(
      policy.migration.policySha256,
      '50dff92489debbc785a6d93b0fd2e576c5f2d4a27737961edc9d92a3f1292dcf',
    );
    expect(
      policy.migration.baselineSha256,
      '75d210a1c52e3da6b800adc3d096cd775087dc4a5f86ce2b89e72e9d855e87b1',
    );
    expect(policy.migration.legacyFileTargets, hasLength(51));
    expect(policy.migration.legacyFileTargets.values.toSet(), {350});
    expect(
      policy.migration.legacyFileTargets.keys,
      containsAll([
        'lib/developer/assets_editor_screen.dart',
        'lib/editor/engine/editor_grid.dart',
        'lib/game/presentation/widgets/hud/combat/hud_combat_preview.dart',
        'lib/menu/menu_route_shell.dart',
      ]),
    );
    expect(policy.scopes.keys.toSet(), expectedRoots.keys.toSet());
    expect({
      for (final entry in policy.roles.entries) entry.key: entry.value.toJson(),
    }, expectedRoles);
    expect({
      for (final entry in policy.scopes.entries)
        entry.key: entry.value.defaultRole,
    }, expectedDefaultRoles);
    expect(
      {
        for (final entry in policy.scopes.entries)
          if (entry.value.roleAssignments.isNotEmpty)
            entry.key: entry.value.roleAssignments,
      },
      {
        'root_lib': {
          'flame_rendering': [
            'lib/editor/engine/',
            'lib/game/presentation/engine/',
            'lib/map/rendering/',
          ],
        },
      },
    );
    expect(policy.buildRunnerScopes, ['core_lib', 'root_lib']);
    for (final entry in expectedRoots.entries) {
      final scope = policy.scopes[entry.key]!;
      expect(scope.sourceRoot, entry.value, reason: entry.key);
    }

    final root = policy.scopes['root_lib']!;
    for (final path in [
      'lib/editor/engine/world_editor.dart',
      'lib/game/presentation/engine/game_world.dart',
      'lib/map/rendering/map_renderer.dart',
    ]) {
      expect(root.roleFor(path).name, 'flame_rendering', reason: path);
    }
    for (final path in [
      'lib/editor/editor_screen.dart',
      'lib/game/application/use_cases/start_game.dart',
      'lib/map/widgets/map_widget.dart',
    ]) {
      expect(root.roleFor(path).name, 'production', reason: path);
    }

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
      'performance-check',
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
      final normalizedPolicy = policy.toLowerCase();
      expect(policy, contains('make architecture'));
      expect(policy, contains('make architecture-snapshot'));
      expect(normalizedPolicy, contains('per-file overrides'));
      expect(normalizedPolicy, contains('inline suppressions'));
      for (final term in [
        'schema 2',
        'production',
        'test',
        'tool',
        'flame',
        'rendering',
        'callable',
        'nesting',
        'cyclomatic',
        'cognitive',
      ]) {
        expect(normalizedPolicy, contains(term), reason: term);
      }
      expect(normalizedPolicy, isNot(contains('remain future policy work')));

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
