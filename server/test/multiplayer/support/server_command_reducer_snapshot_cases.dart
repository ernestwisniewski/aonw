part of '../server_command_reducer_test.dart';

void _registerServerCommandReducerSnapshotTests() {
  group('ServerCommandReducer lossless snapshot boundary', () {
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

        final reduction = await _serverCommandTestDriver.reduce(
          reducer: ServerCommandReducer(
            mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
          ),
          match: _runningMatch(),
          wireSnapshot: snapshot,
          wireCommand: _wireCommand(const SubmitTurnCommand('player_1')),
          actorPlayerId: 'player_1',
          now: now,
        );
        final nextSnapshot = reduction.nextSnapshot!;
        final wireSnapshot = reduction.wireSnapshot;

        expect(reduction.accepted, isTrue);
        expect(nextSnapshot.domain.turn, save.turn);
        expect(reduction.events, isEmpty);
        expect(nextSnapshot.domain, same(reduction.previousSnapshot.domain));
        expect(nextSnapshot.session, reduction.previousSnapshot.session);
        expect(nextSnapshot.metadata.savedAtUtc, now);
        expect(
          reduction.previousSnapshot.session.turnStartedAt,
          save.savedAt.toUtc(),
        );
        expect(wireSnapshot.state, same(rawState));
        expect(wireSnapshot.state['stateCanary'], const {'preserve': true});
        expect(
          (wireSnapshot.state['runtimeState']! as Map).containsKey(
            'turnStartedAt',
          ),
          isFalse,
        );
        expect(wireSnapshot.save, isNot(same(rawSave)));
        expect(
          GameSave.fromJson(wireSnapshot.save),
          save.copyWith(savedAt: now),
        );
        expect(wireSnapshot.v, snapshot.v);
        expect(wireSnapshot.matchId, snapshot.matchId);
        expect(wireSnapshot.offset, snapshot.offset);
      },
    );

    test(
      'preserves raw save when accepted diplomacy changes only domain',
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

        final reduction = await _serverCommandTestDriver.reduce(
          reducer: ServerCommandReducer(
            mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
          ),
          match: _runningMatch(),
          wireSnapshot: snapshot,
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
        final nextSnapshot = reduction.nextSnapshot!;
        final wireSnapshot = reduction.wireSnapshot;

        expect(reduction.accepted, isTrue);
        expect(
          nextSnapshot.domain,
          isNot(same(reduction.previousSnapshot.domain)),
        );
        expect(nextSnapshot.session, same(reduction.previousSnapshot.session));
        expect(
          nextSnapshot.metadata,
          same(reduction.previousSnapshot.metadata),
        );
        expect(wireSnapshot.save, same(rawSave));
        expect(wireSnapshot.save['saveCanary'], const {'preserve': true});
        expect(wireSnapshot.save.containsKey('schemaVersion'), isFalse);
        expect(GameSave.fromJson(wireSnapshot.save), save);
        expect(wireSnapshot.state, isNot(same(rawState)));
        expect(
          nextSnapshot.domain.diplomacy.pendingProposals,
          contains('proposal_snapshot_boundary'),
        );
        expect(wireSnapshot.v, snapshot.v);
        expect(wireSnapshot.matchId, snapshot.matchId);
        expect(wireSnapshot.offset, snapshot.offset);
      },
    );
  });
}
