import 'package:aonw/map/application/map_repository.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/persistence/map_catalog.dart';
import 'package:aonw/map/persistence/map_storage.dart';

class LocalMapRepository implements MapRepository {
  const LocalMapRepository();

  @override
  Future<List<MapSelection>> listAvailableMaps() {
    return MapCatalog.listAvailableMaps();
  }

  @override
  Future<MapData> loadMap(MapSelection selection) {
    return MapCatalog.loadMap(selection);
  }

  @override
  Future<String?> resolveImagePath(MapSelection selection) {
    return MapStorage.resolveImagePath(
      selection.name,
      source: selection.source,
    );
  }

  @override
  Future<void> deleteSavedMap(String name) async {
    final dir = await MapStorage.mapDirectory(name);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
