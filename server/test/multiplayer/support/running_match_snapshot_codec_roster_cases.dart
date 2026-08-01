part of '../running_match_snapshot_codec_test.dart';

void _registerRunningMatchSnapshotCodecRosterTests(
  RunningMatchSnapshotCodec codec,
) {
  group('RunningMatchSnapshotCodec canonical roster validation', () {
    test('returns the same memoized canonical snapshot for a valid roster', () {
      final fixture = _fixture(includeSecondPlayer: true);
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final canonical = decoded.canonical;

      expect(
        codec.canonicalWithValidatedRoster(decoded, match: fixture.match),
        same(canonical),
      );
      expect(decoded.canonical, same(canonical));
    });

    test('ignores transport-only player fields', () {
      final fixture = _fixture(includeSecondPlayer: true);
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final canonical = decoded.canonical;
      final transportChangedMatch = fixture.match.copyWith(
        players: [
          for (final player in fixture.match.players)
            player.copyWith(
              userId: 'transport-${player.id}',
              connectionState: WirePlayerConnectionState.reconnecting,
              ready: !player.ready,
            ),
        ],
      );

      expect(
        codec.canonicalWithValidatedRoster(
          decoded,
          match: transportChangedMatch,
        ),
        same(canonical),
      );
    });

    test('rejects a non-running match', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );

      expect(
        () => codec.canonicalWithValidatedRoster(
          decoded,
          match: fixture.match.copyWith(state: 'finished'),
        ),
        throwsStateError,
      );
    });

    test('rejects a wire snapshot whose match id differs from the match', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );

      expect(
        () => codec.canonicalWithValidatedRoster(
          decoded,
          match: fixture.match.copyWith(id: 'different-match'),
        ),
        _throwsRosterMismatch,
      );
    });

    test('rejects missing, reordered, and changed raw save players', () {
      final fixture = _fixture(includeSecondPlayer: true);
      final players = fixture.save.players;
      final invalidRosters = <List<Player>>[
        [players.first],
        players.reversed.toList(),
        [players.first.copyWith(name: 'Changed identity'), players.last],
      ];

      for (final roster in invalidRosters) {
        final wire = fixture.wire.copyWith(
          save: fixture.save.copyWith(players: roster).toJson(),
        );
        final decoded = codec.decode(match: fixture.match, snapshot: wire);

        expect(
          () =>
              codec.canonicalWithValidatedRoster(decoded, match: fixture.match),
          _throwsRosterMismatch,
          reason: '$roster',
        );
      }
    });

    test('rejects a missing raw player color', () {
      final fixture = _fixture(includeSecondPlayer: true);
      final wire = fixture.wire.copyWith(
        state: {
          ...CanonicalGameSnapshotCodec.encodeDomainState(fixture.state),
          'playerColors': const {'player-1': 0xFF123456},
        },
      );
      final decoded = codec.decode(match: fixture.match, snapshot: wire);

      expect(
        () => codec.canonicalWithValidatedRoster(decoded, match: fixture.match),
        _throwsRosterMismatch,
      );
    });

    test('rejects a missing raw player country', () {
      final fixture = _fixture(includeSecondPlayer: true);
      final wire = fixture.wire.copyWith(
        state: {
          ...CanonicalGameSnapshotCodec.encodeDomainState(fixture.state),
          'playerCountries': const {'player-1': 'poland'},
        },
      );
      final decoded = codec.decode(match: fixture.match, snapshot: wire);

      expect(
        () => codec.canonicalWithValidatedRoster(decoded, match: fixture.match),
        _throwsRosterMismatch,
      );
    });

    test('accepts sparse raw player-state keys', () {
      final fixture = _fixture(includeSecondPlayer: true);
      final wire = fixture.wire.copyWith(
        save: fixture.save
            .copyWith(playerStates: const {'player-1': PlayerTurnState.active})
            .toJson(),
      );
      final decoded = codec.decode(match: fixture.match, snapshot: wire);

      expect(
        codec.canonicalWithValidatedRoster(decoded, match: fixture.match),
        same(decoded.canonical),
      );
    });

    test('rejects an extra raw player-state key', () {
      final fixture = _fixture(includeSecondPlayer: true);
      final wire = fixture.wire.copyWith(
        save: fixture.save
            .copyWith(
              playerStates: const {
                'player-1': PlayerTurnState.active,
                'player-2': PlayerTurnState.active,
                'phantom': PlayerTurnState.active,
              },
            )
            .toJson(),
      );
      final decoded = codec.decode(match: fixture.match, snapshot: wire);

      expect(
        () => codec.canonicalWithValidatedRoster(decoded, match: fixture.match),
        _throwsRosterMismatch,
      );
    });

    test('rejects a player referenced only by private diplomacy state', () {
      final fixture = _fixture();
      final state = fixture.state.copyWith(
        diplomacy: DiplomacyState(
          messages: const {
            'phantom-message': DiplomaticMessage(
              id: 'phantom-message',
              fromPlayerId: 'player-1',
              toPlayerId: 'phantom',
              topic: DiplomaticMessageTopic.peacefulPraise,
              category: DiplomaticMessageCategory.praise,
              createdTurn: 1,
              expiresOnTurn: 2,
            ),
          },
        ),
      );
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire.copyWith(
          state: CanonicalGameSnapshotCodec.encodeDomainState(state),
        ),
      );

      expect(
        () => codec.canonicalWithValidatedRoster(decoded, match: fixture.match),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Multiplayer diplomacy references unknown players: phantom.',
          ),
        ),
      );
    });
  });
}
