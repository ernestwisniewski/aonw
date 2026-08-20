import 'dart:io';

import 'map_runtime_verifier.dart';
import 'repository_asset_policy.dart';
import 'runtime_bundle_budget.dart';
import 'runtime_file_manifest.dart';
import 'source_manifest.dart';
import 'sprite_runtime_verifier.dart';
import 'ui_metadata_runtime_verifier.dart';

final class RuntimeAssetVerifier {
  RuntimeAssetVerifier({
    required this.workspace,
    required this.sources,
    Directory? runtimeRoot,
    this.enforceRepositoryLayout = true,
  }) : runtimeRoot =
           runtimeRoot ?? Directory('${workspace.path}/assets/runtime');

  final Directory workspace;
  final Directory runtimeRoot;
  final AssetSourceManifest sources;
  final bool enforceRepositoryLayout;

  Future<void> verify() async {
    final errors = <String>[];
    await _capture(errors, 'runtime manifest', () async {
      final manifest = await RuntimeFileManifest.load(runtimeRoot);
      errors.addAll(await manifest.verify(runtimeRoot, sources));
    });
    await _capture(errors, 'sprites', () async {
      errors.addAll(
        await SpriteRuntimeVerifier(
          runtimeRoot: runtimeRoot,
          sources: sources,
        ).verify(),
      );
    });
    await _capture(errors, 'maps', () async {
      errors.addAll(
        await MapRuntimeVerifier(
          runtimeRoot: runtimeRoot,
          contentRoot: Directory('${workspace.path}/content'),
          sources: sources,
        ).verify(),
      );
    });
    await _capture(errors, 'UI/metadata', () async {
      errors.addAll(await UiMetadataRuntimeVerifier(runtimeRoot).verify());
    });
    if (enforceRepositoryLayout) {
      errors
        ..addAll(await RepositoryAssetPolicy(workspace).verify())
        ..addAll(await RuntimeBundleBudget(workspace).verify());
    }
    if (errors.isNotEmpty) {
      throw StateError('Asset verification failed:\n- ${errors.join('\n- ')}');
    }
  }

  Future<void> _capture(
    List<String> errors,
    String label,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
    } on FormatException catch (error) {
      errors.add('$label: ${error.message}');
    } on FileSystemException catch (error) {
      errors.add('$label: ${error.message}');
    } on StateError catch (error) {
      errors.add('$label: ${error.message}');
    } on TypeError catch (error) {
      errors.add('$label: malformed manifest value ($error)');
    }
  }
}
