import 'dart:convert';
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
    final roots = _roots ?? const ['content/maps', '../content/maps'];
    for (final root in roots) {
      final file = File('$root/$safeName/map.json');
      if (await file.exists()) {
        return WorldMapCodec.fromJson(
          _dartRulesMapJson(await file.readAsString()),
        );
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

String _dartRulesMapJson(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) return source;
  final tiles = decoded['tiles'];
  if (tiles is! List<dynamic>) return source;

  final normalizedTiles = <dynamic>[];
  var changed = false;
  for (final entry in tiles) {
    if (entry is! Map<String, dynamic>) {
      normalizedTiles.add(entry);
      continue;
    }
    final hasDerivedFields =
        entry.containsKey('terrains') ||
        entry.containsKey('displayTerrain') ||
        entry.containsKey('yieldTerrain');
    if (hasDerivedFields) {
      normalizedTiles.add(entry);
      continue;
    }
    final terrainTags = entry['terrainTags'];
    if (terrainTags is! List<dynamic>) {
      normalizedTiles.add(entry);
      continue;
    }
    final semantics = TileTerrainSemantics.fromAuthoredTerrainTags(
      terrainTags.map((value) => TerrainType.fromString(value as String)),
    );
    normalizedTiles.add({
      ...entry,
      'terrains': semantics.movementTerrains
          .map((terrain) => terrain.name)
          .toList(),
      'displayTerrain': semantics.displayTerrain.name,
      'yieldTerrain': semantics.yieldTerrain.name,
    });
    changed = true;
  }

  if (!changed) return source;
  return jsonEncode({...decoded, 'tiles': normalizedTiles});
}
