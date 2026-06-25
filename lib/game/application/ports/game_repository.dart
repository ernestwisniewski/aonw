import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';

abstract interface class GameRepository {
  String defaultSaveName(String mapDisplayName, DateTime now);

  Future<String> create(NewGameRequest request);

  Future<List<GameSaveIndex>> list();

  Future<SaveSnapshot> load(String saveId);

  Future<void> save(SaveSnapshot snapshot);

  Future<void> delete(String saveId);

  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  });
}
