import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/view.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/lossless_match_snapshot_codec.dart';
import 'package:aonw_server/src/multiplayer/player_match_event_audience.dart';
import 'package:aonw_server/src/multiplayer/player_match_movement_audience.dart';
import 'package:aonw_server/src/multiplayer/player_match_wire_schema_guard.dart';
import 'package:aonw_server/src/multiplayer/player_view_state_projector.dart';

typedef PlayerMatchSnapshotDecoder =
    DecodedRunningMatchSnapshot Function(WireSnapshot snapshot);

const LosslessMatchSnapshotDecoder _playerMatchSnapshotDecoder =
    LosslessMatchSnapshotDecoder();
const _playerMatchWireSchemaGuard = PlayerMatchWireSchemaGuard();

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
  const PreparedPlayerMatchSnapshot._({
    required this.wire,
    required this.publicSave,
    required this.canonicalSnapshot,
    required this.hasSerializedTurnStartedAt,
  });

  final WireSnapshot wire;
  final Map<String, dynamic>? publicSave;
  final CanonicalGameSnapshot? canonicalSnapshot;
  final bool hasSerializedTurnStartedAt;
}

/// Canonical server message prepared once for any number of recipients.
final class PreparedPlayerMatchMessage {
  const PreparedPlayerMatchMessage._({
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
  const ProjectedPlayerMatchMessage._(this.wire);

  final MultiplayerServerMessage wire;
}

/// Nominal proof that a match passed recipient projection.
///
/// Implements the canonical wire type, so projected values flow into generated
/// protocol signatures unchanged, while the private constructor forces every
/// boundary that declares this return type through the projector.
extension type const ProjectedWireMatch._(WireMatch wire)
    implements WireMatch {}

/// Nominal proof that a snapshot passed recipient projection.
extension type const ProjectedWireSnapshot._(WireSnapshot wire)
    implements WireSnapshot {}

/// Nominal proof that an event passed recipient projection.
extension type const ProjectedWireEvent._(WireEvent wire)
    implements WireEvent {}

/// Nominal proof that a command ack passed recipient projection.
extension type const ProjectedWireCommandAck._(WireCommandAck wire)
    implements WireCommandAck {}

/// Builds a fail-closed, recipient-specific view of canonical match state.
///
/// Canonical snapshots and events remain in the store. Every network boundary
/// must call this projector before returning or publishing them to a client.
final class PlayerMatchViewProjector {
  const PlayerMatchViewProjector({
    PlayerMatchSnapshotDecoder decodeSnapshot = _decodePlayerMatchSnapshot,
  }) : _decodeSnapshot = decodeSnapshot;

  final PlayerMatchSnapshotDecoder _decodeSnapshot;

  ProjectedWireMatch matchFor(
    WireMatch canonical, {
    required String userIdentifier,
  }) {
    _playerMatchWireSchemaGuard.validateMatch(canonical);
    final isOwner = canonical.ownerUserId == userIdentifier;
    final owner = canonical.players.where(
      (player) => player.userId == canonical.ownerUserId,
    );
    final publicOwnerId = owner.isEmpty ? canonical.id : owner.first.id;
    return ProjectedWireMatch._(
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

  PreparedPlayerMatchSnapshot prepareSnapshot(WireSnapshot canonical) {
    _playerMatchWireSchemaGuard.validateSnapshotState(canonical.state);
    if (canonical.save.isEmpty) {
      return PreparedPlayerMatchSnapshot._(
        wire: canonical,
        publicSave: null,
        canonicalSnapshot: null,
        hasSerializedTurnStartedAt: false,
      );
    }
    _playerMatchWireSchemaGuard.validateGameSaveEnvelope(canonical.save);
    final decoded = _decodeSnapshot(canonical);
    final save = _prepareSave(decoded.save);
    _playerMatchWireSchemaGuard.validateCanonicalRoster(
      save: save,
      state: decoded.state,
    );
    return PreparedPlayerMatchSnapshot._(
      wire: canonical,
      publicSave: Map.unmodifiable(
        save
            .copyWith(
              camera: CameraState.zero,
              players: [
                for (final player in save.players) _publicPlayer(player),
              ],
            )
            .toJson(),
      ),
      canonicalSnapshot: decoded.canonical,
      hasSerializedTurnStartedAt: decoded.hasSerializedTurnStartedAt,
    );
  }

  GameSave _prepareSave(GameSave save) {
    _playerMatchWireSchemaGuard.validateGameSavePlayers(save.players);
    return save;
  }

  ProjectedWireSnapshot snapshotFor(
    WireSnapshot canonical,
    MatchRecipient recipient,
  ) {
    return projectSnapshot(prepareSnapshot(canonical), recipient);
  }

  ProjectedWireSnapshot projectSnapshot(
    PreparedPlayerMatchSnapshot prepared,
    MatchRecipient recipient,
  ) {
    final canonical = prepared.wire;
    final publicSave = prepared.publicSave;
    final canonicalSnapshot = prepared.canonicalSnapshot;
    if (publicSave == null || canonicalSnapshot == null) {
      return ProjectedWireSnapshot._(
        canonical.copyWith(state: _lifecycleState(canonical.state)),
      );
    }
    final playerViewState = _stateFor(
      canonicalSnapshot,
      recipient.playerId,
      knownDiplomacyPlayerIds: _knownDiplomacyPlayerIds(
        prepared,
        recipient.playerId,
      ),
    );
    return ProjectedWireSnapshot._(
      WireSnapshot(
        v: canonical.v,
        matchId: canonical.matchId,
        offset: canonical.offset,
        save: publicSave,
        state: {
          ..._encodePlayerViewState(prepared, playerViewState),
          ..._lifecycleState(canonical.state),
        },
      ),
    );
  }

  ProjectedWireEvent eventFor(WireEvent canonical, MatchRecipient recipient) {
    final isActor = canonical.actorPlayerId == recipient.playerId;
    final events = PlayerMatchEventAudience.projectForRecipient(
      canonical.events,
      recipientPlayerId: recipient.playerId,
    );
    final actorIsVisible = isActor || events.isNotEmpty;
    return ProjectedWireEvent._(
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
    MatchRecipient recipient,
  ) {
    return _ackForPrepared(
      canonical,
      prepareSnapshot(canonical.snapshot),
      recipient,
    );
  }

  ProjectedWireCommandAck _ackForPrepared(
    WireCommandAck canonical,
    PreparedPlayerMatchSnapshot snapshot,
    MatchRecipient recipient,
  ) {
    return ProjectedWireCommandAck._(
      WireCommandAck(
        v: canonical.v,
        matchId: canonical.matchId,
        accepted: canonical.accepted,
        offset: canonical.offset,
        snapshot: projectSnapshot(snapshot, recipient),
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
    return PreparedPlayerMatchMessage._(
      canonical: canonical,
      snapshot: snapshot,
      ackSnapshot: ackSnapshot,
    );
  }

  MultiplayerServerMessage messageFor(
    MultiplayerServerMessage canonical,
    MatchRecipient recipient,
  ) {
    return projectMessage(prepareMessage(canonical), recipient).wire;
  }

  ProjectedPlayerMatchMessage projectMessage(
    PreparedPlayerMatchMessage prepared,
    MatchRecipient recipient,
  ) {
    final canonical = prepared.canonical;
    return ProjectedPlayerMatchMessage._(
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
            : _ackForPrepared(canonical.ack!, prepared.ackSnapshot!, recipient),
      ),
    );
  }

  PlayerViewState _stateFor(
    CanonicalGameSnapshot canonicalSnapshot,
    String playerId, {
    required Set<String> knownDiplomacyPlayerIds,
  }) {
    return const PlayerViewStateProjector().project(
      domain: canonicalSnapshot.domain,
      session: canonicalSnapshot.session,
      interaction: canonicalSnapshot.interaction,
      recipientPlayerId: playerId,
      knownDiplomacyPlayerIds: knownDiplomacyPlayerIds,
    );
  }

  Set<String> _knownDiplomacyPlayerIds(
    PreparedPlayerMatchSnapshot prepared,
    String recipientPlayerId,
  ) {
    return {
      recipientPlayerId,
      ..._stringMapKeys(prepared.wire.state['playerColors']),
      ..._stringMapKeys(prepared.wire.state['playerCountries']),
    };
  }

  Iterable<String> _stringMapKeys(Object? value) {
    return value is Map ? value.keys.whereType<String>() : const [];
  }

  Map<String, dynamic> _encodePlayerViewState(
    PreparedPlayerMatchSnapshot prepared,
    PlayerViewState state,
  ) {
    final encoded = _preserveRawRosterEncoding(
      prepared,
      const PlayerViewStateWireCodec().encode(state),
    );
    if (prepared.hasSerializedTurnStartedAt) return encoded;
    final runtime = encoded['runtimeState'];
    if (runtime is! Map) return encoded;
    final projectedRuntime = Map<String, dynamic>.from(runtime)
      ..remove('turnStartedAt');
    return {...encoded, 'runtimeState': projectedRuntime};
  }

  Map<String, dynamic> _preserveRawRosterEncoding(
    PreparedPlayerMatchSnapshot prepared,
    Map<String, dynamic> encoded,
  ) {
    final projected = Map<String, dynamic>.from(encoded);
    for (final field in const {'playerColors', 'playerCountries'}) {
      final raw = prepared.wire.state[field];
      if (raw is Map) {
        projected[field] = Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(raw),
        );
      } else {
        projected.remove(field);
      }
    }
    return projected;
  }

  Player _publicPlayer(Player player) {
    final ai = player.ai;
    return ai == null
        ? player
        : player.copyWith(
            ai: AiPlayer(
              strategyId: ai.strategyId,
              difficulty: ai.difficulty,
              persona: ai.persona,
              seed: 0,
            ),
          );
  }

  Map<String, dynamic> _lifecycleState(Map<String, dynamic> state) {
    const allowed = {'phase', 'reason', 'mapName'};
    return {
      for (final entry in state.entries)
        if (allowed.contains(entry.key)) entry.key: entry.value,
    };
  }
}
