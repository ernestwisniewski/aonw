import 'package:aonw_core/map/domain/map_player_capacity.dart';

import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/match_lifecycle_state_adapter.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_errors.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';

CreateMatchRequest quickplayMatchRequest(CreateMatchRequest request) {
  return request.copyWith(
    name: 'Quickplay',
    mapName: MapPlayerCapacityRules.quickplayLobbyMapName,
    maxPlayers: 4,
    minPlayers: 2,
    private: false,
  );
}

void requirePublicOpenLobby(StoredMatchState state) {
  if (state.match.inviteCode != null) {
    throw multiplayerException('match_not_found', 'Match not found.');
  }
  requireOpenLobby(state);
}

void requireOpenLobby(StoredMatchState state) {
  if (const MatchLifecycleStateAdapter().lifecycleOf(state).isOpen) return;
  throw multiplayerException(
    'match_not_open',
    'Only open matches can be joined.',
  );
}
