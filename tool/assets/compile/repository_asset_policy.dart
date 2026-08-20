import 'dart:io';

import 'package:crypto/crypto.dart';

import 'runtime_file_manifest.dart';

const String preservedLogoPath = 'assets/aonw2-logo.png';
const String preservedLogoSha256 =
    'cd16df7f831c44b5d7f72b89f7f8ded36880c6d0e24bb17f92e77f89ee9f216c';

const Set<String> _staticAssetFiles = {
  'aonw-mobile.png',
  'aonw2-logo.png',
  'logo.png',
  'fonts/Cinzel-VariableFont_wght.ttf',
  'fonts/Lato-Bold.ttf',
  'fonts/Lato-Light.ttf',
  'fonts/Lato-Regular.ttf',
  'homepage/platform-icons/android.svg',
  'homepage/platform-icons/apple.svg',
  'homepage/platform-icons/contact.svg',
  'homepage/platform-icons/devlog.svg',
  'homepage/platform-icons/github.svg',
  'homepage/platform-icons/reddit.svg',
  'homepage/platform-icons/stats.svg',
  'homepage/platform-icons/steam.svg',
  'homepage/platform-icons/web.svg',
  'main_menu/background.png',
  'sounds/attack.wav',
  'sounds/city.wav',
  'sounds/map_tile_select.wav',
  'sounds/menu_back.wav',
  'sounds/menu_click.wav',
  'sounds/move_confirm.wav',
  'sounds/music/korona1.mp3',
  'sounds/music/korona2.mp3',
  'sounds/music/kroniki1.mp3',
  'sounds/music/kroniki2.mp3',
  'sounds/music/oddech1.mp3',
  'sounds/music/oddech2.mp3',
  'sounds/music/szepty1.mp3',
  'sounds/music/szepty2.mp3',
  'sounds/nature/656124__itsthegoodstuff__nature-ambiance.mp3',
  'sounds/new_turn.wav',
  'sounds/technology.wav',
  'sounds/ui_panel_open.wav',
  'sounds/walk.wav',
};

const Set<String> _legacyPlatformAssetDirectories = {
  'android/mipmap-hdpi',
  'android/mipmap-mdpi',
  'android/mipmap-xhdpi',
  'android/mipmap-xxhdpi',
  'android/mipmap-xxxhdpi',
};

final class RepositoryAssetPolicy {
  const RepositoryAssetPolicy(this.workspace);

  final Directory workspace;

  Future<List<String>> verify() async {
    final errors = <String>[];
    if (await Directory('${workspace.path}/game_assets').exists()) {
      errors.add('legacy asset root is forbidden: game_assets');
    }
    for (final path in _legacyPlatformAssetDirectories) {
      if (await Directory('${workspace.path}/$path').exists()) {
        errors.add('legacy platform asset directory is forbidden: $path');
      }
    }
    final assets = Directory('${workspace.path}/assets');
    final expected = await _expectedFiles(assets, errors);
    final actual = await _inventory(assets, errors);
    _compareAllowlist(expected, actual.files, actual.directories, errors);
    await _verifyPreservedLogo(assets, errors);
    await _verifyNoDuplicates(actual.files, errors);
    return errors;
  }

  Future<Set<String>> _expectedFiles(
    Directory assets,
    List<String> errors,
  ) async {
    try {
      final runtime = Directory('${assets.path}/runtime');
      final manifest = await RuntimeFileManifest.load(runtime);
      return {
        ..._staticAssetFiles,
        'runtime/$runtimeManifestName',
        ...manifest.files.keys.map((path) => 'runtime/$path'),
      };
    } on Object catch (error) {
      errors.add('cannot build assets allowlist from runtime manifest: $error');
      return _staticAssetFiles;
    }
  }

  Future<_AssetInventory> _inventory(
    Directory assets,
    List<String> errors,
  ) async {
    final files = <String, File>{};
    final directories = <String>{};
    if (!await assets.exists()) {
      errors.add('assets directory is missing');
      return _AssetInventory(files, directories);
    }
    await for (final entity in assets.list(
      recursive: true,
      followLinks: false,
    )) {
      final relative = entity.path
          .substring(assets.path.length + 1)
          .replaceAll('\\', '/');
      if (entity is Link) {
        errors.add('asset symlink is forbidden: $relative');
      } else if (entity is File) {
        files[relative] = entity;
      } else if (entity is Directory) {
        directories.add(relative);
      }
    }
    return _AssetInventory(files, directories);
  }

  void _compareAllowlist(
    Set<String> expected,
    Map<String, File> actual,
    Set<String> actualDirectories,
    List<String> errors,
  ) {
    final actualPaths = actual.keys.toSet();
    final missing = expected.difference(actualPaths).toList()..sort();
    final extra = actualPaths.difference(expected).toList()..sort();
    if (missing.isNotEmpty) errors.add('missing allowed assets: $missing');
    if (extra.isNotEmpty) errors.add('unexpected assets: $extra');
    final expectedDirectories = <String>{};
    for (final path in expected) {
      final parts = path.split('/');
      for (var length = 1; length < parts.length; length++) {
        expectedDirectories.add(parts.take(length).join('/'));
      }
    }
    final extraDirectories = actualDirectories.difference(expectedDirectories);
    if (extraDirectories.isNotEmpty) {
      errors.add(
        'unexpected asset directories: ${extraDirectories.toList()..sort()}',
      );
    }
  }

  Future<void> _verifyPreservedLogo(
    Directory assets,
    List<String> errors,
  ) async {
    final logo = File('${assets.path}/aonw2-logo.png');
    if (!await logo.exists()) return;
    final digest = sha256.convert(await logo.readAsBytes()).toString();
    if (digest != preservedLogoSha256) {
      errors.add('$preservedLogoPath differs from its pinned SHA-256');
    }
  }

  Future<void> _verifyNoDuplicates(
    Map<String, File> files,
    List<String> errors,
  ) async {
    final pathsByDigest = <String, List<String>>{};
    for (final entry in files.entries) {
      final digest = sha256.convert(await entry.value.readAsBytes()).toString();
      pathsByDigest.putIfAbsent(digest, () => []).add(entry.key);
    }
    final duplicates = pathsByDigest.values
        .where((paths) => paths.length > 1)
        .map((paths) => paths..sort())
        .toList();
    if (duplicates.isNotEmpty) {
      errors.add('byte-identical assets are forbidden: $duplicates');
    }
  }
}

final class _AssetInventory {
  const _AssetInventory(this.files, this.directories);

  final Map<String, File> files;
  final Set<String> directories;
}
