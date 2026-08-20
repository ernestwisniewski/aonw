import 'dart:io';

import 'source_manifest.dart';

final class AssetSourceCheckout {
  const AssetSourceCheckout._(this.root);

  static Future<AssetSourceCheckout> open({
    required String path,
    required Directory workspace,
    required ExternalAssetSource contract,
  }) async {
    final root = Directory(path).absolute;
    if (!await root.exists()) {
      throw StateError('Asset master source does not exist: ${root.path}');
    }
    if (_isInside(root, workspace.absolute)) {
      throw StateError(
        'Asset masters must be an external checkout, not ${root.path}',
      );
    }
    if (await Directory('${root.path}/.git').exists()) {
      await _verifyGitCheckout(root, contract);
    }
    return AssetSourceCheckout._(root);
  }

  final Directory root;

  static bool _isInside(Directory candidate, Directory parent) {
    final candidatePath = _canonical(candidate.path);
    final parentPath = _canonical(parent.path);
    return candidatePath == parentPath ||
        candidatePath.startsWith('$parentPath${Platform.pathSeparator}');
  }

  static String _canonical(String path) =>
      Directory(path).absolute.path.replaceAll(RegExp(r'[/\\]+$'), '');

  static Future<void> _verifyGitCheckout(
    Directory root,
    ExternalAssetSource contract,
  ) async {
    final revision = await _git(root, ['rev-parse', 'HEAD']);
    if (revision != contract.revision) {
      throw StateError(
        'Asset master checkout is at $revision; expected ${contract.revision}',
      );
    }
    final remote = await _git(root, ['remote', 'get-url', 'origin']);
    if (_normalizeRemote(remote) != _normalizeRemote(contract.repository)) {
      throw StateError(
        'Asset master origin is $remote; expected ${contract.repository}',
      );
    }
  }

  static Future<String> _git(Directory root, List<String> arguments) async {
    final result = await Process.run('git', [
      '-C',
      root.path,
      ...arguments,
    ], runInShell: false);
    if (result.exitCode != 0) {
      throw StateError(
        'Cannot validate asset master checkout: ${(result.stderr as String).trim()}',
      );
    }
    return (result.stdout as String).trim();
  }

  static String _normalizeRemote(String value) => value
      .trim()
      .replaceFirst(RegExp(r'^git@github\.com:'), 'https://github.com/')
      .replaceFirst(RegExp(r'\.git$'), '')
      .toLowerCase();
}
