import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/player_match_view_projector.dart'
    show ProjectedWireMatch;
import 'package:aonw_server/src/multiplayer/player_match_wire_schema_guard.dart';

/// Projects match identity and owner-only invitation data.
final class PlayerMatchIdentityProjector {
  const PlayerMatchIdentityProjector();

  ProjectedWireMatch project(
    WireMatch canonical, {
    required String userIdentifier,
  }) {
    const PlayerMatchWireSchemaGuard().validateMatch(canonical);
    final isOwner = canonical.ownerUserId == userIdentifier;
    final owner = canonical.players.where(
      (player) => player.userId == canonical.ownerUserId,
    );
    final publicOwnerId = owner.isEmpty ? canonical.id : owner.first.id;
    return ProjectedWireMatch.projected(
      canonical.copyWith(
        ownerUserId: isOwner ? userIdentifier : publicOwnerId,
        players: [
          for (final player in canonical.players)
            player.copyWith(
              userId: player.userId == userIdentifier
                  ? userIdentifier
                  : player.id,
            ),
        ],
        inviteCode: isOwner ? canonical.inviteCode : null,
      ),
    );
  }
}
