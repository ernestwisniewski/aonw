import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/runtime.dart';

abstract final class HudPendingActionCommands {
  static GameCommand? cancelResearchSelection({
    required GameState? state,
    required String activePlayerId,
  }) {
    final pendingAction = state?.pendingAction;
    if (pendingAction is! PendingResearchSelection) return null;
    if (pendingAction.ownerPlayerId != activePlayerId) return null;
    return CancelResearchSelectionCommand(pendingAction.ownerPlayerId);
  }

  static GameCommand? cancelWorkerActionSelection(GameState? state) {
    final pendingAction = state?.pendingAction;
    if (pendingAction is! PendingWorkerActionSelection) return null;
    return CancelWorkerActionSelectionCommand(pendingAction.unitId);
  }
}
