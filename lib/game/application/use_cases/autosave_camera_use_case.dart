import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/domain/game_save.dart';

class AutosaveCameraUseCase {
  final GameRepository repository;

  const AutosaveCameraUseCase({required this.repository});

  Future<bool> execute({
    required String saveId,
    required CameraState camera,
  }) async {
    if (saveId.isEmpty) return false;
    await repository.saveCamera(saveId, camera);
    return true;
  }
}
