import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_view_mode.dart';

class GameSessionFactory {
  const GameSessionFactory();

  GameSession create({
    required MapData mapData,
    required String saveId,
    String? imagePath,
    CameraState? initialCamera,
    GameMode gameMode = GameMode.hotSeat,
  }) {
    return GameSession(
      mapData: mapData,
      viewMode: MapViewMode.graphic,
      gameMode: gameMode,
      imagePath: imagePath,
      saveId: saveId,
      initialCamera: initialCamera,
    );
  }
}
