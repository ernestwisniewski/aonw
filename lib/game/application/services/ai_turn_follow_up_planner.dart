import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw_core/game/domain/player.dart';

abstract final class AiTurnFollowUpPlanner {
  static AiTurnFollowUpAction plan({
    required GameSave updatedSave,
    required int previousTurn,
    required String aiPlayerId,
    required String controlPlayerId,
    required bool localAiRuntimeEnabled,
  }) {
    if (!localAiRuntimeEnabled) return const AiTurnFollowUpNone();

    if (updatedSave.gameMode == GameMode.hotSeat) {
      return _hotSeatFollowUp(
        updatedSave: updatedSave,
        previousTurn: previousTurn,
        aiPlayerId: aiPlayerId,
      );
    }

    return _localMultiplayerFollowUp(
      updatedSave: updatedSave,
      previousTurn: previousTurn,
      aiPlayerId: aiPlayerId,
      controlPlayerId: controlPlayerId,
    );
  }

  static AiTurnFollowUpAction _hotSeatFollowUp({
    required GameSave updatedSave,
    required int previousTurn,
    required String aiPlayerId,
  }) {
    final nextPlayerId = PlayerControlCoordinator.nextActivePlayerId(
      save: updatedSave,
      afterPlayerId: aiPlayerId,
    );
    if (nextPlayerId.isEmpty) return const AiTurnFollowUpNone();

    final nextPlayer = _playerById(updatedSave, nextPlayerId);
    if (nextPlayer == null) return const AiTurnFollowUpNone();

    if (nextPlayer.kind == PlayerKind.ai && nextPlayer.ai != null) {
      return AiTurnFollowUpScheduleAi(nextPlayer.id);
    }

    return AiTurnFollowUpHotSeatHandoff(
      player: nextPlayer,
      turnNumber: updatedSave.turn,
      freshTurn: updatedSave.turn > previousTurn,
    );
  }

  static AiTurnFollowUpAction _localMultiplayerFollowUp({
    required GameSave updatedSave,
    required int previousTurn,
    required String aiPlayerId,
    required String controlPlayerId,
  }) {
    final turnAdvanced = updatedSave.turn > previousTurn;
    final localHumanPlayerId = _localHumanPlayerId(
      save: updatedSave,
      controlPlayerId: controlPlayerId,
    );
    if (turnAdvanced) {
      if (!_canLocalHumanAct(updatedSave, localHumanPlayerId)) {
        return const AiTurnFollowUpNone();
      }
      return AiTurnFollowUpConfirmHumanTurn(
        playerId: localHumanPlayerId!,
        playTurnAdvanceEffects: true,
      );
    }

    final nextAiPlayerId = _nextActiveAiPlayerId(
      save: updatedSave,
      afterPlayerId: aiPlayerId,
    );
    if (nextAiPlayerId != null) {
      return AiTurnFollowUpScheduleAi(nextAiPlayerId);
    }

    if (!_canLocalHumanAct(updatedSave, localHumanPlayerId)) {
      return const AiTurnFollowUpNone();
    }
    return AiTurnFollowUpConfirmHumanTurn(
      playerId: localHumanPlayerId!,
      playTurnAdvanceEffects: false,
    );
  }

  static bool _canLocalHumanAct(GameSave save, String? playerId) {
    return playerId != null &&
        save.playerStates[playerId] == PlayerTurnState.active;
  }

  static Player? _playerById(GameSave save, String playerId) {
    for (final player in save.players) {
      if (player.id == playerId) return player;
    }
    return null;
  }

  static String? _localHumanPlayerId({
    required GameSave save,
    required String controlPlayerId,
  }) {
    final controlPlayer = _playerById(save, controlPlayerId);
    if (controlPlayer != null && controlPlayer.kind == PlayerKind.human) {
      return controlPlayer.id;
    }

    for (final player in save.players) {
      if (player.kind == PlayerKind.human) return player.id;
    }
    return null;
  }

  static String? _nextActiveAiPlayerId({
    required GameSave save,
    required String afterPlayerId,
  }) {
    final players = save.players;
    if (players.isEmpty) return null;

    final currentIndex = players.indexWhere((p) => p.id == afterPlayerId);
    final startIndex = (currentIndex + 1) % players.length;

    for (var i = 0; i < players.length; i++) {
      final index = (startIndex + i) % players.length;
      final player = players[index];
      if (save.playerStates[player.id] == PlayerTurnState.active &&
          player.kind == PlayerKind.ai &&
          player.ai != null) {
        return player.id;
      }
    }
    return null;
  }
}

sealed class AiTurnFollowUpAction {
  const AiTurnFollowUpAction();
}

final class AiTurnFollowUpNone extends AiTurnFollowUpAction {
  const AiTurnFollowUpNone();
}

final class AiTurnFollowUpScheduleAi extends AiTurnFollowUpAction {
  final String playerId;

  const AiTurnFollowUpScheduleAi(this.playerId);
}

final class AiTurnFollowUpHotSeatHandoff extends AiTurnFollowUpAction {
  final Player player;
  final int turnNumber;
  final bool freshTurn;

  const AiTurnFollowUpHotSeatHandoff({
    required this.player,
    required this.turnNumber,
    required this.freshTurn,
  });
}

final class AiTurnFollowUpConfirmHumanTurn extends AiTurnFollowUpAction {
  final String playerId;
  final bool playTurnAdvanceEffects;

  const AiTurnFollowUpConfirmHumanTurn({
    required this.playerId,
    required this.playTurnAdvanceEffects,
  });
}
