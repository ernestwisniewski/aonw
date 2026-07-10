import 'package:aonw_core/protocol.dart';

import 'match_state_access.dart';
import 'multiplayer_errors.dart';
import 'multiplayer_match_store.dart';
import 'player_match_view_projector.dart';

part 'match_query_service_views.dart';

final class MatchQueryService {
  const MatchQueryService({
    required MatchStateAccess stateAccess,
    required PlayerMatchViewProjector viewProjector,
  }) : _stateAccess = stateAccess,
       _viewProjector = viewProjector;

  final MatchStateAccess _stateAccess;
  final PlayerMatchViewProjector _viewProjector;

  Future<List<WireMatch>> listMatches({
    required MultiplayerMatchStore store,
    required String userIdentifier,
  }) async {
    final matches = await store.listVisibleMatches(userIdentifier);
    return _projectPlayerView(() {
      return [
        for (final match in matches)
          _viewProjector.matchFor(match, userIdentifier: userIdentifier),
      ];
    });
  }
}
