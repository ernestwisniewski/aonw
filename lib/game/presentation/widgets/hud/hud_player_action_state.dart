import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/player.dart';

class HudPlayerActionState {
  final bool actionsLocked;
  final bool canShowGlobalActions;
  final bool showTopResources;

  const HudPlayerActionState({
    required this.actionsLocked,
    required this.canShowGlobalActions,
    required this.showTopResources,
  });

  factory HudPlayerActionState.from({
    required GameState? gameState,
    required GameSave gameSave,
    required String activePlayerId,
    required bool activePlayerCanAct,
  }) {
    final activePlayerSubmitted =
        gameState?.hasSubmittedTurn(activePlayerId) ?? false;
    final activePlayerFinished =
        gameSave.playerStates[activePlayerId] == PlayerTurnState.finished;

    return HudPlayerActionState(
      actionsLocked:
          !activePlayerCanAct || activePlayerFinished || activePlayerSubmitted,
      canShowGlobalActions:
          activePlayerId.isNotEmpty &&
          !activePlayerSubmitted &&
          !activePlayerFinished,
      showTopResources: activePlayerId.isNotEmpty,
    );
  }
}
