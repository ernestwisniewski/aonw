import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';

class GameSessionFactory {
  const GameSessionFactory();

  GameSession create({
    required WorldMap mapData,
    required String saveId,
    String? imagePath,
    CameraState? initialCamera,
    GameMode gameMode = GameMode.hotSeat,
    MapViewMode preferredViewMode = MapViewMode.graphic,
  }) {
    return GameSession(
      mapData: mapData,
      viewMode: preferredViewMode,
      gameMode: gameMode,
      imagePath: imagePath,
      saveId: saveId,
      initialCamera: initialCamera,
    );
  }
}
