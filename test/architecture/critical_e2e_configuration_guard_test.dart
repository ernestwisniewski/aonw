import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

const _localTestPath = 'test/game/local_game_persistence_flow_test.dart';
const _runnerPath = 'tool/run_serverpod_critical_e2e.sh';
const _postgresRunnerPath = 'tool/run_postgres_smoke.sh';
const _portAllocatorPath = 'tool/allocate_loopback_port_triplet.dart';
const _portAllocatorTestPath =
    'test/tool/allocate_loopback_port_triplet_test.dart';
const _scenarioPath = 'tool/serverpod_critical_e2e.dart';
const _serverPath = 'server/test/support/critical_e2e_server.dart';
const _serverConfigPath = 'server/test/support/critical_e2e_server_config.dart';
const _loopbackOverridePath =
    'server/test/support/critical_e2e_loopback_io_overrides.dart';
const _serverConfigTestPath =
    'server/test/critical_e2e_server_config_test.dart';
const _loopbackOverrideTestPath =
    'server/test/critical_e2e_loopback_io_overrides_test.dart';

void main() {
  test('critical journeys keep their canonical entry points', () {
    for (final path in const [
      _localTestPath,
      _runnerPath,
      _postgresRunnerPath,
      _portAllocatorPath,
      _portAllocatorTestPath,
      _scenarioPath,
      _serverPath,
      _serverConfigPath,
      _loopbackOverridePath,
      _serverConfigTestPath,
      _loopbackOverrideTestPath,
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }

    if (!Platform.isWindows) {
      for (final path in const [_runnerPath, _postgresRunnerPath]) {
        final executable = Process.runSync('test', ['-x', path]);
        expect(
          executable.exitCode,
          0,
          reason: '$path must be executable from Make and CI.',
        );
      }
    }
  });

  test('Make owns focused and aggregate critical E2E commands', () {
    final makefile = File('Makefile').readAsStringSync();

    expect(
      _makeTarget(makefile, 'local-game-e2e-test'),
      const _MakeTarget(
        prerequisites: ['root-dependencies'],
        recipes: [
          '@flutter test --no-pub '
              'test/game/local_game_persistence_flow_test.dart',
        ],
      ),
    );
    expect(
      _makeTarget(makefile, 'serverpod-critical-e2e-test'),
      const _MakeTarget(
        prerequisites: [
          'root-dependencies',
          'client-dependencies',
          'server-dependencies',
        ],
        recipes: [
          '@AONW_SERVERPOD_CRITICAL_E2E_PORT='
              '"\$(AONW_SERVERPOD_CRITICAL_E2E_PORT)" \\',
          '\ttool/run_serverpod_critical_e2e.sh',
        ],
      ),
    );
    expect(
      _makeTarget(makefile, 'critical-e2e-test'),
      const _MakeTarget(
        prerequisites: ['local-game-e2e-test', 'serverpod-critical-e2e-test'],
      ),
    );
    expect(
      _makeTarget(makefile, '.PHONY').prerequisites.toSet(),
      containsAll({
        'critical-e2e-test',
        'local-game-e2e-test',
        'serverpod-critical-e2e-test',
      }),
    );
    expect(
      _singleVariable(makefile, 'AONW_SERVERPOD_CRITICAL_E2E_PORT'),
      isEmpty,
    );
    final serverCoverage = _makeTarget(makefile, 'server-coverage-report');
    expect(
      serverCoverage,
      const _MakeTarget(
        prerequisites: ['server-dependencies', 'coverage-directory'],
        recipes: [
          "@cd server && dart test --concurrency=1 --coverage-package='^aonw_server\$\$' --coverage-path=\"\$(CURDIR)/coverage/server.lcov.info\" --reporter=failures-only",
        ],
      ),
    );
  });

  test('live harness fails closed around process, secrets, and database', () {
    final makefile = File('Makefile').readAsStringSync();
    final liveTarget = _makeTarget(makefile, 'serverpod-critical-e2e-test');
    final integrationTarget = _makeTarget(makefile, 'server-integration-test');
    final runner = File(_runnerPath).readAsStringSync();
    final postgresRunner = File(_postgresRunnerPath).readAsStringSync();
    final scenario = File(_scenarioPath).readAsStringSync();
    final serverEntry = File(_serverPath).readAsStringSync();
    final serverConfig = File(_serverConfigPath).readAsStringSync();
    final loopbackOverride = File(_loopbackOverridePath).readAsStringSync();

    expect(
      liveTarget.recipes.join('\n'),
      isNot(contains(r'$(SERVERPOD_TEST_DATABASE_PASSWORD)')),
    );
    expect(integrationTarget.recipes.join('\n'), contains('env -i'));
    expect(
      integrationTarget.recipes.join('\n'),
      contains(r'test_database_port="$${AONW_TEST_DATABASE_PORT:-5432}"'),
    );
    expect(
      integrationTarget.recipes.join('\n'),
      contains(r'SERVERPOD_DATABASE_PORT="$$test_database_port"'),
    );
    expect(RegExp(r'\benv -i\b').allMatches(runner), hasLength(2));
    expect(runner, contains('/dev/urandom'));
    expect(
      runner,
      contains(
        r'database_password="${AONW_TEST_DATABASE_PASSWORD:-${SERVERPOD_TEST_DATABASE_PASSWORD:-aonw_dev}}"',
      ),
    );
    expect(runner, isNot(contains(r'${SERVERPOD_PASSWORD_database:-')));
    for (final expected in const [
      r'database_port="${AONW_TEST_DATABASE_PORT:-5432}"',
      r'AONW_TEST_DATABASE_PORT="${database_port}"',
      r'SERVERPOD_DATABASE_PORT="${database_port}"',
      r'ready_nonce="$(random_secret)"',
      r'AONW_SERVERPOD_CRITICAL_E2E_READY_NONCE="${ready_nonce}"',
      'SERVERPOD_APPLY_MIGRATIONS=true',
      'SERVERPOD_APPLY_REPAIR_MIGRATION=false',
      'SERVERPOD_REDIS_ENABLED=false',
      'SERVERPOD_FUTURE_CALL_EXECUTION_ENABLED=false',
      r'grep -Fqx -- "${ready_marker}" "${server_log}"',
      "--noproxy '*'",
      '--connect-timeout 1 --max-time 1',
      r'dart run tool/allocate_loopback_port_triplet.dart',
      r'--lock-directory "${port_lock_root}"',
      r'port_locks=(',
      r'"${port_lock_root}/${base_port}.lock"',
      r'"${port_lock_root}/$((base_port + 1)).lock"',
      r'"${port_lock_root}/$((base_port + 2)).lock"',
      r'rm -f -- "${port_lock}"',
    ]) {
      expect(runner, contains(expected), reason: expected);
    }
    final portAllocation = runner.indexOf(
      'dart run tool/allocate_loopback_port_triplet.dart',
    );
    final serverStart = runner.indexOf('(\n  cd "\${repo_root}/server"');
    expect(portAllocation, isNonNegative);
    expect(serverStart, greaterThan(portAllocation));
    expect(runner, isNot(contains(r'rmdir "${port_lock_root}"')));

    final term = runner.indexOf('kill -TERM "\${server_pid}"');
    final boundedWait = runner.indexOf('attempts < 5', term);
    final kill = runner.indexOf('kill -KILL "\${server_pid}"', boundedWait);
    expect(term, isNonNegative);
    expect(boundedWait, greaterThan(term));
    expect(kill, greaterThan(boundedWait));

    for (final expected in const [
      "source.runMode == 'test'",
      "database.host == 'localhost'",
      'database.port == validatedDatabasePort',
      "database.name == 'aonw_test'",
      "database.user == 'aonw'",
      'source.redis == null',
      '!source.futureCallExecutionEnabled',
      'source.apiServer, basePort',
      'source.insightsServer, basePort + 1',
      'source.webServer, basePort + 2',
    ]) {
      expect(serverConfig, contains(expected), reason: expected);
    }

    for (final expected in const [
      "test_database='aonw_test'",
      'SERVERPOD_TEST_DATABASE must be exactly',
      r'project_name="aonw-critical-e2e-$(random_hex 8)"',
      r'postgres_password="$(random_hex 32)"',
      r'--project-name "${project_name}"',
      "export POSTGRES_DB='aonw'",
      "export POSTGRES_USER='aonw'",
      r'export POSTGRES_PASSWORD="${postgres_password}"',
      r'export SERVERPOD_DATABASE_PASSWORD="${postgres_password}"',
      "export AONW_POSTGRES_BIND='127.0.0.1'",
      "export AONW_POSTGRES_PORT='0'",
      r'published_endpoint="$("${compose[@]}" port postgres 5432)"',
      'trap cleanup EXIT',
      r'"${compose[@]}" --profile dev down --volumes --remove-orphans',
      r'AONW_TEST_DATABASE_PASSWORD="${postgres_password}"',
      r'AONW_TEST_DATABASE_PORT="${postgres_port}"',
      r'AONW_SERVERPOD_CRITICAL_E2E_PORT="${critical_e2e_port_override}"',
      "normalize_port 'AONW_SERVERPOD_CRITICAL_E2E_PORT'",
      'for _ in {1..60}; do',
      r'export PGPASSWORD="$POSTGRES_PASSWORD"',
      '-h 127.0.0.1',
      r'--profile dev logs --tail=160 postgres',
      'Refusing to replace the PostgreSQL main database',
      'env -i',
    ]) {
      expect(postgresRunner, contains(expected), reason: expected);
    }
    expect(
      postgresRunner,
      contains("normalize_port 'Published PostgreSQL port'"),
    );
    expect(postgresRunner, isNot(contains('--project-name aonw')));
    expect(postgresRunner, isNot(contains('pg_isready')));
    expect(
      postgresRunner,
      isNot(contains('dart run tool/allocate_loopback_port_triplet.dart')),
    );

    for (final expected in const [
      'IOOverrides.runWithIOOverrides',
      'CriticalE2eLoopbackIoOverrides(basePort: basePort)',
      'parseCriticalE2eDatabasePort',
      'ServerpodConfig.load',
      'validateCriticalE2eServerConfig',
      'run(const [])',
      'criticalE2eReadyMarkerPrefix',
    ]) {
      expect(serverEntry, contains(expected), reason: expected);
    }
    expect(serverEntry, isNot(contains('configOverride')));
    for (final expected in const [
      'InternetAddress.anyIPv6',
      'InternetAddress.loopbackIPv4',
      'port == _basePort + 1',
      'port == _basePort + 2',
      'v6Only || shared',
      'super.serverSocketBind',
    ]) {
      expect(loopbackOverride, contains(expected), reason: expected);
    }
    for (final expected in const [
      'NetworkInterface.list',
      'includeLoopback: false',
      'Socket.connect',
      'listener isolation:',
      'config = CriticalE2eConfig.fromArgs(args);',
      'await _CriticalE2e(config).run();',
      '_closeCriticalE2eResources(',
      'suppressErrors: true',
      'Error.throwWithStackTrace',
    ]) {
      expect(scenario, contains(expected), reason: expected);
    }
  });

  test('CI delegates the live journey to the canonical Make target', () {
    final workflowSource = File('.github/workflows/ci.yml').readAsStringSync();
    final workflow = loadYaml(workflowSource) as YamlMap;
    final job = (workflow['jobs'] as YamlMap)['server-integration'] as YamlMap;

    expect(job.keys.toSet(), {
      'name',
      'runs-on',
      'timeout-minutes',
      'services',
      'steps',
    });
    expect(job['name'], 'server integration and critical E2E');
    expect(job['runs-on'], 'ubuntu-latest');
    expect(job['timeout-minutes'], 30);

    final postgres = (job['services'] as YamlMap)['postgres'] as YamlMap;
    final postgresEnvironment = postgres['env'] as YamlMap;
    expect(postgresEnvironment['POSTGRES_DB'], 'aonw_test');
    expect(postgresEnvironment['POSTGRES_USER'], 'aonw');
    expect(postgresEnvironment['POSTGRES_PASSWORD'], 'aonw_dev');

    final steps = (job['steps'] as YamlList).cast<YamlMap>();
    final integration = _step(
      steps,
      'Run every Serverpod PostgreSQL integration smoke',
    );
    final live = _step(steps, 'Run public auth-match-command-reconnect E2E');
    expect(integration['run'], 'make server-integration-test');
    expect(live.keys.toSet(), {'name', 'env', 'run'});
    expect(
      (live['env'] as YamlMap)['SERVERPOD_TEST_DATABASE_PASSWORD'],
      'aonw_dev',
    );
    expect(live['run'], 'make serverpod-critical-e2e-test');
    expect(steps.indexOf(live), greaterThan(steps.indexOf(integration)));
    expect(workflowSource, isNot(contains(_runnerPath)));
    expect(workflowSource, isNot(contains(_scenarioPath)));
  });

  test('release PostgreSQL smoke delegates both server layers in order', () {
    final makefile = File('Makefile').readAsStringSync();
    expect(
      _makeTarget(makefile, 'release-check'),
      const _MakeTarget(
        prerequisites: [],
        recipes: [
          '@\$(MAKE) --no-print-directory ci',
          '@\$(MAKE) --no-print-directory serverpod-config-check',
          '@tool/run_postgres_smoke.sh',
        ],
      ),
    );

    final lines = File(
      'tool/run_postgres_smoke.sh',
    ).readAsLinesSync().map((line) => line.trim()).toList();
    const orderedTargets =
        'for target in server-integration-test '
        'serverpod-critical-e2e-test; do';
    const isolatedEnvironment = 'env -i \\';
    const delegatedTarget = 'make "\${target}"';

    expect(lines.where((line) => line == orderedTargets), hasLength(1));
    expect(lines.where((line) => line == isolatedEnvironment), hasLength(1));
    expect(lines.where((line) => line == delegatedTarget), hasLength(1));
    expect(
      lines.indexOf(isolatedEnvironment),
      greaterThan(lines.indexOf(orderedTargets)),
    );
    expect(
      lines.indexOf(delegatedTarget),
      greaterThan(lines.indexOf(isolatedEnvironment)),
    );
  });

  test('critical E2E contract is documented at contributor surfaces', () {
    final documentation = File('docs/critical-e2e.md').readAsStringSync();
    for (final expected in const [
      'make local-game-e2e-test',
      'make serverpod-critical-e2e-test',
      'make critical-e2e-test',
      _localTestPath,
      _scenarioPath,
      _serverPath,
      _serverConfigPath,
      _loopbackOverridePath,
      _serverConfigTestPath,
      _loopbackOverrideTestPath,
      'public HTTP and WebSocket surfaces',
      'fixed delays',
      'fresh per-run secrets',
      _portAllocatorPath,
      'cryptographic per-run nonce',
      'bounded, proxy-free',
      'fails closed',
      r'aonw@localhost:$AONW_TEST_DATABASE_PORT/aonw_test',
      'maps all three wildcard binds to IPv4 loopback',
      'uniquely named Compose project',
    ]) {
      expect(documentation, contains(expected), reason: expected);
    }

    expect(
      File('README.md').readAsStringSync(),
      contains('docs/critical-e2e.md'),
    );
    expect(
      File('CONTRIBUTING.md').readAsStringSync(),
      contains('make critical-e2e-test'),
    );
    expect(
      File('docs/README.md').readAsStringSync(),
      contains('critical-e2e.md'),
    );
    expect(
      File('.github/PULL_REQUEST_TEMPLATE.md').readAsStringSync(),
      contains('`make critical-e2e-test` passes'),
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
  final prefix = '$name ?=';
  final lines = makefile
      .split('\n')
      .where((line) => line.startsWith(prefix))
      .toList();
  expect(lines, hasLength(1), reason: name);
  return lines.single.substring(prefix.length).trimLeft();
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
