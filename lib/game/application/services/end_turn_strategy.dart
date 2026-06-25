import 'package:aonw/game/application/services/game_handoff.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/application/use_cases/game_command_dispatcher.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';

typedef ReloadGameSave = Future<GameSave> Function();

class EndTurnResult {
  final GameSave updatedSave;
  final PlayerControlState nextControl;
  final HandoffData? handoff;
  final bool shouldResetMovement;
  final String? jumpToPlayerId;

  const EndTurnResult({
    required this.updatedSave,
    required this.nextControl,
    this.handoff,
    this.shouldResetMovement = false,
    this.jumpToPlayerId,
  });
}

abstract interface class EndTurnStrategy {
  Future<EndTurnResult> endTurn({
    required GameSave save,
    required PlayerControlState control,
    required DispatchGameCommand dispatch,
    required ReloadGameSave reloadSave,
  });
}

class EndTurnStrategies {
  const EndTurnStrategies._();

  static EndTurnStrategy forMode(GameMode gameMode) => switch (gameMode) {
    GameMode.hotSeat => const HotSeatEndTurnStrategy(),
    GameMode.multiplayer => const MultiplayerEndTurnStrategy(),
  };
}

class HotSeatEndTurnStrategy implements EndTurnStrategy {
  const HotSeatEndTurnStrategy();

  @override
  Future<EndTurnResult> endTurn({
    required GameSave save,
    required PlayerControlState control,
    required DispatchGameCommand dispatch,
    required ReloadGameSave reloadSave,
  }) async {
    await dispatch(EndTurnCommand(control.activePlayerId));
    final updatedSave = await reloadSave();
    final nextControl = PlayerControlCoordinator.afterEndTurn(
      current: control,
      previousSave: save,
      updatedSave: updatedSave,
    );

    final currentPlayerFinished =
        updatedSave.playerStates[control.activePlayerId] ==
            PlayerTurnState.finished ||
        updatedSave.turn > save.turn;

    if (currentPlayerFinished) {
      final nextPlayerId = PlayerControlCoordinator.nextActivePlayerId(
        save: updatedSave,
        afterPlayerId: control.activePlayerId,
      );
      final nextPlayer = updatedSave.players.firstWhere(
        (p) => p.id == nextPlayerId,
        orElse: () => updatedSave.players.first,
      );
      final handoff = nextPlayer.kind == PlayerKind.human
          ? HandoffData(
              playerId: nextPlayer.id,
              playerName: nextPlayer.name,
              playerColorValue: nextPlayer.colorValue,
              turnNumber: updatedSave.turn,
            )
          : null;
      return EndTurnResult(
        updatedSave: updatedSave,
        nextControl: nextControl,
        jumpToPlayerId: nextPlayerId,
        handoff: handoff,
      );
    }

    return EndTurnResult(
      updatedSave: updatedSave,
      nextControl: nextControl,
      shouldResetMovement: updatedSave.turn > save.turn,
    );
  }
}

class MultiplayerEndTurnStrategy implements EndTurnStrategy {
  const MultiplayerEndTurnStrategy();

  @override
  Future<EndTurnResult> endTurn({
    required GameSave save,
    required PlayerControlState control,
    required DispatchGameCommand dispatch,
    required ReloadGameSave reloadSave,
  }) async {
    await dispatch(SubmitTurnCommand(control.activePlayerId));
    final updatedSave = await reloadSave();
    final advancedTurn = updatedSave.turn > save.turn;
    return EndTurnResult(
      updatedSave: updatedSave,
      nextControl: PlayerControlState(
        activePlayerId: control.activePlayerId,
        canAct: advancedTurn,
      ),
      shouldResetMovement: false,
    );
  }
}
