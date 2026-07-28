import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/initial_multiplayer_snapshot_factory.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_map_catalog.dart';
import 'package:aonw_server/src/multiplayer/running_match_snapshot_codec.dart';
import 'package:test/test.dart';

part 'support/initial_multiplayer_snapshot_fixture.dart';

void main() {
  test('preserves the complete legacy initial snapshot wire', () async {
    final canonical = await _createInitialCanonicalSnapshot();
    final actual = const RunningMatchSnapshotCodec().encodeInitial(
      match: _initialSnapshotMatch,
      snapshot: canonical,
    );
    final expected = _legacyInitialSnapshotOracle(
      mapData: _initialSnapshotMap(),
      match: _initialSnapshotMatch,
      startedAt: _initialSnapshotStartedAt,
    );

    expect(actual.toJson(), expected.toJson());
    expect(actual.matchId, _initialSnapshotMatch.id);
    expect(actual.offset, 0);
    expect(
      (actual.state['runtimeState']! as Map<String, dynamic>),
      isNot(contains('turnStartedAt')),
    );
  });

  test('decodes one canonical roster and implicit turn start', () async {
    final canonical = await _createInitialCanonicalSnapshot();
    final wire = const RunningMatchSnapshotCodec().encodeInitial(
      match: _initialSnapshotMatch,
      snapshot: canonical,
    );
    final decoded = const RunningMatchSnapshotCodec().decode(
      match: _initialSnapshotMatch,
      snapshot: wire,
    );

    expect(canonical.domain.participants, _initialSnapshotPlayers);
    expect(canonical.domain.turn, 1);
    expect(canonical.domain.matchRules, MatchRules.standard);
    expect(canonical.session.gameMode, GameMode.multiplayer);
    expect(canonical.session.turnStatesByPlayerId, {
      for (final player in _initialSnapshotPlayers)
        player.id: PlayerTurnState.active,
    });
    expect(canonical.session.turnStartedAt, _initialSnapshotStartedAt);
    expect(canonical.metadata.id, _initialSnapshotMatch.id);
    expect(canonical.metadata.name, _initialSnapshotMatch.name);
    expect(canonical.metadata.world.name, _initialSnapshotMatch.mapName);
    expect(canonical.metadata.world.source, MapSource.asset);
    expect(canonical.metadata.savedAtUtc, _initialSnapshotStartedAt);
    expect(canonical.metadata.camera, GameSnapshotCamera.zero);
    expect(canonical.interaction, PersistedInteractionState.empty);
    expect(canonical.eventLogOffset, 0);
    expect(decoded.canonical, canonical);
  });
}

Future<CanonicalGameSnapshot> _createInitialCanonicalSnapshot() {
  return InitialMultiplayerSnapshotFactory(
    mapCatalog: _InitialSnapshotMapCatalog(_initialSnapshotMap()),
  ).create(
    matchId: _initialSnapshotMatch.id,
    matchName: _initialSnapshotMatch.name,
    mapName: _initialSnapshotMatch.mapName,
    participants: _initialSnapshotPlayers,
    startedAt: _initialSnapshotStartedAt,
  );
}
