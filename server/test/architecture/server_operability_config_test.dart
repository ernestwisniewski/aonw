import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Server operability configuration', () {
    test('deploy waits for readiness while Docker probes liveness', () {
      final makefile = File('../Makefile').readAsStringSync();
      final dockerfile = File('Dockerfile').readAsStringSync();
      final dockerProbe = dockerfile
          .split('\n')
          .singleWhere((line) => line.trimLeft().startsWith('CMD curl'));

      expect(
        RegExp(
          r'^HEALTH_URL \?= https://api\.aonw\.net/readyz$',
          multiLine: true,
        ).hasMatch(makefile),
        isTrue,
      );
      expect(dockerProbe, contains('/livez'));
      expect(dockerProbe, isNot(contains('/readyz')));
    });

    test('database-backed modes bound session log retention', () {
      for (final mode in const [
        'development',
        'staging',
        'production',
        'test',
      ]) {
        final config = _loadConfig(mode);

        expect(
          config.sessionLogs.cleanupInterval,
          const Duration(hours: 24),
          reason: mode,
        );
        expect(
          config.sessionLogs.retentionPeriod,
          const Duration(days: 90),
          reason: mode,
        );
        expect(config.sessionLogs.retentionCount, 100000, reason: mode);
      }
    });

    test('production accepts database and Redis TLS overrides', () {
      final defaults = _loadConfig('production');
      final tls = _loadConfig(
        'production',
        environment: const {
          'SERVERPOD_DATABASE_REQUIRE_SSL': 'true',
          'SERVERPOD_REDIS_REQUIRE_SSL': 'true',
        },
      );

      expect(defaults.database!.requireSsl, isFalse);
      expect(defaults.redis!.requireSsl, isFalse);
      expect(tls.database!.requireSsl, isTrue);
      expect(tls.redis!.requireSsl, isTrue);
    });

    test('Compose and env examples expose backend TLS switches', () {
      final compose =
          loadYaml(File('../compose.yml').readAsStringSync()) as YamlMap;
      final services = compose['services'] as YamlMap;
      final server = services['server'] as YamlMap;
      final environment = server['environment'] as YamlList;

      expect(
        environment,
        contains(
          'SERVERPOD_DATABASE_REQUIRE_SSL='
          r'${SERVERPOD_DATABASE_REQUIRE_SSL:-false}',
        ),
      );
      expect(
        environment,
        contains(
          'SERVERPOD_REDIS_REQUIRE_SSL='
          r'${SERVERPOD_REDIS_REQUIRE_SSL:-false}',
        ),
      );

      for (final path in const ['../.env.example', '.env.example']) {
        final example = File(path).readAsStringSync();
        expect(
          _hasLine(example, 'SERVERPOD_DATABASE_REQUIRE_SSL=false'),
          isTrue,
          reason: path,
        );
        expect(
          _hasLine(example, 'SERVERPOD_REDIS_REQUIRE_SSL=false'),
          isTrue,
          reason: path,
        );
      }
    });
  });
}

ServerpodConfig _loadConfig(
  String mode, {
  Map<String, String> environment = const {},
}) {
  final source = File('config/$mode.yaml').readAsStringSync();
  final yaml = loadYaml(source) as YamlMap;
  return ServerpodConfig.loadFromMap(
    mode,
    'operability-test',
    const {
      'database': 'test-database-password',
      'redis': 'test-redis-password',
      'serviceSecret': 'test-service-secret-long-enough',
    },
    yaml,
    environment: environment,
  );
}

bool _hasLine(String source, String expected) {
  return source.split('\n').any((line) => line.trim() == expected);
}
