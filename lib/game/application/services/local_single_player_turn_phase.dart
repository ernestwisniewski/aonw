import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/services/ai_runtime_mode.dart';
import 'package:aonw/game/application/services/multiplayer_save_origin.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';

enum LocalSinglePlayerTurnPhase {
  notApplicable,
  humanPlanning,
  aiResolving,
  turnOpening;

  bool get blocksHumanInput =>
      this == LocalSinglePlayerTurnPhase.aiResolving ||
      this == LocalSinglePlayerTurnPhase.turnOpening;
}

/// Derives the persisted part of the local single-player turn phase.
///
/// Local campaigns use simultaneous multiplayer rules, so all participants are
/// active at the start of a turn. The human keeps priority until submitting;
/// only then may the local AI execute its already-precomputed plan.
///
/// [LocalSinglePlayerTurnPhase.turnOpening] is presentation-owned and cannot be
/// reconstructed from [GameSave]: the canonical state already marks the human
/// active when turn-opening effects and focus are still running.
abstract final class LocalSinglePlayerTurnPhasePolicy {
  static LocalSinglePlayerTurnPhase resolve({
    required GameSave save,
    required NetworkSession? networkSession,
  }) {
    if (isNetworkBackedGameSave(save: save, networkSession: networkSession)) {
      return LocalSinglePlayerTurnPhase.notApplicable;
    }
    if (!isLocalSinglePlayerAiRuntime(
      save: save,
      networkSession: networkSession,
    )) {
      return LocalSinglePlayerTurnPhase.notApplicable;
    }

    final humanPlayer = _humanPlayer(save);
    if (humanPlayer == null) {
      return LocalSinglePlayerTurnPhase.notApplicable;
    }
    return save.playerStates[humanPlayer.id] == PlayerTurnState.finished
        ? LocalSinglePlayerTurnPhase.aiResolving
        : LocalSinglePlayerTurnPhase.humanPlanning;
  }

  static Player? _humanPlayer(GameSave save) {
    for (final player in save.players) {
      if (player.kind == PlayerKind.human) return player;
    }
    return null;
  }
}
