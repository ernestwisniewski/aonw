import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/running_match_snapshot_codec.dart';
import 'package:test/test.dart';

void main() {
  const codec = RunningMatchSnapshotCodec();

  group('RunningMatchSnapshotCodec lifecycle boundary', () {
    for (final lifecycleState in const ['open', 'finished', 'abandoned']) {
      test('rejects $lifecycleState before parsing malformed payloads', () {
        final fixture = _fixture();
        final malformed = WireSnapshot(
          v: fixture.wire.v,
          matchId: fixture.wire.matchId,
          offset: fixture.wire.offset,
          save: const {'malformed': true},
          state: const {'runtimeState': 'not-a-json-object'},
        );

        expect(
          () => codec.decode(
            match: fixture.match.copyWith(state: lifecycleState),
            snapshot: malformed,
          ),
          throwsStateError,
        );
      });
    }
  });

  group('DecodedRunningMatchSnapshot', () {
    test('can inspect state without parsing a malformed save', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire.copyWith(save: const {'turn': 'not-an-integer'}),
      );

      expect(decoded.state, fixture.state);
      expect(() => decoded.save, throwsA(anything));
    });

    test('can inspect save without parsing malformed state', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire.copyWith(
          state: const {'runtimeState': 'not-a-map'},
        ),
      );

      expect(decoded.save, fixture.save);
      expect(() => decoded.state, throwsA(anything));
    });

    test('canonical decoding is lazy and memoized', () {
      final fixture = _fixture();
      final duplicatePlayerSave = fixture.save.copyWith(
        players: [fixture.save.players.single, fixture.save.players.single],
      );
      final duplicatePlayers = fixture.wire.copyWith(
        save: duplicatePlayerSave.toJson(),
      );

      final lazy = codec.decode(
        match: fixture.match,
        snapshot: duplicatePlayers,
      );

      expect(lazy.save.players, hasLength(2));
      expect(() => lazy.canonical, throwsArgumentError);

      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final canonical = decoded.canonical;

      expect(decoded.wire, same(fixture.wire));
      expect(decoded.save, fixture.save);
      expect(decoded.state, fixture.state);
      expect(decoded.eventLogOffset, fixture.wire.offset);
      expect(decoded.canonical, same(canonical));
    });

    test('keeps an absent turnStartedAt as a raw encoding decision', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final rawRuntime = fixture.wire.state['runtimeState']! as Map;

      expect(rawRuntime.containsKey('turnStartedAt'), isFalse);
      expect(decoded.hadExplicitTurnStartedAt, isFalse);
      expect(decoded.state.runtimeState.turnStartedAt, isNull);
      expect(decoded.canonical.session.turnStartedAt, fixture.save.savedAt);
      expect(
        (decoded.wire.state['runtimeState']! as Map).containsKey(
          'turnStartedAt',
        ),
        isFalse,
      );
    });

    test('detects and preserves an explicit turnStartedAt', () {
      final startedAt = DateTime.utc(2026, 7, 21, 15, 30);
      final fixture = _fixture(turnStartedAt: startedAt);
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final rawState = fixture.wire.state;

      expect(decoded.hadExplicitTurnStartedAt, isTrue);
      expect(decoded.state.runtimeState.turnStartedAt, startedAt);
      expect(decoded.canonical.session.turnStartedAt, startedAt);

      final encoded = codec.encode(
        decoded,
        save: decoded.save.copyWith(name: 'Renamed match'),
      );

      expect(encoded.state, same(rawState));
      expect(
        (encoded.state['runtimeState']! as Map)['turnStartedAt'],
        startedAt.toIso8601String(),
      );
    });
  });

  group('RunningMatchSnapshotCodec encoding', () {
    test('returns the original wire snapshot without replacements', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );

      expect(codec.encode(decoded), same(fixture.wire));
    });

    test('replaces save while preserving raw state and wire envelope', () {
      final fixture = _fixture(wireVersion: 37, offset: 41);
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final rawState = fixture.wire.state;
      final replacement = decoded.save.copyWith(turn: decoded.save.turn + 1);

      final encoded = codec.encode(decoded, save: replacement);

      expect(encoded.v, fixture.wire.v);
      expect(encoded.matchId, fixture.wire.matchId);
      expect(encoded.offset, fixture.wire.offset);
      expect(encoded.save, replacement.toJson());
      expect(encoded.state, same(rawState));
      expect(encoded.state, fixture.wire.state);
      expect(fixture.wire.save, fixture.save.toJson());
    });

    test('replaces state while preserving raw save identity and shape', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final rawSave = fixture.wire.save;
      final replacement = decoded.state.copyWith(
        playerGold: const {'player-1': 17},
      );

      final encoded = codec.encode(decoded, state: replacement);

      expect(encoded.save, same(rawSave));
      expect(encoded.save, fixture.wire.save);
      expect(encoded.state, replacement.toJson());
      expect(fixture.wire.state, fixture.state.toJson());
    });
  });

  group('RunningMatchSnapshotCodec canonical transitions', () {
    test('returns the raw snapshot for a semantic no-op', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );

      expect(
        codec.encodeCanonical(decoded, decoded.canonical),
        same(fixture.wire),
      );
    });

    test('metadata-only change preserves raw state and implicit timeout', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final next = decoded.canonical.copyWith(
        metadata: decoded.canonical.metadata.copyWith(
          savedAtUtc: decoded.canonical.metadata.savedAtUtc.add(
            const Duration(seconds: 1),
          ),
        ),
      );

      final encoded = codec.encodeCanonical(decoded, next);

      expect(encoded.state, same(fixture.wire.state));
      expect(encoded.save, isNot(same(fixture.wire.save)));
      expect(
        (encoded.state['runtimeState']! as Map).containsKey('turnStartedAt'),
        isFalse,
      );
    });

    test('domain-only change preserves raw save and implicit timeout', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final next = decoded.canonical.copyWith(
        domain: decoded.canonical.domain.copyWith(
          playerGold: const {'player-1': 17},
        ),
      );

      final encoded = codec.encodeCanonical(decoded, next);

      expect(encoded.save, same(fixture.wire.save));
      expect(encoded.state['playerGold'], const {'player-1': 17});
      expect(
        (encoded.state['runtimeState']! as Map).containsKey('turnStartedAt'),
        isFalse,
      );
    });

    test('writes turnStartedAt only when the canonical value changes', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final startedAt = fixture.save.savedAt.add(const Duration(minutes: 1));
      final next = decoded.canonical.copyWith(
        session: decoded.canonical.session.copyWith(turnStartedAt: startedAt),
      );

      final encoded = codec.encodeCanonical(decoded, next);

      expect(
        (encoded.state['runtimeState']! as Map)['turnStartedAt'],
        startedAt.toIso8601String(),
      );
    });
  });
}

typedef _CodecFixture = ({
  WireMatch match,
  WireSnapshot wire,
  GameSave save,
  PersistentGameState state,
});

_CodecFixture _fixture({
  DateTime? turnStartedAt,
  int wireVersion = 11,
  int offset = 7,
}) {
  const player = Player(
    id: 'player-1',
    name: 'Player 1',
    colorValue: 0xFF123456,
    country: PlayerCountry.poland,
  );
  const wirePlayer = WirePlayer(
    id: 'player-1',
    userId: 'user-1',
    name: 'Player 1',
    colorValue: 0xFF123456,
    country: PlayerCountry.poland,
    kind: WirePlayerKind.human,
    connectionState: WirePlayerConnectionState.connected,
  );
  final savedAt = DateTime.utc(2026, 7, 21, 15);
  final save = GameSave(
    id: 'match-1',
    name: 'Codec fixture',
    mapName: 'verdantia',
    turn: 1,
    playerStates: const {'player-1': PlayerTurnState.active},
    savedAt: savedAt,
    camera: CameraState.zero,
    players: const [player],
    gameMode: GameMode.multiplayer,
  );
  final state = PersistentGameState.snapshot(
    playerColors: const {'player-1': 0xFF123456},
    playerCountries: const {'player-1': PlayerCountry.poland},
    runtimeState: GameRuntimeState.snapshot(turnStartedAt: turnStartedAt),
  );
  final wire = WireSnapshot(
    v: wireVersion,
    matchId: 'match-1',
    offset: offset,
    save: save.toJson(),
    state: state.toJson(),
  );
  final match = WireMatch(
    v: wireVersion,
    id: 'match-1',
    ownerUserId: 'user-1',
    name: 'Codec fixture',
    mapName: 'verdantia',
    players: const [wirePlayer],
    turn: 1,
    state: 'running',
    createdAt: DateTime.utc(2026, 7, 21, 14),
  );
  return (match: match, wire: wire, save: save, state: state);
}
