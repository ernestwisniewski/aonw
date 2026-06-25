import 'package:aonw/game/application/use_cases/game_command_dispatcher.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';

class DetachTroopUseCase {
  const DetachTroopUseCase();

  Future<bool> execute({
    required GameState? state,
    required TroopType troopType,
    required DispatchGameCommand dispatch,
  }) async {
    final unitId = state?.selectedUnitId;
    if (unitId == null) return false;
    await dispatch(DetachTroopCommand(unitId, troopType));
    return true;
  }
}
