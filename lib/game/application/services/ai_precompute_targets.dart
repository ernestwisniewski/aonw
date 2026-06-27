import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/player.dart';

abstract final class AiPrecomputeTargets {
  static List<Player> duringHumanTurn({
    required GameSave save,
    required PlayerControlState control,
    required GameState gameState,
  }) {
    if (!_isStableHumanTurn(
      save: save,
      control: control,
      gameState: gameState,
    )) {
      return const [];
    }

    final targets = <Player>[];
    var afterPlayerId = control.activePlayerId;
    for (var index = 0; index < save.players.length - 1; index++) {
      final nextPlayerId = PlayerControlCoordinator.nextActivePlayerId(
        save: save,
        afterPlayerId: afterPlayerId,
      );
      if (nextPlayerId.isEmpty || nextPlayerId == control.activePlayerId) {
        break;
      }

      final nextPlayer = save.playerById(nextPlayerId);
      if (nextPlayer == null) break;
      if (nextPlayer.kind != PlayerKind.ai || nextPlayer.ai == null) {
        break;
      }

      targets.add(nextPlayer);
      afterPlayerId = nextPlayerId;
    }

    return List.unmodifiable(targets);
  }

  static bool _isStableHumanTurn({
    required GameSave save,
    required PlayerControlState control,
    required GameState gameState,
  }) {
    if (!control.canAct || control.activePlayerId.isEmpty) return false;
    if (gameState.activePlayerId != control.activePlayerId ||
        !gameState.activePlayerCanAct) {
      return false;
    }

    final currentPlayer = save.playerById(control.activePlayerId);
    return currentPlayer != null && currentPlayer.kind == PlayerKind.human;
  }
}
