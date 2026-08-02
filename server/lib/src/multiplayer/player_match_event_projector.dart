import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/player_match_event_audience.dart';
import 'package:aonw_server/src/multiplayer/player_match_movement_audience.dart';
import 'package:aonw_server/src/multiplayer/player_match_snapshot_projector.dart';
import 'package:aonw_server/src/multiplayer/player_match_view_projector.dart'
    show
        MatchRecipient,
        PreparedPlayerMatchSnapshot,
        ProjectedWireCommandAck,
        ProjectedWireEvent;

/// Projects recipient-visible events, movement executions, and command acks.
final class PlayerMatchEventProjector {
  const PlayerMatchEventProjector(this._snapshots);

  final PlayerMatchSnapshotProjector _snapshots;

  ProjectedWireEvent eventFor(WireEvent canonical, MatchRecipient recipient) {
    final isActor = canonical.actorPlayerId == recipient.playerId;
    final events = PlayerMatchEventAudience.projectForRecipient(
      canonical.events,
      recipientPlayerId: recipient.playerId,
    );
    final actorIsVisible = isActor || events.isNotEmpty;
    return ProjectedWireEvent.projected(
      WireEvent(
        v: canonical.v,
        matchId: canonical.matchId,
        offset: canonical.offset,
        timestamp: canonical.timestamp,
        actorPlayerId: actorIsVisible ? canonical.actorPlayerId : null,
        tick: isActor ? canonical.tick : null,
        turn: canonical.turn,
        command: isActor ? canonical.command : null,
        events: events,
        movementExecutions: PlayerMatchMovementAudience.projectForRecipient(
          canonical.movementExecutions,
          recipientPlayerId: recipient.playerId,
        ),
      ),
    );
  }

  ProjectedWireCommandAck ackFor(
    WireCommandAck canonical,
    PreparedPlayerMatchSnapshot snapshot,
    MatchRecipient recipient,
  ) {
    return ProjectedWireCommandAck.projected(
      WireCommandAck(
        v: canonical.v,
        matchId: canonical.matchId,
        accepted: canonical.accepted,
        offset: canonical.offset,
        tick: canonical.tick,
        timestamp: canonical.timestamp,
        snapshot: _snapshots.project(snapshot, recipient),
        events: PlayerMatchEventAudience.projectForRecipient(
          canonical.events,
          recipientPlayerId: recipient.playerId,
        ),
        reason: canonical.reason,
        movementExecutions: PlayerMatchMovementAudience.projectForRecipient(
          canonical.movementExecutions,
          recipientPlayerId: recipient.playerId,
        ),
      ),
    );
  }
}
