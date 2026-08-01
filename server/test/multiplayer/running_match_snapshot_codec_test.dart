import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/running_match_snapshot_codec.dart';
import 'package:test/test.dart';

part 'support/running_match_snapshot_codec_roster_cases.dart';
part 'support/running_match_snapshot_codec_transition_cases.dart';

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
          state: const {'lifecycle': 'not-a-json-object'},
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
    test('can retain raw state without parsing a malformed save', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire.copyWith(save: const {'turn': 'not-an-integer'}),
      );

      expect(decoded.wire.state, fixture.wire.state);
      expect(() => decoded.save, throwsA(anything));
    });

    test('can inspect save without parsing malformed state', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire.copyWith(
          state: const {'lifecycle': 'not-a-map'},
        ),
      );

      expect(decoded.save, fixture.save);
      expect(decoded.wire.state, const {'lifecycle': 'not-a-map'});
      expect(() => decoded.canonical, throwsA(anything));
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
      expect(decoded.wire.state, fixture.wire.state);
      expect(decoded.eventLogOffset, fixture.wire.offset);
      expect(decoded.canonical, same(canonical));
    });

    test('preserves the explicitly serialized turnStartedAt', () {
      final startedAt = DateTime.utc(2026, 7, 21, 15, 30);
      final fixture = _fixture(turnStartedAt: startedAt);
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final rawState = fixture.wire.state;

      expect(decoded.canonical.domain.turnStartedAt, startedAt);

      final encoded = codec.encodeCanonical(
        decoded,
        decoded.canonical.copyWith(
          metadata: decoded.canonical.metadata.copyWith(name: 'Renamed match'),
        ),
      );

      expect(encoded.state, same(rawState));
      expect(
        (encoded.state['lifecycle']! as Map)['turnStartedAt'],
        startedAt.toIso8601String(),
      );
    });
  });

  _registerRunningMatchSnapshotCodecRosterTests(codec);

  group('RunningMatchSnapshotCodec initial encoding', () {
    test('round-trips canonical state with an explicit turnStartedAt', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final initial = decoded.canonical.copyWith(eventLogOffset: 0);

      final encoded = codec.encodeInitial(
        match: fixture.match,
        snapshot: initial,
      );

      expect(encoded.matchId, fixture.match.id);
      expect(encoded.offset, 0);
      expect(encoded.save, fixture.save.toJson());
      expect(
        encoded.state,
        CanonicalGameSnapshotCodec.encodeDomainState(fixture.state),
      );
      expect(
        (encoded.state['lifecycle']! as Map)['turnStartedAt'],
        fixture.save.savedAt.toIso8601String(),
      );
      expect(
        codec.decode(match: fixture.match, snapshot: encoded).canonical,
        initial,
      );
    });

    test('rejects non-running, mismatched, and non-zero initial sources', () {
      final fixture = _fixture();
      final canonical = codec
          .decode(match: fixture.match, snapshot: fixture.wire)
          .canonical;
      final initial = canonical.copyWith(eventLogOffset: 0);

      expect(
        () => codec.encodeInitial(
          match: fixture.match.copyWith(state: 'open'),
          snapshot: initial,
        ),
        throwsStateError,
      );
      expect(
        () => codec.encodeInitial(
          match: fixture.match,
          snapshot: initial.copyWith(
            metadata: initial.metadata.copyWith(id: 'different-match'),
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => codec.encodeInitial(match: fixture.match, snapshot: canonical),
        throwsArgumentError,
      );
    });

    test('rejects an invalid initial turn start', () {
      final fixture = _fixture();
      final initial = codec
          .decode(match: fixture.match, snapshot: fixture.wire)
          .canonical
          .copyWith(eventLogOffset: 0);

      for (final invalidTurnStart in <DateTime?>[
        null,
        initial.metadata.savedAtUtc.add(const Duration(seconds: 1)),
      ]) {
        expect(
          () => codec.encodeInitial(
            match: fixture.match,
            snapshot: initial.copyWith(
              domain: initial.domain.copyWith(turnStartedAt: invalidTurnStart),
            ),
          ),
          throwsArgumentError,
          reason: '$invalidTurnStart',
        );
      }
    });
  });

  _registerRunningMatchSnapshotCodecTransitionTests(codec);
}

typedef _CodecFixture = ({
  WireMatch match,
  WireSnapshot wire,
  GameSave save,
  DomainState state,
});

_CodecFixture _fixture({
  DateTime? turnStartedAt,
  int wireVersion = 11,
  int offset = 7,
  bool includeSecondPlayer = false,
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
  const secondPlayer = Player(
    id: 'player-2',
    name: 'Player 2',
    colorValue: 0xFF654321,
    country: PlayerCountry.germany,
  );
  const secondWirePlayer = WirePlayer(
    id: 'player-2',
    userId: 'user-2',
    name: 'Player 2',
    colorValue: 0xFF654321,
    country: PlayerCountry.germany,
    kind: WirePlayerKind.human,
    connectionState: WirePlayerConnectionState.connected,
  );
  final players = includeSecondPlayer
      ? const [player, secondPlayer]
      : const [player];
  final wirePlayers = includeSecondPlayer
      ? const [wirePlayer, secondWirePlayer]
      : const [wirePlayer];
  final playerStates = includeSecondPlayer
      ? const {
          'player-1': PlayerTurnState.active,
          'player-2': PlayerTurnState.active,
        }
      : const {'player-1': PlayerTurnState.active};
  final playerColors = includeSecondPlayer
      ? const {'player-1': 0xFF123456, 'player-2': 0xFF654321}
      : const {'player-1': 0xFF123456};
  final playerCountries = includeSecondPlayer
      ? const {
          'player-1': PlayerCountry.poland,
          'player-2': PlayerCountry.germany,
        }
      : const {'player-1': PlayerCountry.poland};
  final savedAt = DateTime.utc(2026, 7, 21, 15);
  final save = GameSave(
    id: 'match-1',
    name: 'Codec fixture',
    mapName: 'verdantia',
    turn: 1,
    playerStates: playerStates,
    savedAt: savedAt,
    camera: CameraState.zero,
    players: players,
    gameMode: GameMode.multiplayer,
  );
  final state = DomainState.snapshot(
    playerColors: playerColors,
    playerCountries: playerCountries,
    turnStartedAt: turnStartedAt ?? savedAt,
  );
  final wire = WireSnapshot(
    v: wireVersion,
    matchId: 'match-1',
    offset: offset,
    save: save.toJson(),
    state: CanonicalGameSnapshotCodec.encodeDomainState(state),
  );
  final match = WireMatch(
    v: wireVersion,
    id: 'match-1',
    ownerUserId: 'user-1',
    name: 'Codec fixture',
    mapName: 'verdantia',
    players: wirePlayers,
    turn: 1,
    state: 'running',
    createdAt: DateTime.utc(2026, 7, 21, 14),
  );
  return (match: match, wire: wire, save: save, state: state);
}

final _throwsRosterMismatch = throwsA(
  isA<FormatException>().having(
    (error) => error.message,
    'message',
    'Running snapshot roster must exactly match authoritative players.',
  ),
);
