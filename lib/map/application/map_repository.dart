import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';

abstract interface class MapRepository {
  Future<List<MapSelection>> listAvailableMaps();

  Future<MapData> loadMap(MapSelection selection);

  Future<String?> resolveImagePath(MapSelection selection);

  Future<void> deleteSavedMap(String name);
}
