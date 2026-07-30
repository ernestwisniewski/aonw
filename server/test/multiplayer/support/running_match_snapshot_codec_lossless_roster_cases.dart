part of '../running_match_snapshot_codec_test.dart';

void _registerRunningMatchSnapshotCodecLosslessRosterTests(
  RunningMatchSnapshotCodec codec,
) {
  group('RunningMatchSnapshotCodec initial roster encoding', () {
    test('rejects a canonical roster that differs from the wire match', () {
      final fixture = _fixture();
      final initial = codec
          .decode(match: fixture.match, snapshot: fixture.wire)
          .canonical
          .copyWith(eventLogOffset: 0);
      final changedPlayer = fixture.match.players.single.copyWith(
        name: 'Changed transport roster',
      );

      expect(
        () => codec.encodeInitial(
          match: fixture.match.copyWith(players: [changedPlayer]),
          snapshot: initial,
        ),
        _throwsRosterMismatch,
      );
    });

    test(
      'rejects initial turn-state keys that differ from the wire roster',
      () {
        final fixture = _fixture();
        final canonical = codec
            .decode(match: fixture.match, snapshot: fixture.wire)
            .canonical;
        final initial = canonical.copyWith(
          session: canonical.session.copyWith(turnStatesByPlayerId: const {}),
          eventLogOffset: 0,
        );

        expect(
          () => codec.encodeInitial(match: fixture.match, snapshot: initial),
          _throwsRosterMismatch,
        );
      },
    );
  });

  group('RunningMatchSnapshotCodec lossless roster transitions', () {
    test('metadata change preserves conflicting raw save roster fields', () {
      final fixture = _fixture();
      final rawSave = fixture.save.copyWith(
        players: [
          fixture.save.players.single.copyWith(
            colorValue: 0xFF010203,
            country: PlayerCountry.canada,
          ),
        ],
      );
      final rawState = fixture.state.copyWith(
        playerColors: const {'player-1': 0xFFABCDEF},
        playerCountries: const {'player-1': PlayerCountry.japan},
      );
      final wire = fixture.wire.copyWith(
        save: rawSave.toJson(),
        state: rawState.toJson(),
      );
      final decoded = codec.decode(match: fixture.match, snapshot: wire);
      final next = decoded.canonical.copyWith(
        metadata: decoded.canonical.metadata.copyWith(name: 'Renamed match'),
      );

      final encoded = codec.encodeCanonical(decoded, next);
      final encodedSave = GameSave.fromJson(encoded.save);

      expect(encodedSave.name, 'Renamed match');
      expect(encodedSave.players, rawSave.players);
      expect(encoded.state, same(wire.state));
    });

    test('domain change preserves sparse raw roster maps', () {
      final fixture = _fixture();
      final sparseState = fixture.state.copyWith(
        playerColors: const {},
        playerCountries: const {},
      );
      final wire = fixture.wire.copyWith(state: sparseState.toJson());
      final decoded = codec.decode(match: fixture.match, snapshot: wire);
      final next = decoded.canonical.copyWith(
        domain: decoded.canonical.domain.copyWith(
          playerGold: const {'player-1': 23},
        ),
      );

      final encoded = codec.encodeCanonical(decoded, next);
      final encodedState = PersistentGameState.fromJson(encoded.state);

      expect(encoded.save, same(wire.save));
      expect(encodedState.playerGold, const {'player-1': 23});
      expect(encodedState.playerColors, isEmpty);
      expect(encodedState.playerCountries, isEmpty);
    });

    test('changed halves keep absent raw roster keys absent', () {
      final fixture = _fixture();
      final rawSave = Map<String, dynamic>.from(fixture.wire.save)
        ..remove('players');
      final rawState = Map<String, dynamic>.from(fixture.wire.state)
        ..remove('playerColors')
        ..remove('playerCountries');
      final wire = fixture.wire.copyWith(save: rawSave, state: rawState);
      final decoded = codec.decode(match: fixture.match, snapshot: wire);
      final next = decoded.canonical.copyWith(
        metadata: decoded.canonical.metadata.copyWith(name: 'Renamed match'),
        domain: decoded.canonical.domain.copyWith(
          playerGold: const {'player-1': 31},
        ),
      );

      final encoded = codec.encodeCanonical(decoded, next);

      expect(encoded.save.containsKey('players'), isFalse);
      expect(encoded.state.containsKey('playerColors'), isFalse);
      expect(encoded.state.containsKey('playerCountries'), isFalse);
      expect(encoded.state['playerGold'], const {'player-1': 31});
    });

    test('session change preserves every raw roster carrier', () {
      final fixture = _fixture();
      final rawSave = fixture.save.copyWith(
        players: [
          fixture.save.players.single.copyWith(
            colorValue: 0xFF010203,
            country: PlayerCountry.canada,
          ),
        ],
      );
      final rawState = fixture.state.copyWith(
        playerColors: const {'player-1': 0xFFABCDEF},
        playerCountries: const {'player-1': PlayerCountry.japan},
      );
      final wire = fixture.wire.copyWith(
        save: rawSave.toJson(),
        state: rawState.toJson(),
      );
      final decoded = codec.decode(match: fixture.match, snapshot: wire);
      final next = decoded.canonical.copyWith(
        session: decoded.canonical.session.copyWith(
          submittedPlayerIds: const {'player-1'},
        ),
      );

      final encoded = codec.encodeCanonical(decoded, next);
      final encodedState = PersistentGameState.fromJson(encoded.state);

      expect(encoded.save, same(wire.save));
      expect(encodedState.playerColors, rawState.playerColors);
      expect(encodedState.playerCountries, rawState.playerCountries);
      expect(encodedState.runtimeState.submittedPlayerIds, {'player-1'});
    });

    test('rejects canonical participant mutation', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final next = decoded.canonical.copyWith(
        domain: decoded.canonical.domain.copyWith(
          participants: [
            decoded.canonical.domain.participants.single.copyWith(
              name: 'Changed canonical roster',
            ),
          ],
        ),
      );

      expect(() => codec.encodeCanonical(decoded, next), _throwsRosterMismatch);
    });

    test('encodes a sparse canonical turn-state roster', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final next = decoded.canonical.copyWith(
        session: decoded.canonical.session.copyWith(
          turnStatesByPlayerId: const {},
        ),
      );

      final encoded = codec.encodeCanonical(decoded, next);

      expect(GameSave.fromJson(encoded.save).playerStates, isEmpty);
    });

    test('rejects a domain reference outside canonical participants', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final next = decoded.canonical.copyWith(
        domain: decoded.canonical.domain.copyWith(
          playerGold: {
            ...decoded.canonical.domain.playerGold,
            'phantom-player': 99,
          },
        ),
      );

      expect(
        () => codec.encodeCanonical(decoded, next),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('cannot be represented losslessly'),
          ),
        ),
      );
    });
  });
}
