import 'dart:convert';
import 'dart:io';

import 'package:aonw_core/domain.dart';

/// Test-only importer that lets the frozen Dart regression suite consume the
/// current canonical map content without adding compatibility code to either
/// production client or engine.
Future<String> loadCurrentMapAsLegacyFixture(String mapName) async {
  final source = await File('content/maps/$mapName/map.json').readAsString();
  return currentMapAsLegacyFixture(source);
}

String currentMapAsLegacyFixture(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Canonical map fixture must be an object');
  }
  final tiles = decoded['tiles'];
  if (tiles is! List<dynamic>) {
    throw const FormatException('Canonical map fixture must contain tiles');
  }

  final legacyTiles = <Map<String, dynamic>>[];
  for (final value in tiles) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Canonical map tile must be an object');
    }
    if (value.keys.any(_isLegacyTerrainField)) {
      throw const FormatException(
        'Canonical map fixture already contains legacy terrain fields',
      );
    }
    final rawTags = value['terrainTags'];
    if (rawTags is! List<dynamic> || rawTags.any((tag) => tag is! String)) {
      throw const FormatException(
        'Canonical map tile must contain string terrainTags',
      );
    }
    final semantics = TileTerrainSemantics.fromAuthoredTerrainTags(
      rawTags.cast<String>().map(TerrainType.fromString),
    );
    legacyTiles.add({
      ...value,
      'terrains': semantics.movementTerrains
          .map((terrain) => terrain.name)
          .toList(),
      'displayTerrain': semantics.displayTerrain.name,
      'yieldTerrain': semantics.yieldTerrain.name,
    });
  }

  return jsonEncode({...decoded, 'tiles': legacyTiles});
}

String currentTextureManifestAsLegacyFixture(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Texture manifest fixture must be an object');
  }
  if (decoded.containsKey('version')) {
    throw const FormatException(
      'Current texture manifest fixture contains a legacy version',
    );
  }
  return jsonEncode({'version': 1, ...decoded});
}

bool _isLegacyTerrainField(String field) =>
    field == 'terrains' || field == 'displayTerrain' || field == 'yieldTerrain';
