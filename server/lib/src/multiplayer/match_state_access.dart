import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/multiplayer/multiplayer_errors.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';

part 'match_state_access_protocol.dart';
part 'match_state_access_lifecycle.dart';

final class MatchStateAccess {
  const MatchStateAccess();

  Future<StoredMatchState> requireMatch(
    MultiplayerMatchStore store,
    String matchId, {
    bool lock = false,
  }) async {
    final state = await store.findState(matchId, lock: lock);
    if (state == null) {
      throw multiplayerException('match_not_found', 'Match not found.');
    }
    requireCurrentProtocol(state);
    return state;
  }

  WirePlayer requireParticipant(StoredMatchState state, String userIdentifier) {
    for (final player in state.match.players) {
      if (player.userId == userIdentifier) return player;
    }
    throw multiplayerException(
      'not_match_player',
      'User is not a participant in this match.',
    );
  }

  bool hasActiveHumanPlayer(
    Iterable<WirePlayer> players, {
    String? excludingUserIdentifier,
  }) {
    return players.any(
      (player) =>
          player.kind == WirePlayerKind.human &&
          player.userId != excludingUserIdentifier &&
          _isActiveConnectionState(player.connectionState),
    );
  }

  bool _isActiveConnectionState(WirePlayerConnectionState state) {
    return switch (state) {
      WirePlayerConnectionState.connected ||
      WirePlayerConnectionState.connecting ||
      WirePlayerConnectionState.reconnecting => true,
      WirePlayerConnectionState.offline => false,
    };
  }
}
