import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import '../../tool/mutation/baseline.dart';
import '../../tool/mutation/git_repository.dart';
import '../../tool/mutation/policy.dart';
import '../../tool/mutation/target_validator.dart';

const _policyPath = 'tool/mutation_policy.json';
const _baselinePath = 'tool/mutation_baseline.json';

void main() {
  test('mutation policy owns the reviewed critical scopes', () {
    final policy = MutationPolicy.load(_policyPath);

    expect(policy.enforcedSince, '27f179953a62186739d263ca34c331f12b5d7767');
    expect(policy.perMutantTimeoutSeconds, 90);
    expect(policy.operators, supportedMutationOperators);
    expect(policy.scopes.keys.toList(), [
      'core_combat_serializer',
      'root_unit_validator',
      'server_auth_input',
    ]);

    final expected =
        <
          String,
          ({
            String architectureScope,
            String packageRoot,
            String runner,
            String target,
            String test,
          })
        >{
          'core_combat_serializer': (
            architectureScope: 'core_lib',
            packageRoot: 'packages/aonw_core',
            runner: 'dart',
            target:
                'packages/aonw_core/lib/game/domain/combat/'
                'combat_serialization.dart',
            test: 'packages/aonw_core/test/game/combat_serialization_test.dart',
          ),
          'root_unit_validator': (
            architectureScope: 'root_lib',
            packageRoot: '.',
            runner: 'flutter',
            target: 'lib/game/domain/reducer/unit/unit_command_validator.dart',
            test: 'test/game/domain/reducer/unit_command_validator_test.dart',
          ),
          'server_auth_input': (
            architectureScope: 'server_lib',
            packageRoot: 'server',
            runner: 'dart',
            target: 'server/lib/src/auth/auth_input_validator.dart',
            test: 'server/test/auth/auth_input_validator_test.dart',
          ),
        };
    for (final entry in expected.entries) {
      final scope = policy.scopes[entry.key]!;
      expect(scope.architectureScope, entry.value.architectureScope);
      expect(scope.packageRoot, entry.value.packageRoot);
      expect(scope.runner, entry.value.runner);
      expect(scope.targetFiles, [entry.value.target]);
      expect(scope.testFiles, [entry.value.test]);
    }

    MutationTargetValidator(
      repository: MutationGitRepository(Directory.current.path),
      architecturePolicyPath: 'tool/architecture_policy.json',
    ).validate(policy);
  });

  test('mutation baseline has an exact census and no survivors', () {
    final policy = MutationPolicy.load(_policyPath);
    final baseline = MutationBaseline.load(_baselinePath, policy);

    expect(baseline.scopes.keys.toList(), policy.scopes.keys.toList());
    expect(baseline.mutantCount, 98);
    expect(baseline.survivorCount, 0);
    expect(
      baseline.scopes.map((name, scope) => MapEntry(name, scope.mutantCount)),
      {
        'core_combat_serializer': 62,
        'root_unit_validator': 7,
        'server_auth_input': 29,
      },
    );
    for (final entry in baseline.scopes.entries) {
      expect(
        entry.value.targets.keys.toList(),
        policy.scopes[entry.key]!.targetFiles,
      );
      expect(entry.value.operatorTotals.keys.toList(), policy.operators);
      expect(entry.value.mutantCount, greaterThan(0));
      expect(entry.value.survivors, isEmpty);
    }
  });

  test('Make and CI delegate to the same mutation gate', () {
    final makefile = File('Makefile').readAsStringSync();
    expect(
      _makeTarget(makefile, 'mutation'),
      const _MakeTarget(prerequisites: ['mutation-check']),
    );
    expect(
      _makeTarget(makefile, 'mutation-check'),
      const _MakeTarget(
        prerequisites: [
          'root-dependencies',
          'core-dependencies',
          'server-dependencies',
        ],
        recipes: [
          '@if [ "\$\$(uname -s 2>/dev/null || echo unknown)" = "Darwin" ]; '
              'then \\',
          '\texec caffeinate -i dart run tool/check_mutations.dart check '
              '--ratchet-ref "\$(MUTATION_RATCHET_REF)"; \\',
          'else \\',
          '\texec dart run tool/check_mutations.dart check --ratchet-ref '
              '"\$(MUTATION_RATCHET_REF)"; \\',
          'fi',
        ],
      ),
    );
    expect(
      _makeTarget(makefile, 'mutation-snapshot'),
      const _MakeTarget(
        prerequisites: [
          'root-dependencies',
          'core-dependencies',
          'server-dependencies',
        ],
        recipes: [
          '@if [ "\$\$(uname -s 2>/dev/null || echo unknown)" = "Darwin" ]; '
              'then \\',
          '\texec caffeinate -i dart run tool/check_mutations.dart snapshot '
              '> "\$(MUTATION_SNAPSHOT_PATH)"; \\',
          'else \\',
          '\texec dart run tool/check_mutations.dart snapshot > '
              '"\$(MUTATION_SNAPSHOT_PATH)"; \\',
          'fi',
          '@echo "Wrote mutation baseline candidate to '
              '\$(MUTATION_SNAPSHOT_PATH)"',
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
      containsAll({'mutation', 'mutation-check', 'mutation-snapshot'}),
    );
    expect(_singleVariable(makefile, 'MUTATION_RATCHET_REF'), '@{upstream}');
    expect(
      _singleVariable(makefile, 'MUTATION_SNAPSHOT_PATH'),
      '/tmp/aonw-mutation-baseline.json',
    );
    expect(makefile, contains('caffeinate -i dart run'));

    final workflowSource = File('.github/workflows/ci.yml').readAsStringSync();
    final workflow = loadYaml(workflowSource) as YamlMap;
    final job = (workflow['jobs'] as YamlMap)['mutation-gate'] as YamlMap;
    expect(job.keys.toSet(), {
      'name',
      'runs-on',
      'timeout-minutes',
      'env',
      'steps',
    });
    expect(job['name'], 'mutation gate');
    expect(job['runs-on'], 'ubuntu-latest');
    expect(job['timeout-minutes'], 30);
    final environment = job['env'] as YamlMap;
    expect(environment.keys.toSet(), {'MUTATION_RATCHET_REF'});
    expect(
      environment['MUTATION_RATCHET_REF'],
      r"${{ github.event_name == 'pull_request' && github.event.pull_request.base.sha || github.event.before }}",
    );

    final steps = (job['steps'] as YamlList).cast<YamlMap>();
    expect(steps, hasLength(5));
    final checkout = _step(steps, 'Checkout repository');
    expect(checkout.keys.toSet(), {'name', 'uses', 'with'});
    expect((checkout['with'] as YamlMap)['fetch-depth'], 0);
    final fetchRatchet = _step(steps, 'Fetch mutation ratchet commit');
    expect(fetchRatchet.keys.toSet(), {'name', 'run'});
    expect(
      fetchRatchet['run'],
      contains(r'git fetch --no-tags origin "$MUTATION_RATCHET_REF"'),
    );
    expect(steps.indexOf(fetchRatchet), greaterThan(steps.indexOf(checkout)));
    final flutter = _step(steps, 'Set up Flutter');
    expect((flutter['with'] as YamlMap)['flutter-version-file'], '.fvmrc');
    final check = _step(steps, 'Check critical mutation gates');
    expect(check.keys.toSet(), {'name', 'run'});
    expect(check['run'], 'make --no-print-directory mutation-check');
    expect(
      workflowSource,
      isNot(contains('dart run tool/check_mutations.dart')),
    );
  });

  test('mutation contract is documented at contributor surfaces', () {
    final documentation = File('docs/mutation-testing.md').readAsStringSync();
    expect(documentation, contains('make mutation'));
    expect(documentation, contains('make mutation-snapshot'));
    expect(documentation, contains('seven reviewed operators'));
    expect(documentation, contains('no survivors'));

    expect(
      File('README.md').readAsStringSync(),
      contains('docs/mutation-testing.md'),
    );
    expect(
      File('CONTRIBUTING.md').readAsStringSync(),
      contains('make mutation-snapshot'),
    );
    expect(
      File('docs/README.md').readAsStringSync(),
      contains('mutation-testing.md'),
    );
    expect(
      File('.github/PULL_REQUEST_TEMPLATE.md').readAsStringSync(),
      contains('`make mutation` passes'),
    );
  });
}

YamlMap _step(List<YamlMap> steps, String name) =>
    steps.singleWhere((step) => step['name'] == name);

_MakeTarget _makeTarget(String source, String name) {
  final lines = source.split('\n');
  final prefix = '$name:';
  final matches = <int>[
    for (var index = 0; index < lines.length; index++)
      if (lines[index].startsWith(prefix)) index,
  ];
  expect(matches, hasLength(1), reason: 'Make target $name');
  final prerequisites = lines[matches.single]
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
}

bool _sameList<T>(List<T> first, List<T> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
