import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/lobby_presence_policy.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';

/// Decides whether durable human presence permits a running turn clock to tick.
final class MatchTurnPresencePolicy {
  const MatchTurnPresencePolicy(this._presencePolicy);

  final LobbyPresencePolicy _presencePolicy;

  bool areAllHumanPlayersOffline(
    StoredMatchState state, {
    required DateTime nowUtc,
  }) {
    var hasHumanPlayer = false;
    for (final player in state.match.players) {
      if (player.kind != WirePlayerKind.human) continue;
      hasHumanPlayer = true;
      if (_presencePolicy.isLiveConnectedParticipant(
        state,
        player,
        nowUtc: nowUtc,
      )) {
        return false;
      }
    }
    return hasHumanPlayer;
  }

  bool shouldRestartClockOnConnection(
    StoredMatchState state,
    WirePlayer connectingPlayer, {
    required DateTime nowUtc,
  }) {
    return connectingPlayer.kind == WirePlayerKind.human &&
        areAllHumanPlayersOffline(state, nowUtc: nowUtc);
  }
}
