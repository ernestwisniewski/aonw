import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/lossless_match_snapshot_codec.dart';
import 'package:aonw_server/src/multiplayer/player_match_event_projector.dart';
import 'package:aonw_server/src/multiplayer/player_match_identity_projector.dart';
import 'package:aonw_server/src/multiplayer/player_match_snapshot_projector.dart';

typedef PlayerMatchSnapshotDecoder =
    DecodedRunningMatchSnapshot Function(WireSnapshot snapshot);

const LosslessMatchSnapshotDecoder _playerMatchSnapshotDecoder =
    LosslessMatchSnapshotDecoder();

DecodedRunningMatchSnapshot _decodePlayerMatchSnapshot(WireSnapshot snapshot) {
  return _playerMatchSnapshotDecoder.decode(snapshot);
}

final class MatchRecipient {
  const MatchRecipient({required this.userIdentifier, required this.playerId});

  final String userIdentifier;
  final String playerId;
}

/// Canonical snapshot decoded once before recipient-specific projection.
final class PreparedPlayerMatchSnapshot {
  const PreparedPlayerMatchSnapshot.prepared({
    required this.wire,
    required this.publicSave,
    required this.canonicalSnapshot,
  });

  final WireSnapshot wire;
  final Map<String, dynamic>? publicSave;
  final CanonicalGameSnapshot? canonicalSnapshot;
}

/// Canonical server message prepared once for any number of recipients.
final class PreparedPlayerMatchMessage {
  const PreparedPlayerMatchMessage.prepared({
    required this.canonical,
    required this.snapshot,
    required this.ackSnapshot,
  });

  final MultiplayerServerMessage canonical;
  final PreparedPlayerMatchSnapshot? snapshot;
  final PreparedPlayerMatchSnapshot? ackSnapshot;
}

/// Nominal proof that a server message passed recipient projection.
final class ProjectedPlayerMatchMessage {
  const ProjectedPlayerMatchMessage.projected(this.wire);

  final MultiplayerServerMessage wire;
}

extension type const ProjectedWireMatch.projected(WireMatch wire)
    implements WireMatch {}

extension type const ProjectedWireSnapshot.projected(WireSnapshot wire)
    implements WireSnapshot {}

extension type const ProjectedWireEvent.projected(WireEvent wire)
    implements WireEvent {}

extension type const ProjectedWireCommandAck.projected(WireCommandAck wire)
    implements WireCommandAck {}

/// Recipient projection façade composed from identity, snapshot, and event
/// capabilities. Canonical values never leave this boundary directly.
final class PlayerMatchViewProjector {
  const PlayerMatchViewProjector({
    PlayerMatchSnapshotDecoder decodeSnapshot = _decodePlayerMatchSnapshot,
  }) : _decodeSnapshot = decodeSnapshot;

  static const PlayerMatchIdentityProjector _identity =
      PlayerMatchIdentityProjector();
  final PlayerMatchSnapshotDecoder _decodeSnapshot;

  PlayerMatchSnapshotProjector get _snapshots =>
      PlayerMatchSnapshotProjector(_decodeSnapshot);
  PlayerMatchEventProjector get _events =>
      PlayerMatchEventProjector(_snapshots);

  ProjectedWireMatch matchFor(
    WireMatch canonical, {
    required String userIdentifier,
  }) => _identity.project(canonical, userIdentifier: userIdentifier);

  PreparedPlayerMatchSnapshot prepareSnapshot(WireSnapshot canonical) =>
      _snapshots.prepare(canonical);

  ProjectedWireSnapshot snapshotFor(
    WireSnapshot canonical,
    MatchRecipient recipient,
  ) => projectSnapshot(prepareSnapshot(canonical), recipient);

  ProjectedWireSnapshot projectSnapshot(
    PreparedPlayerMatchSnapshot prepared,
    MatchRecipient recipient,
  ) => _snapshots.project(prepared, recipient);

  ProjectedWireEvent eventFor(WireEvent canonical, MatchRecipient recipient) =>
      _events.eventFor(canonical, recipient);

  ProjectedWireCommandAck ackFor(
    WireCommandAck canonical,
    MatchRecipient recipient,
  ) =>
      _events.ackFor(canonical, prepareSnapshot(canonical.snapshot), recipient);

  PreparedPlayerMatchMessage prepareMessage(
    MultiplayerServerMessage canonical,
  ) {
    final snapshot = canonical.snapshot == null
        ? null
        : prepareSnapshot(canonical.snapshot!);
    final ackSnapshot = canonical.ack == null
        ? null
        : canonical.ack!.snapshot == canonical.snapshot
        ? snapshot
        : prepareSnapshot(canonical.ack!.snapshot);
    return PreparedPlayerMatchMessage.prepared(
      canonical: canonical,
      snapshot: snapshot,
      ackSnapshot: ackSnapshot,
    );
  }

  MultiplayerServerMessage messageFor(
    MultiplayerServerMessage canonical,
    MatchRecipient recipient,
  ) => projectMessage(prepareMessage(canonical), recipient).wire;

  ProjectedPlayerMatchMessage projectMessage(
    PreparedPlayerMatchMessage prepared,
    MatchRecipient recipient,
  ) {
    final canonical = prepared.canonical;
    return ProjectedPlayerMatchMessage.projected(
      MultiplayerServerMessage(
        serverMessageId: canonical.serverMessageId,
        matchId: canonical.matchId,
        offset: canonical.offset,
        match: canonical.match == null
            ? null
            : matchFor(
                canonical.match!,
                userIdentifier: recipient.userIdentifier,
              ),
        snapshot: canonical.snapshot == null
            ? null
            : projectSnapshot(prepared.snapshot!, recipient),
        event: canonical.event == null
            ? null
            : eventFor(canonical.event!, recipient),
        ack: canonical.ack == null
            ? null
            : _events.ackFor(canonical.ack!, prepared.ackSnapshot!, recipient),
      ),
    );
  }
}
