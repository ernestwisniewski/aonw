import 'package:aonw/map/application/map_image_source.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/map_selection.dart';

abstract interface class MapRepository {
  Future<List<MapSelection>> listAvailableMaps();

  Future<WorldMap> loadMap(MapSelection selection);

  Future<MapImageSource?> resolveImageSource(MapSelection selection);

  Future<void> deleteSavedMap(String name);
}
