import 'package:aonw/game/application/ports/network_session.dart';
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
}) => isLocalSinglePlayerAiRuntimeForParticipants(
  gameMode: save.gameMode,
  saveId: save.id,
  participants: save.players,
  networkSession: networkSession,
);

bool isLocalSinglePlayerAiRuntimeForParticipants({
  required GameMode gameMode,
  required String saveId,
  required Iterable<Player> participants,
  required NetworkSession? networkSession,
}) {
  if (gameMode != GameMode.multiplayer) return false;
  if (!shouldRunLocalAiForMode(
    gameMode: gameMode,
    saveId: saveId,
    networkSession: networkSession,
  )) {
    return false;
  }

  var humanCount = 0;
  var aiCount = 0;
  for (final player in participants) {
    switch (player.kind) {
      case PlayerKind.human:
        humanCount += 1;
      case PlayerKind.ai:
        if (player.ai != null) aiCount += 1;
    }
  }
  return humanCount == 1 && aiCount > 0;
}
