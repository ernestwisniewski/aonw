import 'package:aonw_core/protocol.dart';

import 'match_state_access.dart';
import 'multiplayer_match_store.dart';

final class MatchQueryService {
  const MatchQueryService({required MatchStateAccess stateAccess})
    : _stateAccess = stateAccess;

  final MatchStateAccess _stateAccess;

  Future<List<WireMatch>> listMatches({
    required MultiplayerMatchStore store,
    required String userIdentifier,
  }) async {
    final states = await store.listVisibleMatchStates(userIdentifier);
    return [for (final state in states) state.match];
  }

  Future<WireSnapshot> loadSnapshot({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
  }) async {
    final state = await _stateAccess.requireMatch(store, matchId);
    _stateAccess.requireParticipant(state, userIdentifier);
    return state.snapshot;
  }

  Future<List<WireEvent>> listEvents({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    required int afterOffset,
  }) async {
    final state = await _stateAccess.requireMatch(store, matchId);
    _stateAccess.requireParticipant(state, userIdentifier);
    return store.listEvents(matchId, afterOffset);
  }
}
