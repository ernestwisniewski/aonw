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
      ).decodeSnapshot(match: _runningMatch(), snapshot: snapshot).canonical;

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

    test(
      'preserves raw state when an accepted repeat submission changes only save',
      () async {
        final save = _save(
          playerStates: const {
            'player_1': PlayerTurnState.finished,
            'player_2': PlayerTurnState.active,
          },
        );
        final state = _diplomacyState(
          runtimeState: GameRuntimeState(
            submittedPlayerIds: const {'player_1'},
            diplomacy: DiplomacyState.empty.addContact('player_1', 'player_2'),
          ),
        );
        final rawSave = save.toJson();
        final rawState = <String, dynamic>{
          ...state.toJson(),
          'stateCanary': const {'preserve': true},
        };
        final rawRuntimeState = rawState['runtimeState']! as Map;
        final snapshot = WireSnapshot(
          v: 37,
          matchId: 'match_1',
          offset: 41,
          save: rawSave,
          state: rawState,
        );
        final now = DateTime.utc(2026, 6, 30, 11, 1);

        expect(rawRuntimeState.containsKey('turnStartedAt'), isFalse);

        final reduction =
            await ServerCommandReducer(
              mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
            ).reduce(
              match: _runningMatch(),
              snapshot: snapshot,
              wireCommand: _wireCommand(const SubmitTurnCommand('player_1')),
              actorPlayerId: 'player_1',
              now: now,
            );

        expect(reduction.accepted, isTrue);
        expect(reduction.turn, save.turn);
        expect(reduction.events, isEmpty);
        expect(reduction.state, reduction.previousState);
        expect(reduction.state, isNot(same(reduction.previousState)));
        expect(reduction.snapshot.state, same(rawState));
        expect(reduction.snapshot.state['stateCanary'], const {
          'preserve': true,
        });
        expect(
          (reduction.snapshot.state['runtimeState']! as Map).containsKey(
            'turnStartedAt',
          ),
          isFalse,
        );
        expect(reduction.snapshot.save, isNot(same(rawSave)));
        expect(
          GameSave.fromJson(reduction.snapshot.save),
          save.copyWith(savedAt: now),
        );
        expect(reduction.snapshot.v, snapshot.v);
        expect(reduction.snapshot.matchId, snapshot.matchId);
        expect(reduction.snapshot.offset, snapshot.offset);
      },
    );

    test(
      'preserves raw save when accepted diplomacy changes only state',
      () async {
        final save = _save();
        final state = _diplomacyState();
        final rawSave = Map<String, dynamic>.from(save.toJson())
          ..remove('schemaVersion')
          ..['saveCanary'] = const {'preserve': true};
        final rawState = state.toJson();
        final snapshot = WireSnapshot(
          v: 37,
          matchId: 'match_1',
          offset: 41,
          save: rawSave,
          state: rawState,
        );

        expect(rawSave.containsKey('schemaVersion'), isFalse);

        final reduction =
            await ServerCommandReducer(
              mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
            ).reduce(
              match: _runningMatch(),
              snapshot: snapshot,
              wireCommand: _wireCommand(
                const SendDiplomaticProposalCommand(
                  playerId: 'player_1',
                  targetPlayerId: 'player_2',
                  kind: DiplomaticProposalKind.friendship,
                  proposalId: 'proposal_snapshot_boundary',
                ),
              ),
              actorPlayerId: 'player_1',
              now: save.savedAt,
            );

        expect(reduction.accepted, isTrue);
        expect(reduction.state, isNot(reduction.previousState));
        expect(reduction.snapshot.save, same(rawSave));
        expect(reduction.snapshot.save['saveCanary'], const {'preserve': true});
        expect(reduction.snapshot.save.containsKey('schemaVersion'), isFalse);
        expect(GameSave.fromJson(reduction.snapshot.save), save);
        expect(reduction.snapshot.state, isNot(same(rawState)));
        expect(
          PersistentGameState.fromJson(
            reduction.snapshot.state,
          ).runtimeState.diplomacy.pendingProposals,
          contains('proposal_snapshot_boundary'),
        );
        expect(reduction.snapshot.v, snapshot.v);
        expect(reduction.snapshot.matchId, snapshot.matchId);
        expect(reduction.snapshot.offset, snapshot.offset);
      },
    );
  });

  group('ServerCommandReducer decoded snapshot', () {
    test('memoizes the canonical snapshot', () {
      final decoded =
          ServerCommandReducer(
            mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
          ).decodeSnapshot(
            match: _runningMatch(),
            snapshot: _snapshot(
              const PersistentGameState(),
            ).copyWith(offset: 7),
          );

      final canonical = decoded.canonical;

      expect(identical(decoded.canonical, canonical), isTrue);
      expect(canonical.eventLogOffset, 7);
    });

    test('withState creates a fresh cache for submitted state', () {
      final decoded =
          ServerCommandReducer(
            mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
          ).decodeSnapshot(
            match: _runningMatch(),
            snapshot: _snapshot(
              const PersistentGameState(),
            ).copyWith(offset: 7),
          );
      final canonical = decoded.canonical;
      final submittedState = decoded.state.copyWith(
        runtimeState: decoded.state.runtimeState.copyWith(
          submittedPlayerIds: const {'player_1'},
        ),
      );

      final refreshed = decoded.withState(submittedState).canonical;

      expect(identical(refreshed, canonical), isFalse);
      expect(canonical.session.submittedPlayerIds, isEmpty);
      expect(refreshed.session.submittedPlayerIds, {'player_1'});
    });
  });
}
