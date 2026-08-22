import '../read_model/map_scene.dart';

final class MapAssetPaths {
  const MapAssetPaths({required this.document, required this.bundleManifest});

  static const starter = MapAssetPaths(
    document: 'assets/maps/aonw2_starter/map.json',
    bundleManifest: 'assets/maps/aonw2_starter/map_texture_manifest.json',
  );

  final String document;
  final String bundleManifest;
}

abstract interface class MapRepository {
  Future<MapScene> load(MapAssetPaths assets);
}

final class MapLoadException implements Exception {
  const MapLoadException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'MapLoadException($code): $message';
}
