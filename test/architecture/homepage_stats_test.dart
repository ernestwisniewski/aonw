import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('homepage exposes the multiplayer statistics page', () {
    final homepage = File('deploy/homepage/index.html').readAsStringSync();
    final statsFile = File('deploy/homepage/stats/index.html');

    expect(statsFile.existsSync(), isTrue);
    expect(
      homepage,
      matches(
        RegExp(
          r'<a class="nav-link" href="/stats">\s*'
          r'<span class="platform-label">Statistics</span>',
        ),
      ),
    );

    final stats = statsFile.readAsStringSync();
    expect(stats, contains('data-page="multiplayer-stats"'));
    expect(stats, contains('/api/stats'));
    expect(stats, isNot(contains('https://api.aonw.net')));
    expect(stats, contains('data-stats-loading'));
    expect(stats, contains('data-stats-error'));
    expect(stats, isNot(contains('cache: "no-store"')));
  });

  test('stats page does not load a third-party chart runtime', () {
    final stats = File('deploy/homepage/stats/index.html').readAsStringSync();
    final lower = stats.toLowerCase();

    expect(
      RegExp(r'<script\b[^>]*\bsrc\s*=', caseSensitive: false).hasMatch(stats),
      isFalse,
    );
    for (final dependency in _thirdPartyChartDependencies) {
      expect(lower, isNot(contains(dependency)), reason: dependency);
    }
  });

  test('stats runtime handles the public API contract and UI states', () {
    late ProcessResult result;
    try {
      result = Process.runSync('node', [
        'tool/test_homepage_stats.mjs',
      ], runInShell: Platform.isWindows);
    } on ProcessException catch (error) {
      fail('Node.js is required to test the homepage stats runtime: $error');
    }

    expect(
      result.exitCode,
      0,
      reason: [
        'tool/test_homepage_stats.mjs failed.',
        if (result.stdout.toString().trim().isNotEmpty)
          'stdout:\n${result.stdout}',
        if (result.stderr.toString().trim().isNotEmpty)
          'stderr:\n${result.stderr}',
      ].join('\n'),
    );
  });

  test('homepage build stages and validates an extensionless stats route', () {
    final makefile = File('Makefile').readAsStringSync();

    expect(makefile, contains('STATS_HEALTH_URL ?= https://aonw.net/stats'));
    expect(
      makefile,
      contains('STATS_API_HEALTH_URL ?= https://aonw.net/api/stats'),
    );
    expect(makefile, contains(r'$(HOMEPAGE_SOURCE_DIR)/stats/index.html'));
    expect(
      makefile,
      contains(
        r'@cp "$(HOMEPAGE_SOURCE_DIR)/stats/index.html" '
        r'"$(HOMEPAGE_BUILD_DIR)/stats"',
      ),
    );
    expect(makefile, contains('data-page="multiplayer-stats"'));
    expect(makefile, contains('health-stats:'));
    expect(makefile, contains(r'$(MAKE) --no-print-directory health-stats'));
    expect(makefile, contains('--force-recreate --no-deps caddy'));
    expect(makefile, contains('"schemaVersion":1'));
    expect(makefile, contains('"outcomes":['));
    expect(makefile, contains('"turns":{'));
  });

  test('Caddy keeps stats, homepage, demo, and API routing isolated', () {
    final production = File('deploy/caddy/Caddyfile').readAsStringSync();
    final local = File('deploy/caddy/Caddyfile.local').readAsStringSync();

    expect(production, contains('@serverpodWeb path /auth/* /api/stats'));
    expect(production, contains('@homepageStatsApi path /api/stats'));
    expect(_occurrences(production, '/api/stats'), 2);
    expect(local, contains('@homepageStatsApi path /api/stats'));
    expect(_occurrences(local, '/api/stats'), 1);

    for (final caddyfile in [production, local]) {
      expect(caddyfile, contains('reverse_proxy {\$AONW_WEB_UPSTREAM'));
      expect(caddyfile, contains('redir /stats/ /stats 308'));
      expect(caddyfile, contains('/stats /stats/ /stats/index.html'));
      expect(caddyfile, contains('Cache-Control "no-cache, must-revalidate"'));
      expect(caddyfile, contains('Content-Type "text/html; charset=utf-8"'));
      expect(caddyfile, contains('try_files {path} {path}/index.html'));
      expect(
        caddyfile,
        isNot(contains('try_files {path} {path}/index.html /index.html')),
      );
      expect(caddyfile, isNot(contains('path /api/*')));
    }

    expect(production, contains('redir /privacy-policy/ /privacy-policy 308'));
    expect(production, contains('try_files {path} /index.html'));
  });
}

int _occurrences(String source, String pattern) =>
    pattern.allMatches(source).length;

const _thirdPartyChartDependencies = [
  'chart.js',
  'chartjs',
  'd3.js',
  'echarts',
  'highcharts',
  'plotly',
  'cdn.jsdelivr.net',
  'cdnjs.cloudflare.com',
  'unpkg.com',
];
