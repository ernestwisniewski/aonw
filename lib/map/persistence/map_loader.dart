import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/map/persistence.dart';
import 'package:flutter/services.dart';

typedef MapLoadException = MapDataLoadException;

abstract final class MapLoader {
  /// Loads map data from a JSON string.
  /// Throws [MapLoadException] if the JSON is malformed or contains unknown keys.
  static MapData fromJson(String jsonString) =>
      MapDataCodec.fromJson(jsonString);

  /// Serializes [mapData] to a JSON string in the same format as map asset files.
  static String toJson(MapData mapData) => MapDataCodec.toJson(mapData);

  /// Loads map data from an asset file path.
  static Future<MapData> load(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    return fromJson(jsonString);
  }
}
