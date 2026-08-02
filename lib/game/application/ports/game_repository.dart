import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';

abstract interface class GameRepository {
  String defaultSaveName(String mapDisplayName, DateTime now);

  Future<String> create(NewGameRequest request);

  Future<List<GameSaveIndex>> list();

  Future<CanonicalGameSnapshot> load(String saveId);

  Future<void> save(CanonicalGameSnapshot snapshot);

  Future<void> delete(String saveId);

  Future<CanonicalGameSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  });
}
