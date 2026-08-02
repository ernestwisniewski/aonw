import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/view.dart';

import 'package:aonw_server/src/multiplayer/player_lifecycle_state_projector.dart';
import 'package:aonw_server/src/multiplayer/player_world_state_projector.dart';

/// Composes recipient-scoped world and lifecycle projections.
final class PlayerViewStateProjector {
  const PlayerViewStateProjector({
    PlayerWorldStateProjector world = const PlayerWorldStateProjector(),
    PlayerLifecycleStateProjector lifecycle =
        const PlayerLifecycleStateProjector(),
  }) : _world = world,
       _lifecycle = lifecycle;

  final PlayerWorldStateProjector _world;
  final PlayerLifecycleStateProjector _lifecycle;

  PlayerViewState project({
    required DomainState domain,
    required String recipientPlayerId,
    required Set<String> knownDiplomacyPlayerIds,
  }) {
    return PlayerViewState(
      recipientPlayerId: recipientPlayerId,
      projectedState: {
        ..._world.project(domain, recipientPlayerId),
        'lifecycle': _lifecycle.project(
          domain,
          recipientPlayerId,
          knownDiplomacyPlayerIds,
        ),
        if (domain.wonderRegistry.completedBy.isNotEmpty)
          'wonderRegistry': domain.wonderRegistry.toJson(),
      },
    );
  }
}
