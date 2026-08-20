import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/services/ai_runtime_mode.dart'
    as runtime_mode;
import 'package:aonw/game/application/services/local_single_player_turn_phase.dart';
import 'package:aonw/game/application/services/multiplayer_save_origin.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';

final class GameAiTurnAutoPilotRules {
  const GameAiTurnAutoPilotRules._();

  static Player? playerById(GameSave save, String playerId) {
    return save.playerById(playerId);
  }

  static Player? aiPlayerToRun({
    required GameSave save,
    required PlayerControlState control,
    required NetworkSession? networkSession,
    required GameClientState? gameState,
  }) {
    if (gameState == null || control.activePlayerId.isEmpty) return null;
    if (_isHumanPlanningPhase(save, networkSession)) return null;

    if (_hasSynchronizedActingControl(control, gameState)) {
      return _playerToRunForActiveControl(save, control.activePlayerId);
    }

    if (!_canAdvancePastControlledPlayer(save, control, gameState)) {
      return null;
    }
    return _nextPlayerAfter(save, control.activePlayerId);
  }

  static bool _isHumanPlanningPhase(
    GameSave save,
    NetworkSession? networkSession,
  ) {
    final phase = LocalSinglePlayerTurnPhasePolicy.resolve(
      save: save,
      networkSession: networkSession,
    );
    return phase == LocalSinglePlayerTurnPhase.humanPlanning;
  }

  static bool _hasSynchronizedActingControl(
    PlayerControlState control,
    GameClientState gameState,
  ) {
    return control.canAct &&
        gameState.activePlayerId == control.activePlayerId &&
        gameState.activePlayerCanAct == control.canAct;
  }

  static Player? _playerToRunForActiveControl(
    GameSave save,
    String activePlayerId,
  ) {
    if (save.gameMode == GameMode.multiplayer) {
      final controlPlayer = playerById(save, activePlayerId);
      if (controlPlayer != null && controlPlayer.kind == PlayerKind.human) {
        return activeAiPlayerAfter(save, activePlayerId);
      }
    }
    return playerById(save, activePlayerId);
  }

  static bool _canAdvancePastControlledPlayer(
    GameSave save,
    PlayerControlState control,
    GameClientState gameState,
  ) {
    return !control.canAct &&
        gameState.activePlayerId == control.activePlayerId &&
        !gameState.activePlayerCanAct &&
        save.playerStates[control.activePlayerId] == PlayerTurnState.finished;
  }

  static Player? _nextPlayerAfter(GameSave save, String activePlayerId) {
    final nextPlayerId = PlayerControlCoordinator.nextActivePlayerId(
      save: save,
      afterPlayerId: activePlayerId,
    );
    if (nextPlayerId.isEmpty || nextPlayerId == activePlayerId) {
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
    if (isNetworkBackedGameSave(save: save, networkSession: networkSession)) {
      return false;
    }
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
