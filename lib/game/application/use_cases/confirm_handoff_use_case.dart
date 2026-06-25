import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/application/use_cases/game_command_dispatcher.dart';
import 'package:aonw_core/game/domain/command.dart';

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
    required bool resetMovement,
    required DispatchGameCommand dispatch,
  }) async {
    if (saveId.isEmpty) return null;

    final save = (await repository.load(saveId)).save;
    final next = PlayerControlCoordinator.selectPlayer(
      current: current,
      save: save,
      playerId: playerId,
    );

    await dispatch(
      SetActivePlayerCommand(next.activePlayerId, canAct: next.canAct),
    );
    if (resetMovement) {
      await dispatch(ResetUnitMovementCommand(playerId: playerId));
    }

    return ConfirmHandoffResult(nextControl: next);
  }
}
