import 'dart:io';

import 'asset_verifier.dart';
import 'map_texture_compiler.dart';
import 'metadata_compiler.dart';
import 'runtime_file_manifest.dart';
import 'source_manifest.dart';
import 'sprite_compiler.dart';
import 'ui_asset_compiler.dart';

final class AssetCompiler {
  const AssetCompiler({
    required this.workspace,
    required this.sources,
    required this.sourceRoot,
  });

  final Directory workspace;
  final AssetSourceManifest sources;
  final Directory sourceRoot;

  Future<void> build(Directory runtimeRoot) async {
    if (await runtimeRoot.exists()) await runtimeRoot.delete(recursive: true);
    await runtimeRoot.create(recursive: true);
    await SpriteCompiler(
      sources: sources,
      sourceRoot: sourceRoot,
      outputRoot: Directory('${runtimeRoot.path}/sprites'),
    ).compile();
    await MapTextureCompiler(
      sources: sources,
      sourceRoot: sourceRoot,
      outputRoot: Directory('${runtimeRoot.path}/maps'),
    ).compile();
    await UiAssetCompiler(
      sources: sources,
      sourceRoot: sourceRoot,
      outputRoot: Directory('${runtimeRoot.path}/ui'),
    ).compile();
    await MetadataCompiler(
      sources: sources,
      workspace: workspace,
      outputRoot: Directory('${runtimeRoot.path}/metadata'),
    ).compile();
    await RuntimeFileManifest.write(runtimeRoot: runtimeRoot, sources: sources);
    await RuntimeAssetVerifier(
      workspace: workspace,
      runtimeRoot: runtimeRoot,
      sources: sources,
      enforceRepositoryLayout: false,
    ).verify();
  }
}

final class AtomicRuntimeInstaller {
  const AtomicRuntimeInstaller({
    required this.compiler,
    required this.outputWorkspace,
  });

  final AssetCompiler compiler;
  final Directory outputWorkspace;

  Future<void> compileAndInstall() async {
    final assets = Directory('${outputWorkspace.path}/assets');
    await assets.create(recursive: true);
    final staging = await assets.createTemp('.runtime-build-');
    try {
      await compiler.build(staging);
      await _replace(staging, Directory('${assets.path}/runtime'));
    } finally {
      if (await staging.exists()) await staging.delete(recursive: true);
    }
  }

  Future<void> _replace(Directory staging, Directory target) async {
    final backup = Directory(
      '${target.parent.path}/.runtime-backup-'
      '${DateTime.now().microsecondsSinceEpoch}',
    );
    final hadTarget = await target.exists();
    if (hadTarget) await target.rename(backup.path);
    try {
      await staging.rename(target.path);
      if (await backup.exists()) await backup.delete(recursive: true);
    } catch (_) {
      if (!await target.exists() && await backup.exists()) {
        await backup.rename(target.path);
      }
      rethrow;
    }
  }
}

final class RuntimeReproducer {
  const RuntimeReproducer({
    required this.compiler,
    required this.expectedRuntime,
  });

  final AssetCompiler compiler;
  final Directory expectedRuntime;

  Future<void> verify() async {
    final temporary = await Directory.systemTemp.createTemp(
      'aonw-assets-reproduce-',
    );
    try {
      final actual = Directory('${temporary.path}/assets/runtime');
      await compiler.build(actual);
      await RuntimeDirectoryComparator().compare(expectedRuntime, actual);
    } finally {
      await temporary.delete(recursive: true);
    }
  }
}

final class RuntimeDirectoryComparator {
  Future<void> compare(Directory expected, Directory actual) async {
    final expectedFiles = await _files(expected);
    final actualFiles = await _files(actual);
    final missing =
        expectedFiles.keys.toSet().difference(actualFiles.keys.toSet()).toList()
          ..sort();
    final unexpected =
        actualFiles.keys.toSet().difference(expectedFiles.keys.toSet()).toList()
          ..sort();
    final changed = <String>[];
    for (final path in expectedFiles.keys.toSet().intersection(
      actualFiles.keys.toSet(),
    )) {
      if (!await _sameFile(expectedFiles[path]!, actualFiles[path]!)) {
        changed.add(path);
      }
    }
    changed.sort();
    if (missing.isNotEmpty || unexpected.isNotEmpty || changed.isNotEmpty) {
      throw StateError(
        'Runtime assets are not reproducible; '
        'missing=$missing unexpected=$unexpected changed=$changed',
      );
    }
  }

  Future<Map<String, File>> _files(Directory root) async {
    if (!await root.exists()) return const {};
    final files = <String, File>{};
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        files[entity.path.substring(root.path.length + 1)] = entity;
      }
    }
    return files;
  }

  Future<bool> _sameFile(File left, File right) async {
    if (await left.length() != await right.length()) return false;
    final leftBytes = await left.readAsBytes();
    final rightBytes = await right.readAsBytes();
    for (var index = 0; index < leftBytes.length; index++) {
      if (leftBytes[index] != rightBytes[index]) return false;
    }
    return true;
  }
}
