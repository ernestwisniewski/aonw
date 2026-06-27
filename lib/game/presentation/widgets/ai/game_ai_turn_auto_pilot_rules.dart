import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/game/application/services/ai_runtime_mode.dart'
    as runtime_mode;
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/player.dart';

final class GameAiTurnAutoPilotRules {
  const GameAiTurnAutoPilotRules._();

  static Player? playerById(GameSave save, String playerId) {
    return save.playerById(playerId);
  }

  static Player? aiPlayerToRun({
    required GameSave save,
    required PlayerControlState control,
    required GameState? gameState,
  }) {
    if (gameState == null || control.activePlayerId.isEmpty) return null;

    if (control.canAct &&
        gameState.activePlayerId == control.activePlayerId &&
        gameState.activePlayerCanAct == control.canAct) {
      if (save.gameMode == GameMode.multiplayer) {
        final controlPlayer = playerById(save, control.activePlayerId);
        if (controlPlayer != null && controlPlayer.kind == PlayerKind.human) {
          return activeAiPlayerAfter(save, control.activePlayerId);
        }
      }
      return playerById(save, control.activePlayerId);
    }

    if (control.canAct ||
        gameState.activePlayerId != control.activePlayerId ||
        gameState.activePlayerCanAct) {
      return null;
    }
    if (save.playerStates[control.activePlayerId] != PlayerTurnState.finished) {
      return null;
    }

    final nextPlayerId = PlayerControlCoordinator.nextActivePlayerId(
      save: save,
      afterPlayerId: control.activePlayerId,
    );
    if (nextPlayerId.isEmpty || nextPlayerId == control.activePlayerId) {
      return null;
    }
    return playerById(save, nextPlayerId);
  }

  static Player? activeAiPlayerAfter(GameSave save, String afterPlayerId) {
    final players = save.players;
    if (players.isEmpty) return null;

    final currentIndex = players.indexWhere(
      (player) => player.id == afterPlayerId,
    );
    final startIndex = (currentIndex + 1) % players.length;
    for (var indexOffset = 0; indexOffset < players.length; indexOffset++) {
      final index = (startIndex + indexOffset) % players.length;
      final player = players[index];
      if (player.kind == PlayerKind.ai &&
          player.ai != null &&
          save.playerStates[player.id] == PlayerTurnState.active) {
        return player;
      }
    }
    return null;
  }

  static bool shouldRunLocalAi({
    required GameSave save,
    required NetworkSession? networkSession,
  }) {
    return runtime_mode.shouldRunLocalAiForMode(
      gameMode: save.gameMode,
      saveId: save.id,
      networkSession: networkSession,
    );
  }

  static bool shouldRunLocalAiForMode({
    required GameMode gameMode,
    required String saveId,
    required NetworkSession? networkSession,
  }) {
    return runtime_mode.shouldRunLocalAiForMode(
      gameMode: gameMode,
      saveId: saveId,
      networkSession: networkSession,
    );
  }

  static bool isLocalSinglePlayer({
    required GameSave save,
    required NetworkSession? networkSession,
  }) {
    return runtime_mode.isLocalSinglePlayerAiRuntime(
      save: save,
      networkSession: networkSession,
    );
  }

  static bool canRunScheduledAiTurn({
    required GameSave save,
    required int scheduledTurn,
    required String playerId,
  }) {
    if (save.turn != scheduledTurn) return false;
    if (save.playerStates[playerId] != PlayerTurnState.active) return false;
    final player = playerById(save, playerId);
    return player?.kind == PlayerKind.ai && player?.ai != null;
  }
}
