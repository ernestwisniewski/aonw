import 'package:aonw_core/map/domain/map_survey.dart';

double mapExpansionRoomScore(MapSurvey mapData) {
  final tileCount = mapData.tileCount;
  if (tileCount >= 96) return 3.0;
  if (tileCount >= 48) return 2.2;
  if (tileCount >= 24) return 1.4;
  return 0.0;
}

double settlerInfrastructurePenalty(MapSurvey mapData) {
  return mapData.tileCount >= 24 ? 1.2 : 3.0;
}
