import 'package:aonw/game/application/services/local_single_player_turn_phase.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';

class PlayerControlState {
  final String activePlayerId;
  final bool canAct;
  final LocalSinglePlayerTurnPhase phase;

  const PlayerControlState({
    this.activePlayerId = '',
    this.canAct = true,
    this.phase = LocalSinglePlayerTurnPhase.notApplicable,
  });

  bool get canInteract => canAct && !phase.blocksHumanInput;

  PlayerControlState copyWith({
    String? activePlayerId,
    bool? canAct,
    LocalSinglePlayerTurnPhase? phase,
  }) {
    return PlayerControlState(
      activePlayerId: activePlayerId ?? this.activePlayerId,
      canAct: canAct ?? this.canAct,
      phase: phase ?? this.phase,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerControlState &&
        other.activePlayerId == activePlayerId &&
        other.canAct == canAct &&
        other.phase == phase;
  }

  @override
  int get hashCode => Object.hash(activePlayerId, canAct, phase);
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

  static PlayerControlState initialFromCollections({
    required Iterable<Player> orderedPlayers,
    required Map<String, PlayerTurnState> turnStatesByPlayerId,
    String? preferredPlayerId,
  }) {
    final players = orderedPlayers.toList(growable: false);
    if (players.isEmpty) return const PlayerControlState();
    final preferredIsKnown =
        preferredPlayerId != null &&
        players.any((player) => player.id == preferredPlayerId);
    final playerId = preferredIsKnown ? preferredPlayerId : players.first.id;
    return PlayerControlState(
      activePlayerId: playerId,
      canAct: turnStatesByPlayerId[playerId] != PlayerTurnState.finished,
    );
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
        phase: preferredPlayerId == current.activePlayerId
            ? current.phase
            : LocalSinglePlayerTurnPhase.notApplicable,
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
      phase: current.phase,
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
      phase: LocalSinglePlayerTurnPhase.notApplicable,
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
    LocalSinglePlayerTurnPhase phase = LocalSinglePlayerTurnPhase.notApplicable,
  }) {
    if (playerId.isEmpty) return const PlayerControlState();
    if (save == null) {
      return PlayerControlState(
        activePlayerId: playerId,
        canAct: previousCanAct,
        phase: phase,
      );
    }

    return PlayerControlState(
      activePlayerId: playerId,
      canAct: save.playerStates[playerId] != PlayerTurnState.finished,
      phase: phase,
    );
  }

  static bool _containsPlayer(GameSave save, String playerId) {
    return save.players.any((player) => player.id == playerId);
  }
}
