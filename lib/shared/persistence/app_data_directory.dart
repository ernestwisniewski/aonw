import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract final class AppDataDirectory {
  static const String appFolderName = 'aonw';

  static Future<Directory> documentsDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } on Object {
      final fallback = fallbackDirectory();
      await fallback.create(recursive: true);
      return fallback;
    }
  }

  static Directory fallbackDirectory() => Directory(
    resolveFallbackPath(
      operatingSystem: Platform.operatingSystem,
      environment: Platform.environment,
      currentDirectory: Directory.current.path,
      pathSeparator: Platform.pathSeparator,
    ),
  );

  static String resolveFallbackPath({
    required String operatingSystem,
    required Map<String, String> environment,
    required String currentDirectory,
    required String pathSeparator,
  }) {
    final home = _homeDirectory(environment);

    if (operatingSystem == 'macos') {
      if (home != null) {
        return [
          home,
          'Library',
          'Application Support',
          appFolderName,
        ].join(pathSeparator);
      }
    }

    if (operatingSystem == 'windows') {
      final appData = _nonBlankValue(environment, 'APPDATA');
      if (appData != null) {
        return [appData, appFolderName].join(pathSeparator);
      }
    }

    final xdgDataHome = _nonBlankValue(environment, 'XDG_DATA_HOME');
    if (xdgDataHome != null) {
      return [xdgDataHome, appFolderName].join(pathSeparator);
    }

    if (home != null) {
      return [home, '.local', 'share', appFolderName].join(pathSeparator);
    }

    return [currentDirectory, appFolderName].join(pathSeparator);
  }

  static String? _homeDirectory(Map<String, String> environment) =>
      _nonBlankValue(environment, 'HOME') ??
      _nonBlankValue(environment, 'USERPROFILE');

  static String? _nonBlankValue(Map<String, String> environment, String key) {
    final value = environment[key];
    return value == null || value.trim().isEmpty ? null : value;
  }
}
