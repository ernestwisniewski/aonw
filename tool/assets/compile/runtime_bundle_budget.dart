import 'dart:io';

const int flutterAssetBudgetBytes = 115 * 1024 * 1024;

final class RuntimeBundleBudget {
  const RuntimeBundleBudget(this.workspace);

  final Directory workspace;

  Future<List<String>> verify() async {
    var bytes = 0;
    for (final path in const [
      'assets/runtime',
      'assets/sounds',
      'assets/fonts',
      'assets/main_menu',
      'content/maps',
    ]) {
      bytes += await _directoryBytes(Directory('${workspace.path}/$path'));
    }
    if (bytes <= flutterAssetBudgetBytes) return const [];
    return [
      'declared Flutter assets are '
          '${(bytes / 1024 / 1024).toStringAsFixed(2)} MiB '
          '(limit ${flutterAssetBudgetBytes ~/ 1024 ~/ 1024} MiB)',
    ];
  }

  Future<int> _directoryBytes(Directory directory) async {
    if (!await directory.exists()) return 0;
    var bytes = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) bytes += await entity.length();
    }
    return bytes;
  }
}
