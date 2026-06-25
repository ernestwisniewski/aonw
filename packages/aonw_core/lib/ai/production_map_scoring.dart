import 'package:aonw_core/map/domain/map_data.dart';

double mapExpansionRoomScore(MapData mapData) {
  final tileCount = mapData.tiles.length;
  if (tileCount >= 96) return 3.0;
  if (tileCount >= 48) return 2.2;
  if (tileCount >= 24) return 1.4;
  return 0.0;
}

double settlerInfrastructurePenalty(MapData mapData) {
  return mapData.tiles.length >= 24 ? 1.2 : 3.0;
}
