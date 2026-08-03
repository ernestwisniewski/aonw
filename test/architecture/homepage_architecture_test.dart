import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('homepage exposes the interactive architecture atlas', () {
    final homepage = File('deploy/homepage/index.html').readAsStringSync();
    final architectureFile = File('deploy/homepage/architecture/index.html');

    expect(architectureFile.existsSync(), isTrue);
    expect(homepage, contains('href="/architecture"'));

    final architecture = architectureFile.readAsStringSync();
    expect(architecture, contains('data-page="architecture"'));
    expect(
      architecture,
      contains('<link rel="canonical" href="https://aonw.net/architecture">'),
    );
    expect(architecture, contains('Architecture Atlas'));
    expect(architecture, contains('data-view="overview"'));
    expect(architecture, contains('data-view="multiplayer"'));
    expect(architecture, contains('data-view="quality"'));
    expect(architecture, contains('@media (max-width: 720px)'));
    expect(architecture, contains('href="/"'));
  });

  test('architecture atlas stays self-contained', () {
    final architecture = File(
      'deploy/homepage/architecture/index.html',
    ).readAsStringSync();

    expect(
      RegExp(
        r'<script\b[^>]*\bsrc\s*=',
        caseSensitive: false,
      ).hasMatch(architecture),
      isFalse,
    );
    expect(
      RegExp(
        r'''<link\b[^>]*\brel\s*=\s*["']stylesheet["']''',
        caseSensitive: false,
      ).hasMatch(architecture),
      isFalse,
    );
  });

  test('homepage build stages and verifies the extensionless route', () {
    final makefile = File('Makefile').readAsStringSync();

    expect(
      makefile,
      contains('ARCHITECTURE_HEALTH_URL ?= https://aonw.net/architecture'),
    );
    expect(
      makefile,
      contains(r'$(HOMEPAGE_SOURCE_DIR)/architecture/index.html'),
    );
    expect(
      makefile,
      contains(
        r'@cp "$(HOMEPAGE_SOURCE_DIR)/architecture/index.html" '
        r'"$(HOMEPAGE_BUILD_DIR)/architecture"',
      ),
    );
    expect(makefile, contains('data-page="architecture"'));
    expect(makefile, contains('health-architecture:'));
    expect(
      makefile,
      contains(r'$(MAKE) --no-print-directory health-architecture'),
    );
  });

  test('Caddy serves one canonical architecture URL', () {
    for (final path in [
      'deploy/caddy/Caddyfile',
      'deploy/caddy/Caddyfile.local',
    ]) {
      final caddyfile = File(path).readAsStringSync();

      expect(
        caddyfile,
        contains('/architecture /architecture/ /architecture/index.html'),
      );
      expect(caddyfile, contains('redir /architecture/ /architecture 308'));
      expect(
        caddyfile,
        contains('redir /architecture/index.html /architecture 308'),
      );
      expect(caddyfile, contains('try_files {path} {path}/index.html'));
      expect(
        caddyfile,
        isNot(contains('try_files {path} {path}/index.html /index.html')),
      );
    }
  });

  test('README links the public architecture map', () {
    final readme = File('README.md').readAsStringSync();

    expect(
      readme,
      contains(
        '| Architecture | '
        '[Interactive map](https://aonw.net/architecture) |',
      ),
    );
  });
}
