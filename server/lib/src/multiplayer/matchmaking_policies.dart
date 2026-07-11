import 'package:aonw_core/map/domain/map_player_capacity.dart';

import '../generated/protocol.dart';
import 'multiplayer_errors.dart';
import 'multiplayer_match_store.dart';

CreateMatchRequest quickplayMatchRequest(CreateMatchRequest request) {
  return request.copyWith(
    name: 'Quickplay',
    mapName: MapPlayerCapacityRules.fullMultiplayerMapName,
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
  if (state.match.state == 'open') return;
  throw multiplayerException(
    'match_not_open',
    'Only open matches can be joined.',
  );
}
