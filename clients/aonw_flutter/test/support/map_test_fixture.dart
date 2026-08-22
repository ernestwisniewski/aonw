import 'package:aonw_flutter/features/map/application/map_repository.dart';
import 'package:aonw_flutter/features/map/read_model/map_reference_bundle.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';

MapScene testMapScene({
  int cols = 3,
  int rows = 2,
  String? mapId,
  String? contentHash,
}) {
  final terrains = MapTerrain.values;
  final tiles = <MapTileView>[];
  for (var row = 0; row < rows; row++) {
    for (var col = 0; col < cols; col++) {
      final terrain = terrains[(row * cols + col) % terrains.length];
      tiles.add(
        MapTileView(
          coordinate: (col: col, row: row),
          displayTerrain: terrain,
          yieldTerrain: terrain,
          movementTerrains: [terrain],
          terrainTags: [terrain],
          resources: const [],
          height: 0,
        ),
      );
    }
  }
  return MapScene(
    map: MapView(
      mapId: mapId ?? (cols == 7 && rows == 7 ? 'aonw2_starter' : 'test-map'),
      contentHash: contentHash ?? 'a' * 64,
      gridLayout: MapGridLayout.oddQFlatTop,
      cols: cols,
      rows: rows,
      defaultZoom: 1,
      tiles: tiles,
      objectives: const [],
    ),
    reference: MapReferenceBundle(
      mapId: mapId ?? (cols == 7 && rows == 7 ? 'aonw2_starter' : 'test-map'),
      mapContentHash: contentHash ?? 'a' * 64,
      worldWidth: 120 + (cols - 1) * 90,
      worldHeight: 103.92304845413263 * (rows + (cols > 1 ? 0.5 : 0)),
      pages: const [],
    ),
  );
}

final class FakeMapRepository implements MapRepository {
  FakeMapRepository.success(this.scene) : failure = null;
  FakeMapRepository.failure(this.failure) : scene = null;

  final MapScene? scene;
  final MapLoadException? failure;

  @override
  Future<MapScene> load(MapAssetPaths assets) async {
    final error = failure;
    if (error != null) throw error;
    return scene!;
  }
}
