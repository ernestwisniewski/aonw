import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/services/end_turn_strategy.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/application/use_cases/game_command_dispatcher.dart';
import 'package:aonw/game/domain/game_save.dart';

export 'package:aonw/game/application/services/end_turn_strategy.dart'
    show
        EndTurnResult,
        EndTurnStrategies,
        EndTurnStrategy,
        HotSeatEndTurnStrategy,
        MultiplayerEndTurnStrategy;

class EndTurnUseCase {
  final GameRepository repository;
  final EndTurnStrategy strategy;

  const EndTurnUseCase({required this.repository, required this.strategy});

  Future<EndTurnResult?> execute({
    required GameSave save,
    required PlayerControlState control,
    required DispatchGameCommand dispatch,
  }) async {
    if (control.activePlayerId.isEmpty) return null;

    return strategy.endTurn(
      save: save,
      control: control,
      dispatch: dispatch,
      reloadSave: () async => (await repository.load(save.id)).save,
    );
  }
}
