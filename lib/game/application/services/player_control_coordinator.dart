import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw_core/game/domain/player.dart';

class PlayerControlState {
  final String activePlayerId;
  final bool canAct;

  const PlayerControlState({this.activePlayerId = '', this.canAct = true});

  @override
  bool operator ==(Object other) {
    return other is PlayerControlState &&
        other.activePlayerId == activePlayerId &&
        other.canAct == canAct;
  }

  @override
  int get hashCode => Object.hash(activePlayerId, canAct);
}

abstract final class PlayerControlCoordinator {
  static PlayerControlState initial(GameSave? save) {
    return normalize(current: const PlayerControlState(), save: save);
  }

  static PlayerControlState initialForPlayer({
    required GameSave? save,
    String? preferredPlayerId,
  }) {
    if (save == null) return initial(save);
    if (preferredPlayerId != null && _containsPlayer(save, preferredPlayerId)) {
      return selectPlayer(
        current: const PlayerControlState(),
        save: save,
        playerId: preferredPlayerId,
      );
    }
    return initial(save);
  }

  static PlayerControlState normalizeForPlayer({
    required PlayerControlState current,
    required GameSave? save,
    String? preferredPlayerId,
  }) {
    if (preferredPlayerId != null &&
        save != null &&
        _containsPlayer(save, preferredPlayerId)) {
      return _stateForPlayer(
        save: save,
        playerId: preferredPlayerId,
        previousCanAct: current.canAct,
      );
    }
    return normalize(current: current, save: save);
  }

  static PlayerControlState normalize({
    required PlayerControlState current,
    required GameSave? save,
  }) {
    if (save == null) return current;
    if (save.players.isEmpty) return const PlayerControlState();

    final activePlayerId = _containsPlayer(save, current.activePlayerId)
        ? current.activePlayerId
        : save.players.first.id;

    return _stateForPlayer(
      save: save,
      playerId: activePlayerId,
      previousCanAct: current.canAct,
    );
  }

  static PlayerControlState selectPlayer({
    required PlayerControlState current,
    required GameSave? save,
    required String playerId,
  }) {
    return _stateForPlayer(
      save: save,
      playerId: playerId,
      previousCanAct: current.canAct,
    );
  }

  static PlayerControlState afterEndTurn({
    required PlayerControlState current,
    required GameSave previousSave,
    required GameSave updatedSave,
  }) {
    if (updatedSave.turn == previousSave.turn) {
      return normalize(current: current, save: updatedSave);
    }

    return _stateForPlayer(
      save: updatedSave,
      playerId: nextActivePlayerId(
        save: updatedSave,
        afterPlayerId: current.activePlayerId,
      ),
      previousCanAct: current.canAct,
    );
  }

  static String nextActivePlayerId({
    required GameSave save,
    required String afterPlayerId,
  }) {
    final players = save.players;
    if (players.isEmpty) return '';

    final currentIndex = players.indexWhere((p) => p.id == afterPlayerId);
    final startIndex = (currentIndex + 1) % players.length;

    for (int i = 0; i < players.length; i++) {
      final index = (startIndex + i) % players.length;
      final player = players[index];
      if (save.playerStates[player.id] == PlayerTurnState.active) {
        return player.id;
      }
    }

    return players.first.id;
  }

  static PlayerControlState _stateForPlayer({
    required GameSave? save,
    required String playerId,
    required bool previousCanAct,
  }) {
    if (playerId.isEmpty) return const PlayerControlState();
    if (save == null) {
      return PlayerControlState(
        activePlayerId: playerId,
        canAct: previousCanAct,
      );
    }

    return PlayerControlState(
      activePlayerId: playerId,
      canAct: save.playerStates[playerId] != PlayerTurnState.finished,
    );
  }

  static bool _containsPlayer(GameSave save, String playerId) {
    return save.players.any((player) => player.id == playerId);
  }
}
