import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw_core/game/domain/save.dart';

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
