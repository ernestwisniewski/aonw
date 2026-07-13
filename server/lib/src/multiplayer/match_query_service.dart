import 'package:aonw_server/src/multiplayer/match_state_access.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_errors.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/multiplayer/player_match_view_projector.dart';
import 'package:aonw_server/src/observability/server_operational_event_sink.dart';

part 'match_query_service_views.dart';

final class MatchQueryService {
  const MatchQueryService({
    required MatchStateAccess stateAccess,
    required PlayerMatchViewProjector viewProjector,
  }) : _stateAccess = stateAccess,
       _viewProjector = viewProjector;

  final MatchStateAccess _stateAccess;
  final PlayerMatchViewProjector _viewProjector;

  Future<List<ProjectedWireMatch>> listMatches({
    required MultiplayerMatchStore store,
    required String userIdentifier,
  }) async {
    final matches = await store.listVisibleMatches(userIdentifier);
    return _projectPlayerView(
      store: store,
      matchId: 'match-list',
      surface: MultiplayerProjectionSurface.matchList,
      project: () {
        return [
          for (final match in matches)
            if (_stateAccess.supportsCurrentMatch(match))
              _viewProjector.matchFor(match, userIdentifier: userIdentifier),
        ];
      },
    );
  }
}
