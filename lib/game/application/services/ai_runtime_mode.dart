import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw_core/game/domain/player.dart';

bool shouldRunLocalAiForMode({
  required GameMode gameMode,
  required String saveId,
  required NetworkSession? networkSession,
}) {
  return switch (gameMode) {
    GameMode.hotSeat => true,
    GameMode.multiplayer =>
      networkSession == null ||
          !networkSession.isConnected ||
          networkSession.matchId != saveId,
  };
}

bool isLocalSinglePlayerAiRuntime({
  required GameSave save,
  required NetworkSession? networkSession,
}) {
  if (save.gameMode != GameMode.multiplayer) return false;
  if (!shouldRunLocalAiForMode(
    gameMode: save.gameMode,
    saveId: save.id,
    networkSession: networkSession,
  )) {
    return false;
  }

  var humanCount = 0;
  var aiCount = 0;
  for (final player in save.players) {
    switch (player.kind) {
      case PlayerKind.human:
        humanCount += 1;
      case PlayerKind.ai:
        if (player.ai != null) aiCount += 1;
    }
  }
  return humanCount == 1 && aiCount > 0;
}
