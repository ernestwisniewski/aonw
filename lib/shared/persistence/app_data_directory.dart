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

  static Directory fallbackDirectory() {
    if (Platform.isMacOS) {
      final home = _homeDirectory;
      if (home != null) {
        return Directory(
          [
            home,
            'Library',
            'Application Support',
            appFolderName,
          ].join(Platform.pathSeparator),
        );
      }
    }

    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.trim().isNotEmpty) {
        return Directory([appData, appFolderName].join(Platform.pathSeparator));
      }
    }

    final xdgDataHome = Platform.environment['XDG_DATA_HOME'];
    if (xdgDataHome != null && xdgDataHome.trim().isNotEmpty) {
      return Directory(
        [xdgDataHome, appFolderName].join(Platform.pathSeparator),
      );
    }

    final home = _homeDirectory;
    if (home != null) {
      return Directory(
        [home, '.local', 'share', appFolderName].join(Platform.pathSeparator),
      );
    }

    return Directory(
      [Directory.current.path, appFolderName].join(Platform.pathSeparator),
    );
  }

  static String? get _homeDirectory {
    final home = Platform.environment['HOME'];
    if (home != null && home.trim().isNotEmpty) return home;
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null && userProfile.trim().isNotEmpty) {
      return userProfile;
    }
    return null;
  }
}
