import 'dart:io';

import 'package:aonw_core/domain.dart';

abstract interface class MultiplayerMapCatalog {
  Future<WorldMap> loadAssetMap(String mapName);
}

final class FileMultiplayerMapCatalog implements MultiplayerMapCatalog {
  const FileMultiplayerMapCatalog({List<String>? roots}) : _roots = roots;

  final List<String>? _roots;

  @override
  Future<WorldMap> loadAssetMap(String mapName) async {
    final safeName = _safeMapName(mapName);
    final roots = _roots ?? const ['assets/maps', '../assets/maps'];
    for (final root in roots) {
      final file = File('$root/$safeName/map.json');
      if (await file.exists()) {
        return WorldMapCodec.fromJson(await file.readAsString());
      }
    }
    throw StateError('Map asset not found: $safeName');
  }

  String _safeMapName(String mapName) {
    final trimmed = mapName.trim();
    if (trimmed.isEmpty ||
        trimmed.contains('/') ||
        trimmed.contains(r'\') ||
        trimmed.contains('..')) {
      throw ArgumentError.value(mapName, 'mapName', 'Invalid map asset name');
    }
    return trimmed;
  }
}
