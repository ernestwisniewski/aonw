import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/persistence.dart';
import 'package:flutter/services.dart';

typedef MapLoadException = WorldMapLoadException;

abstract final class MapLoader {
  /// Loads map data from a JSON string.
  /// Throws [MapLoadException] if the JSON is malformed or contains unknown keys.
  static WorldMap fromJson(String jsonString) =>
      WorldMapCodec.fromJson(jsonString);

  /// Serializes [mapData] to a JSON string in the same format as map asset files.
  static String toJson(WorldMap mapData) => WorldMapCodec.toJson(mapData);

  /// Loads map data from an asset file path.
  static Future<WorldMap> load(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    return fromJson(jsonString);
  }
}
