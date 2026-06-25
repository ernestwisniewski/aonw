import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Layer boundaries', () {
    test(
      'game domain does not depend on outer game layers or UI frameworks',
      () {
        expect(
          _violations(
            roots: const ['lib/game/domain'],
            disallowed: const [
              _ImportRule.dartIo,
              _ImportRule.dartMath,
              _ImportRule.frameworks,
              _ImportRule.pathProvider,
              _ImportRule.sharedPreferences,
              _ImportRule.gameApplication,
              _ImportRule.gameInfrastructure,
              _ImportRule.gamePresentation,
            ],
          ),
          isEmpty,
        );
      },
    );

    test('game domain does not read wall-clock time directly', () {
      expect(
        _textViolations(
          roots: const ['lib/game/domain'],
          disallowed: const [_TextRule.dateTimeNow],
        ),
        isEmpty,
      );
    });

    test('game layer uses clock port outside SystemClock', () {
      expect(
        _textViolations(
          roots: const ['lib/game'],
          disallowed: const [_TextRule.dateTimeNow],
          allowedPaths: const {
            'lib/game/infrastructure/system/system_clock.dart',
          },
        ),
        isEmpty,
      );
    });

    test('game layer uses GameLogger instead of debugPrint', () {
      expect(
        _textViolations(
          roots: const ['lib/game'],
          disallowed: const [_TextRule.debugPrint],
        ),
        isEmpty,
      );
    });

    test(
      'game application does not depend on infrastructure or presentation',
      () {
        expect(
          _violations(
            roots: const ['lib/game/application'],
            disallowed: const [
              _ImportRule.dartIo,
              _ImportRule.frameworks,
              _ImportRule.gameInfrastructure,
              _ImportRule.gamePresentation,
            ],
          ),
          isEmpty,
        );
      },
    );

    test('game infrastructure does not depend on presentation', () {
      expect(
        _violations(
          roots: const ['lib/game/infrastructure'],
          disallowed: const [_ImportRule.gamePresentation],
        ),
        isEmpty,
      );
    });

    test(
      'game presentation imports infrastructure only from repository providers',
      () {
        expect(
          _violations(
            roots: const ['lib/game/presentation'],
            disallowed: const [_ImportRule.gameInfrastructure],
            allowedPaths: const {
              'lib/game/presentation/providers/repository_providers.dart',
            },
          ),
          isEmpty,
        );
      },
    );

    test('api layer does not depend on game infrastructure', () {
      expect(
        _violations(
          roots: const ['lib/api'],
          disallowed: const [_ImportRule.gameInfrastructure],
        ),
        isEmpty,
      );
    });

    test('map domain does not depend on game or UI frameworks', () {
      expect(
        _violations(
          roots: const ['lib/map/domain'],
          disallowed: const [_ImportRule.frameworks, _ImportRule.gameLayer],
        ),
        isEmpty,
      );
    });

    test('aonw_core stays Dart-only and independent of Flutter app code', () {
      expect(
        _violations(
          roots: const ['packages/aonw_core/lib'],
          disallowed: const [
            _ImportRule.frameworks,
            _ImportRule.flutterApp,
            _ImportRule.serverRuntimePackage,
            _ImportRule.serverpodRuntime,
          ],
        ),
        isEmpty,
      );
    });

    test('Flutter app does not import the Serverpod server package', () {
      expect(
        _violations(
          roots: const ['lib', 'test'],
          disallowed: const [_ImportRule.serverRuntimePackage],
        ),
        isEmpty,
      );
    });

    test(
      'generated Serverpod client stays client-side and app independent',
      () {
        expect(
          _violations(
            roots: const ['packages/aonw_server_client/lib'],
            disallowed: const [
              _ImportRule.frameworks,
              _ImportRule.flutterApp,
              _ImportRule.serverRuntimePackage,
            ],
          ),
          isEmpty,
        );
      },
    );

    test('server does not import client or Flutter app packages', () {
      expect(
        _violations(
          roots: const ['server/lib'],
          disallowed: const [
            _ImportRule.flutterApp,
            _ImportRule.generatedServerClient,
          ],
        ),
        isEmpty,
      );
    });
  });
}

List<String> _violations({
  required List<String> roots,
  required List<_ImportRule> disallowed,
  Set<String> allowedPaths = const {},
}) {
  final violations = <String>[];
  for (final file in roots.expand(_dartFiles)) {
    final relativePath = _relativePath(file.path);
    if (allowedPaths.contains(relativePath)) continue;
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final uri = _importUri(lines[i]);
      if (uri == null) continue;
      for (final rule in disallowed) {
        if (rule.matches(uri)) {
          violations.add('$relativePath:${i + 1} ${rule.message}: $uri');
        }
      }
    }
  }
  return violations;
}

List<String> _textViolations({
  required List<String> roots,
  required List<_TextRule> disallowed,
  Set<String> allowedPaths = const {},
}) {
  final violations = <String>[];
  for (final file in roots.expand(_dartFiles)) {
    final relativePath = _relativePath(file.path);
    if (allowedPaths.contains(relativePath)) continue;
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final rule in disallowed) {
        if (rule.matches(line)) {
          violations.add('$relativePath:${i + 1} ${rule.message}');
        }
      }
    }
  }
  return violations;
}

Iterable<File> _dartFiles(String root) {
  final directory = Directory(root);
  if (!directory.existsSync()) return const [];
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart'));
}

String? _importUri(String line) {
  final match = RegExp(
    r'''^\s*(import|export)\s+['"]([^'"]+)['"]''',
  ).firstMatch(line);
  return match?.group(2);
}

String _relativePath(String path) {
  final root = '${Directory.current.path}${Platform.pathSeparator}';
  return path.startsWith(root) ? path.substring(root.length) : path;
}

enum _ImportRule {
  dartIo('depends on dart:io'),
  dartMath('depends on dart:math'),
  frameworks('depends on Flutter, Flame, or Riverpod'),
  pathProvider('depends on path_provider'),
  sharedPreferences('depends on shared_preferences'),
  gameLayer('depends on game layer'),
  gameApplication('depends on game application'),
  gameInfrastructure('depends on game infrastructure'),
  gamePresentation('depends on game presentation'),
  flutterApp('depends on Flutter app package'),
  serverRuntimePackage('depends on Serverpod server package'),
  generatedServerClient('depends on generated Serverpod client package'),
  serverpodRuntime('depends on Serverpod runtime');

  final String message;

  const _ImportRule(this.message);

  bool matches(String uri) {
    return switch (this) {
      _ImportRule.dartIo => uri == 'dart:io',
      _ImportRule.dartMath => uri == 'dart:math',
      _ImportRule.frameworks => _isFrameworkUri(uri),
      _ImportRule.pathProvider => uri.startsWith('package:path_provider/'),
      _ImportRule.sharedPreferences => uri.startsWith(
        'package:shared_preferences/',
      ),
      _ImportRule.gameLayer => _isGameLayerUri(uri),
      _ImportRule.gameApplication => _isGameLayerUri(uri, 'application'),
      _ImportRule.gameInfrastructure => _isGameInfrastructureUri(uri),
      _ImportRule.gamePresentation => _isGameLayerUri(uri, 'presentation'),
      _ImportRule.flutterApp => _isFlutterAppUri(uri),
      _ImportRule.serverRuntimePackage => _isServerRuntimePackageUri(uri),
      _ImportRule.generatedServerClient => _isGeneratedServerClientUri(uri),
      _ImportRule.serverpodRuntime => _isServerpodRuntimeUri(uri),
    };
  }

  static bool _isFrameworkUri(String uri) {
    return RegExp(
      r'^package:(flutter|flame|hooks_riverpod|flutter_riverpod|riverpod|riverpod_annotation)/',
    ).hasMatch(uri);
  }

  static bool _isGameLayerUri(String uri, [String? layer]) {
    final packagePrefix = layer == null
        ? 'package:aonw/game/'
        : 'package:aonw/game/$layer/';
    final relativePrefix = layer == null ? '../game/' : '../$layer/';
    return uri.startsWith(packagePrefix) || uri.startsWith(relativePrefix);
  }

  static bool _isGameInfrastructureUri(String uri) {
    return _isGameLayerUri(uri, 'infrastructure') ||
        uri.startsWith('package:aonw/game/infrastructure/') ||
        uri.contains('/game/infrastructure/');
  }

  static bool _isFlutterAppUri(String uri) {
    return uri.startsWith('package:aonw/');
  }

  static bool _isServerRuntimePackageUri(String uri) {
    return uri.startsWith('package:aonw_server/');
  }

  static bool _isGeneratedServerClientUri(String uri) {
    return uri.startsWith('package:aonw_server_client/');
  }

  static bool _isServerpodRuntimeUri(String uri) {
    return RegExp(
      r'^package:(serverpod|serverpod_client|serverpod_auth_core_server|serverpod_auth_core_client)/',
    ).hasMatch(uri);
  }
}

enum _TextRule {
  dateTimeNow('reads DateTime.now() directly'),
  debugPrint('logs with debugPrint directly');

  final String message;

  const _TextRule(this.message);

  bool matches(String line) {
    return switch (this) {
      _TextRule.dateTimeNow => line.contains('DateTime.now()'),
      _TextRule.debugPrint => line.contains('debugPrint('),
    };
  }
}
