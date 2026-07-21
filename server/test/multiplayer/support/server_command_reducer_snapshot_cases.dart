part of '../server_command_reducer_test.dart';

void _registerServerCommandReducerSnapshotTests() {
  group('ServerCommandReducer snapshot boundary', () {
    test(
      'rejects every non-running lifecycle before snapshot decode',
      () async {
        final reducer = ServerCommandReducer(
          mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
        );
        const snapshot = WireSnapshot(
          matchId: 'match_1',
          offset: 7,
          save: {'turn': 'not-an-integer'},
          state: {'runtimeState': 'not-a-map'},
        );
        final rawSnapshot = snapshot.toJson();

        for (final lifecycle in const ['open', 'finished', 'abandoned']) {
          final reduction = await reducer.reduce(
            match: _runningMatch().copyWith(state: lifecycle),
            snapshot: snapshot,
            wireCommand: _wireCommand(const SubmitTurnCommand('player_1')),
            actorPlayerId: 'player_1',
            now: DateTime.utc(2026, 7, 21, 12),
          );

          expect(reduction.accepted, isFalse, reason: lifecycle);
          expect(reduction.reason, 'match_not_running', reason: lifecycle);
          expect(reduction.snapshot, same(snapshot), reason: lifecycle);
          expect(reduction.snapshot.toJson(), rawSnapshot, reason: lifecycle);
        }
      },
    );

    test('canonicalizes missing turnStartedAt without mutating wire shape', () {
      final save = _save();
      final snapshot = _snapshot(_diplomacyState(), save: save);
      final rawSnapshot = snapshot.toJson();
      final rawSave = Map<String, dynamic>.from(snapshot.save);
      final rawState = Map<String, dynamic>.from(snapshot.state);
      final rawRuntimeState = Map<String, dynamic>.from(
        snapshot.state['runtimeState'] as Map<String, dynamic>,
      );
      expect(rawRuntimeState.containsKey('turnStartedAt'), isFalse);

      final canonical = ServerCommandReducer(
        mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
      ).decodeSnapshot(snapshot).toCanonical();

      expect(canonical.session.turnStartedAt, save.savedAt.toUtc());
      expect(snapshot.toJson(), rawSnapshot);
      expect(snapshot.save, rawSave);
      expect(snapshot.state, rawState);
      expect(snapshot.state['runtimeState'], rawRuntimeState);
      expect(
        (snapshot.state['runtimeState'] as Map<String, dynamic>).containsKey(
          'turnStartedAt',
        ),
        isFalse,
      );
    });
  });

  group('DecodedMatchSnapshot canonical cache', () {
    test('memoizes the canonical snapshot', () {
      final decoded = DecodedMatchSnapshot(
        _save(),
        const PersistentGameState(),
        7,
      );

      final canonical = decoded.toCanonical();

      expect(identical(decoded.toCanonical(), canonical), isTrue);
      expect(canonical.eventLogOffset, 7);
    });

    test('withState creates a fresh cache for submitted state', () {
      final decoded = DecodedMatchSnapshot(
        _save(),
        const PersistentGameState(),
        7,
      );
      final canonical = decoded.toCanonical();
      final submittedState = decoded.state.copyWith(
        runtimeState: decoded.state.runtimeState.copyWith(
          submittedPlayerIds: const {'player_1'},
        ),
      );

      final refreshed = decoded.withState(submittedState).toCanonical();

      expect(identical(refreshed, canonical), isFalse);
      expect(canonical.session.submittedPlayerIds, isEmpty);
      expect(refreshed.session.submittedPlayerIds, {'player_1'});
    });
  });
}
