import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';

class ConfirmHandoffResult {
  final PlayerControlState nextControl;

  const ConfirmHandoffResult({required this.nextControl});
}

class ConfirmHandoffUseCase {
  final GameRepository repository;

  const ConfirmHandoffUseCase({required this.repository});

  Future<ConfirmHandoffResult?> execute({
    required String saveId,
    required PlayerControlState current,
    required String playerId,
  }) async {
    if (saveId.isEmpty) return null;

    final save = (await repository.load(saveId)).save;
    final next = PlayerControlCoordinator.selectPlayer(
      current: current,
      save: save,
      playerId: playerId,
    );

    return ConfirmHandoffResult(nextControl: next);
  }
}
