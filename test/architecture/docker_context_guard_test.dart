import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final dockerignore = File('.dockerignore').readAsStringSync();
  final dockerignoreRules = dockerignore
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toList();
  final makefile = File('Makefile').readAsStringSync();

  test('server image context is default-deny with exact production inputs', () {
    final rules = dockerignoreRules;

    expect(rules.first, '**');
    expect(rules, isNot(contains('!server/**')));
    expect(rules, isNot(contains('!packages/aonw_core/**')));
    expect(rules, isNot(contains('!assets/**')));
    expect(
      rules,
      containsAll([
        'server/**',
        'server/config/**',
        'packages/**',
        'packages/aonw_core/**',
        'assets/**',
      ]),
    );
    expect(
      rules.where((rule) => rule.startsWith('!')).toList(),
      equals(const [
        '!server/',
        '!server/pubspec.yaml',
        '!server/pubspec.lock',
        '!server/bin/',
        '!server/bin/**',
        '!server/lib/',
        '!server/lib/**',
        '!server/config/',
        '!server/config/development.yaml',
        '!server/config/staging.yaml',
        '!server/config/production.yaml',
        '!server/config/test.yaml',
        '!server/migrations/',
        '!server/migrations/**',
        '!server/docker-entrypoint.sh',
        '!packages/',
        '!packages/aonw_core/',
        '!packages/aonw_core/pubspec.yaml',
        '!packages/aonw_core/pubspec.lock',
        '!packages/aonw_core/lib/',
        '!packages/aonw_core/lib/**',
        '!assets/',
        '!assets/maps/',
        '!assets/maps/**',
        '!server/migrations/*/definition.sql',
        '!server/migrations/*/migration.sql',
      ]),
    );
  });

  test('secret and backup denies override every broad allow', () {
    final rules = dockerignoreRules;
    const requiredDenies = [
      '**/.env',
      '**/.env.*',
      '**/*.env',
      '**/*.env.*',
      '**/.envrc',
      '**/.direnv/**',
      '**/*.log',
      '**/.DS_Store',
      '**/passwords*.yaml',
      '**/.ssh/**',
      '**/.aws/**',
      '**/id_dsa*',
      '**/*.ppk',
      '**/*.pkcs8',
      '**/*.pem',
      '**/*.key',
      '**/*.p8',
      '**/*.p12',
      '**/*.pfx',
      '**/*.jks',
      '**/*.keystore',
      '**/*.crt',
      '**/*.cer',
      '**/*credentials*.json',
      '**/*credentials*.yaml',
      '**/*service-account*.json',
      '**/*service-account*.yml',
      '**/backups/**',
      '**/*.backup',
      '**/*.backup.*',
      '**/*.dump',
      '**/*.dump.*',
      '**/*.db',
      '**/*.sqlite3',
      '**/*.sql',
      '**/*.sql.*',
      '**/*.7z',
    ];

    for (final rule in requiredDenies) {
      expect(rules, contains(rule), reason: rule);
    }

    final sqlDeny = rules.lastIndexOf('**/*.sql');
    final definitionAllow = rules.lastIndexOf(
      '!server/migrations/*/definition.sql',
    );
    final migrationAllow = rules.lastIndexOf(
      '!server/migrations/*/migration.sql',
    );
    expect(definitionAllow, greaterThan(sqlDeny));
    expect(migrationAllow, greaterThan(sqlDeny));

    for (final rule in requiredDenies.where((rule) => rule != '**/*.sql')) {
      expect(
        rules.lastIndexOf(rule),
        greaterThan(migrationAllow),
        reason: rule,
      );
    }
  });

  test('BuildKit context probe is part of deployment validation', () {
    final guard = File('tool/check_docker_context.sh');

    expect(guard.existsSync(), isTrue);
    final source = guard.readAsStringSync();
    expect(source, contains('docker buildx build'));
    expect(source, contains('git -C "\${repo_root}" ls-files --error-unmatch'));
    expect(File('server/Dockerfile.dockerignore').existsSync(), isFalse);
    expect(source, contains('server/Dockerfile.dockerignore'));
    expect(makefile, contains('docker-context-check:'));
    expect(makefile, contains('infra-config-check: docker-context-check'));
  });

  test('long-lived dev branch receives CI and vulnerability scans', () {
    final ci = File('.github/workflows/ci.yml').readAsStringSync();
    final osv = File('.github/workflows/osv-scanner.yml').readAsStringSync();

    expect(_eventBranches(ci, 'push'), containsAll(['main', 'dev']));
    for (final event in const ['pull_request', 'merge_group', 'push']) {
      expect(
        _eventBranches(osv, event),
        containsAll(['main', 'dev']),
        reason: event,
      );
    }
  });
}

Set<String> _eventBranches(String source, String event) {
  final lines = source.split('\n');
  final eventStart = lines.indexOf('  $event:');
  expect(eventStart, greaterThanOrEqualTo(0), reason: event);

  final branches = <String>{};
  var readingBranches = false;
  for (var index = eventStart + 1; index < lines.length; index++) {
    final line = lines[index];
    if (line.isNotEmpty && !line.startsWith('    ')) break;
    if (line == '    branches:') {
      readingBranches = true;
      continue;
    }
    if (!readingBranches) continue;

    final match = RegExp(r'^      - (.+)$').firstMatch(line);
    if (match == null) break;
    branches.add(match.group(1)!);
  }
  return branches;
}
