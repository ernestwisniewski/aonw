import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/domain/world_map.dart';

abstract interface class MapRepository {
  Future<List<MapSelection>> listAvailableMaps();

  Future<WorldMap> loadMap(MapSelection selection);

  Future<String?> resolveImagePath(MapSelection selection);

  Future<void> deleteSavedMap(String name);
}
