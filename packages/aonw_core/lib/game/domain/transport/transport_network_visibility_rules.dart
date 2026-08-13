import 'package:aonw_core/game/domain/fog/fog_visibility_query.dart';
import 'package:aonw_core/game/domain/transport/transport_network_state.dart';

/// Projects immutable transport infrastructure into one player's known world.
abstract final class TransportNetworkVisibilityRules {
  static TransportNetworkState knownFor({
    required TransportNetworkState network,
    required String playerId,
    required Iterable<String> ownCityIds,
    required FogVisibilityQuery visibility,
  }) {
    if (network.isEmpty) return network;
    final cityIds = ownCityIds.toSet();
    return TransportNetworkState(
      segments: [
        for (final segment in network.segments)
          if (segment.builtByPlayerId == playerId ||
              cityIds.contains(segment.builtByCityId) ||
              visibility.canRememberStaticAt(segment.hex.col, segment.hex.row))
            segment,
      ],
    );
  }
}
