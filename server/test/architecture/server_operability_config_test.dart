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

    test('proxy identity headers cross only the private ingress boundary', () {
      final compose =
          loadYaml(File('../compose.yml').readAsStringSync()) as YamlMap;
      final services = compose['services'] as YamlMap;
      final server = services['server'] as YamlMap;
      final cloudflared = services['cloudflared'] as YamlMap;
      final ports = (server['ports'] as YamlList).cast<String>();

      expect(
        ports,
        containsAll(const [
          r'${AONW_SERVER_BIND:-127.0.0.1}:${AONW_SERVER_PUBLIC_PORT:-8080}:${SERVERPOD_API_SERVER_PORT:-8080}',
          r'${AONW_INSIGHTS_BIND:-127.0.0.1}:${AONW_INSIGHTS_PUBLIC_PORT:-8081}:${SERVERPOD_INSIGHTS_SERVER_PORT:-8081}',
          r'${AONW_WEB_BIND:-127.0.0.1}:${AONW_WEB_PUBLIC_PORT:-8082}:${SERVERPOD_WEB_SERVER_PORT:-8082}',
        ]),
      );

      final caddyfile = File('../deploy/caddy/Caddyfile').readAsStringSync();
      final proxyBlocks = _reverseProxyBlocks(caddyfile);

      expect(caddyfile, contains('client_ip_headers CF-Connecting-IP'));
      expect(caddyfile, contains('trusted_proxies_strict'));
      final trustedProxyTokens = caddyfile
          .split('\n')
          .singleWhere(
            (line) => line.trimLeft().startsWith('trusted_proxies static '),
          )
          .trim()
          .split(RegExp(r'\s+'));
      expect(trustedProxyTokens.take(2), ['trusted_proxies', 'static']);
      expect(
        trustedProxyTokens.skip(2),
        unorderedEquals(_cloudflareProxyRanges),
      );
      expect(proxyBlocks, hasLength(4));
      for (final block in proxyBlocks) {
        expect(_hasLine(block, 'header_up -Forwarded'), isTrue, reason: block);
        expect(
          _hasLine(block, 'header_up -CF-Connecting-IP'),
          isTrue,
          reason: block,
        );
        expect(
          _hasLine(block, 'header_up X-Forwarded-For {client_ip}'),
          isTrue,
          reason: block,
        );
      }
      expect(
        cloudflared['command'],
        'tunnel --no-autoupdate --url '
        r'http://server:${SERVERPOD_API_SERVER_PORT:-8080}',
      );
      expect(cloudflared.containsKey('ports'), isFalse);
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

List<String> _reverseProxyBlocks(String source) {
  final lines = source.split('\n');
  final blocks = <String>[];

  for (var index = 0; index < lines.length; index++) {
    if (!lines[index].trimLeft().startsWith('reverse_proxy ')) continue;

    final block = <String>[lines[index]];
    var depth = _braceDelta(lines[index]);
    while (depth > 0 && index + 1 < lines.length) {
      index++;
      block.add(lines[index]);
      depth += _braceDelta(lines[index]);
    }
    blocks.add(block.join('\n'));
  }

  return blocks;
}

int _braceDelta(String line) {
  return '{'.allMatches(line).length - '}'.allMatches(line).length;
}

const _cloudflareProxyRanges = <String>{
  '173.245.48.0/20',
  '103.21.244.0/22',
  '103.22.200.0/22',
  '103.31.4.0/22',
  '141.101.64.0/18',
  '108.162.192.0/18',
  '190.93.240.0/20',
  '188.114.96.0/20',
  '197.234.240.0/22',
  '198.41.128.0/17',
  '162.158.0.0/15',
  '104.16.0.0/13',
  '104.24.0.0/14',
  '172.64.0.0/13',
  '131.0.72.0/22',
  '2400:cb00::/32',
  '2606:4700::/32',
  '2803:f800::/32',
  '2405:b500::/32',
  '2405:8100::/32',
  '2a06:98c0::/29',
  '2c0f:f248::/32',
};
