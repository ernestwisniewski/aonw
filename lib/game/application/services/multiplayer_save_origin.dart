import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/services/ai_runtime_mode.dart';
import 'package:aonw_core/game/domain/save.dart';

/// Whether a save belongs to a server-authoritative match.
///
/// `GameMode.multiplayer` describes the simultaneous-turn ruleset and is also
/// used by local single-player campaigns. An active match id is authoritative;
/// explicit persisted origin wins next. Only legacy saves fall back to the
/// established participant invariant used by the local AI runtime.
bool isNetworkBackedGameSave({
  required GameSave save,
  required NetworkSession? networkSession,
}) {
  if (networkSession?.matchId == save.id) return true;
  return switch (save.origin) {
    GameSaveOrigin.network => true,
    GameSaveOrigin.local => false,
    GameSaveOrigin.legacy =>
      save.gameMode == GameMode.multiplayer &&
          !hasLocalSinglePlayerParticipants(
            gameMode: save.gameMode,
            participants: save.players,
          ),
  };
}
