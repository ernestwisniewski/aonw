import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/view.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/multiplayer/player_match_view_projector.dart'
    show
        MatchRecipient,
        PlayerMatchSnapshotDecoder,
        PreparedPlayerMatchSnapshot,
        ProjectedWireSnapshot;
import 'package:aonw_server/src/multiplayer/player_match_wire_schema_guard.dart';
import 'package:aonw_server/src/multiplayer/player_view_state_projector.dart';

/// Decodes canonical snapshots once and projects recipient-scoped state.
final class PlayerMatchSnapshotProjector {
  const PlayerMatchSnapshotProjector(this._decodeSnapshot);

  final PlayerMatchSnapshotDecoder _decodeSnapshot;

  PreparedPlayerMatchSnapshot prepare(WireSnapshot canonical) {
    const PlayerMatchWireSchemaGuard().validateSnapshotState(canonical.state);
    if (canonical.save.isEmpty) {
      return PreparedPlayerMatchSnapshot.prepared(
        wire: canonical,
        publicSave: null,
        canonicalSnapshot: null,
      );
    }
    const PlayerMatchWireSchemaGuard().validateGameSaveEnvelope(canonical.save);
    final decoded = _decodeSnapshot(canonical);
    const PlayerMatchWireSchemaGuard()
      ..validateGameSavePlayers(decoded.save.players)
      ..validateCanonicalRoster(
        save: decoded.save,
        state: decoded.wire.state,
        canonical: decoded.canonical,
      );
    return PreparedPlayerMatchSnapshot.prepared(
      wire: canonical,
      publicSave: Map.unmodifiable(
        decoded.save
            .copyWith(
              camera: CameraState.zero,
              players: [
                for (final player in decoded.save.players)
                  _publicPlayer(player),
              ],
            )
            .toJson(),
      ),
      canonicalSnapshot: decoded.canonical,
    );
  }

  ProjectedWireSnapshot project(
    PreparedPlayerMatchSnapshot prepared,
    MatchRecipient recipient,
  ) {
    final canonical = prepared.wire;
    final publicSave = prepared.publicSave;
    final canonicalSnapshot = prepared.canonicalSnapshot;
    if (publicSave == null || canonicalSnapshot == null) {
      return ProjectedWireSnapshot.projected(
        canonical.copyWith(state: _lifecycleState(canonical.state)),
      );
    }
    final playerViewState = const PlayerViewStateProjector().project(
      domain: canonicalSnapshot.domain,
      recipientPlayerId: recipient.playerId,
      knownDiplomacyPlayerIds: {
        recipient.playerId,
        ..._stringMapKeys(prepared.wire.state['playerColors']),
        ..._stringMapKeys(prepared.wire.state['playerCountries']),
      },
    );
    final recipientSnapshot = RecipientSnapshot(
      metadata: canonicalSnapshot.metadata.copyWith(
        camera: GameSnapshotCamera.zero,
      ),
      state: playerViewState,
      visibleOffset: canonical.offset,
    );
    return ProjectedWireSnapshot.projected(
      WireSnapshot(
        v: canonical.v,
        matchId: canonical.matchId,
        offset: recipientSnapshot.visibleOffset,
        save: publicSave,
        state: {
          ...const PlayerViewStateWireCodec().encode(recipientSnapshot.state),
          ..._lifecycleState(canonical.state),
        },
      ),
    );
  }
}

Iterable<String> _stringMapKeys(Object? value) {
  return value is Map ? value.keys.whereType<String>() : const [];
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
