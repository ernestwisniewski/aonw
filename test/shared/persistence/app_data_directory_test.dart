import 'package:aonw/shared/persistence/app_data_directory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDataDirectory.resolveFallbackPath', () {
    test('uses macOS Application Support under HOME', () {
      expect(
        _resolve(operatingSystem: 'macos', environment: {'HOME': '/home/me'}),
        '/home/me/Library/Application Support/aonw',
      );
    });

    test('uses USERPROFILE for macOS when HOME is unavailable', () {
      expect(
        _resolve(
          operatingSystem: 'macos',
          environment: {'USERPROFILE': '/users/me'},
        ),
        '/users/me/Library/Application Support/aonw',
      );
    });

    test('falls through to XDG on macOS without a home directory', () {
      expect(
        _resolve(
          operatingSystem: 'macos',
          environment: {'XDG_DATA_HOME': '/xdg/data'},
        ),
        '/xdg/data/aonw',
      );
    });

    test('uses APPDATA on Windows', () {
      expect(
        _resolve(
          operatingSystem: 'windows',
          environment: {'APPDATA': r'C:\Users\me\AppData\Roaming'},
          pathSeparator: r'\',
        ),
        r'C:\Users\me\AppData\Roaming\aonw',
      );
    });

    test('prefers APPDATA over other Windows fallbacks', () {
      expect(
        _resolve(
          operatingSystem: 'windows',
          environment: {
            'APPDATA': r'C:\AppData',
            'XDG_DATA_HOME': r'C:\XdgData',
            'HOME': r'C:\Home',
          },
          pathSeparator: r'\',
        ),
        r'C:\AppData\aonw',
      );
    });

    test('uses XDG_DATA_HOME when the platform-specific path is absent', () {
      expect(
        _resolve(
          operatingSystem: 'windows',
          environment: {'XDG_DATA_HOME': r'D:\XdgData'},
          pathSeparator: r'\',
        ),
        r'D:\XdgData\aonw',
      );
    });

    test('uses HOME under the local data directory after XDG fallback', () {
      expect(
        _resolve(operatingSystem: 'linux', environment: {'HOME': '/home/me'}),
        '/home/me/.local/share/aonw',
      );
    });

    test('uses USERPROFILE when HOME is absent', () {
      expect(
        _resolve(
          operatingSystem: 'linux',
          environment: {'USERPROFILE': '/users/me'},
        ),
        '/users/me/.local/share/aonw',
      );
    });

    test('prefers HOME over USERPROFILE', () {
      expect(
        _resolve(
          operatingSystem: 'linux',
          environment: {'HOME': '/home/me', 'USERPROFILE': '/users/me'},
        ),
        '/home/me/.local/share/aonw',
      );
    });

    test('uses the current directory when no environment fallback exists', () {
      expect(
        _resolve(operatingSystem: 'linux', environment: const {}),
        '/work/aonw',
      );
    });

    test('ignores empty and whitespace-only environment values', () {
      expect(
        _resolve(
          operatingSystem: 'windows',
          environment: const {
            'APPDATA': ' ',
            'XDG_DATA_HOME': '',
            'HOME': '\t',
            'USERPROFILE': '  ',
          },
          currentDirectory: r'C:\work',
          pathSeparator: r'\',
        ),
        r'C:\work\aonw',
      );
    });

    test('preserves a non-blank environment value verbatim', () {
      expect(
        _resolve(
          operatingSystem: 'linux',
          environment: const {'XDG_DATA_HOME': ' /xdg/data '},
        ),
        ' /xdg/data /aonw',
      );
    });
  });
}

String _resolve({
  required String operatingSystem,
  required Map<String, String> environment,
  String currentDirectory = '/work',
  String pathSeparator = '/',
}) => AppDataDirectory.resolveFallbackPath(
  operatingSystem: operatingSystem,
  environment: environment,
  currentDirectory: currentDirectory,
  pathSeparator: pathSeparator,
);
