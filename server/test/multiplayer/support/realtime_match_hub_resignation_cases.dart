part of '../realtime_match_hub_test.dart';

void _registerRealtimeMatchHubResignationCharacterizationTests() {
  group('RealtimeMatchHub resignation characterization', () {
    test('mutates only the resigning session slice while running', () async {
      final fixture = await _createResignationFixture('exact-running');
      final actor = fixture.player('guest-one');
      final survivor = fixture.player('guest-two');
      final stored = await fixture.state();
      final save = GameSave.fromJson(stored.snapshot.save);
      final state = PersistentGameState.fromJson(stored.snapshot.state);
      final seededRuntime = state.runtimeState.copyWith(
        submittedPlayerIds: {actor.id, survivor.id},
        timeoutStreaksByPlayerId: {survivor.id: 2},
        afkPlayerIds: const {'existing-afk'},
        kickedPlayerIds: const {'existing-kicked'},
        turnStartedAt: DateTime.utc(2026, 7, 21, 11, 55),
      );
      final seededState = state.copyWith(runtimeState: seededRuntime);
      final seeded = stored.copyWith(
        snapshot: stored.snapshot.copyWith(state: seededState.toJson()),
      );
      await fixture.store.saveState(seeded);
      final saveCallsBefore = fixture.store.saveStateCalls;

      final result = await fixture.resign(actor);
      final updated = await fixture.state();
      final expectedRuntime = seededRuntime.copyWith(
        submittedPlayerIds: {survivor.id},
        afkPlayerIds: {'existing-afk', actor.id},
        kickedPlayerIds: {'existing-kicked', actor.id},
      );
      final expectedState = seededState.copyWith(runtimeState: expectedRuntime);
      final expectedSave = save.copyWith(
        playerStates: {
          ...save.playerStates,
          actor.id: PlayerTurnState.finished,
        },
      );
      final expectedMatch = seeded.match.copyWith(
        players: [
          for (final player in seeded.match.players)
            player.id == actor.id
                ? player.copyWith(
                    connectionState: WirePlayerConnectionState.offline,
                  )
                : player,
        ],
      );

      expect(result.state, 'running');
      expect(updated.match.turn, seeded.match.turn);
      expect(updated.snapshot.offset, seeded.snapshot.offset);
      expect(updated.match.toJson(), expectedMatch.toJson());
      expect(
        updated.snapshot.toJson(),
        seeded.snapshot
            .copyWith(
              save: expectedSave.toJson(),
              state: expectedState.toJson(),
            )
            .toJson(),
      );
      expect(fixture.store.saveStateCalls, saveCallsBefore + 1);
      expect(await fixture.store.listEvents(fixture.match.id, -1), isEmpty);
    });

    test('does not synthesize a missing turn state', () async {
      final fixture = await _createResignationFixture('missing-turn-state');
      final actor = fixture.player('guest-one');
      final stored = await fixture.state();
      final save = GameSave.fromJson(stored.snapshot.save);
      final withoutActor = save.copyWith(
        playerStates: {
          for (final entry in save.playerStates.entries)
            if (entry.key != actor.id) entry.key: entry.value,
        },
      );
      await fixture.store.saveState(
        stored.copyWith(
          snapshot: stored.snapshot.copyWith(save: withoutActor.toJson()),
        ),
      );

      final result = await fixture.resign(actor);
      final updated = await fixture.state();
      final updatedSave = GameSave.fromJson(updated.snapshot.save);
      final updatedState = PersistentGameState.fromJson(updated.snapshot.state);

      expect(result.state, 'running');
      expect(
        updatedSave.players.map((player) => player.id),
        contains(actor.id),
      );
      expect(updatedSave.playerStates, isNot(contains(actor.id)));
      expect(updatedState.runtimeState.kickedPlayerIds, contains(actor.id));
      expect(updatedState.runtimeState.afkPlayerIds, contains(actor.id));
      expect(updatedState.runtimeState.turnStartedAt, isNull);
      expect(
        updated.match.players
            .singleWhere((player) => player.id == actor.id)
            .connectionState,
        WirePlayerConnectionState.offline,
      );
    });

    test('finishes turn state without save player identity', () async {
      final fixture = await _createResignationFixture('missing-save-player');
      final actor = fixture.player('guest-one');
      final stored = await fixture.state();
      final save = GameSave.fromJson(stored.snapshot.save);
      final withoutActor = save.copyWith(
        players: [
          for (final player in save.players)
            if (player.id != actor.id) player,
        ],
      );
      await fixture.store.saveState(
        stored.copyWith(
          snapshot: stored.snapshot.copyWith(save: withoutActor.toJson()),
        ),
      );

      final result = await fixture.resign(actor);
      final updated = await fixture.state();
      final updatedSave = GameSave.fromJson(updated.snapshot.save);
      final updatedState = PersistentGameState.fromJson(updated.snapshot.state);

      expect(result.state, 'running');
      expect(
        updatedSave.players.map((player) => player.id),
        isNot(contains(actor.id)),
      );
      expect(updatedSave.playerStates[actor.id], PlayerTurnState.finished);
      expect(updatedState.runtimeState.kickedPlayerIds, contains(actor.id));
      expect(updatedState.runtimeState.afkPlayerIds, contains(actor.id));
      expect(updatedState.runtimeState.turnStartedAt, isNull);
    });

    test(
      'resigns a Wire-only actor without rebuilding legacy identity',
      () async {
        final fixture = await _createResignationFixture('wire-only-actor');
        final stored = await fixture.state();
        final template = fixture.player('guest-one');
        final wireOnlyActor = template.copyWith(
          id: 'wire-only-player',
          userId: 'wire-only-user',
          name: 'Wire-only player',
        );
        await fixture.store.saveState(
          stored.copyWith(
            match: stored.match.copyWith(
              players: [...stored.match.players, wireOnlyActor],
            ),
          ),
        );

        final result = await fixture.hub.resignMatch(
          store: fixture.store,
          userIdentifier: wireOnlyActor.userId,
          matchId: fixture.match.id,
        );
        final updated = await fixture.state();
        final updatedSave = GameSave.fromJson(updated.snapshot.save);
        final updatedState = PersistentGameState.fromJson(
          updated.snapshot.state,
        );

        expect(result.state, 'running');
        expect(
          updatedSave.players.map((player) => player.id),
          isNot(contains(wireOnlyActor.id)),
        );
        expect(updatedSave.playerStates, isNot(contains(wireOnlyActor.id)));
        expect(
          updatedState.runtimeState.kickedPlayerIds,
          contains(wireOnlyActor.id),
        );
        expect(
          updatedState.runtimeState.afkPlayerIds,
          contains(wireOnlyActor.id),
        );
        expect(
          updated.match.players
              .singleWhere((player) => player.id == wireOnlyActor.id)
              .connectionState,
          WirePlayerConnectionState.offline,
        );
      },
    );

    test('persists an exact no-op when the player already resigned', () async {
      final fixture = await _createResignationFixture('repeat-no-op');
      final actor = fixture.player('guest-one');
      await fixture.resign(actor);
      final afterFirst = await fixture.state();
      final saveCallsBefore = fixture.store.saveStateCalls;

      final result = await fixture.resign(actor);
      final afterSecond = await fixture.state();

      expect(result.state, 'running');
      expect(afterSecond.match.toJson(), afterFirst.match.toJson());
      expect(afterSecond.snapshot.toJson(), afterFirst.snapshot.toJson());
      expect(fixture.store.saveStateCalls, saveCallsBefore + 1);
      expect(await fixture.store.listEvents(fixture.match.id, -1), isEmpty);
    });

    test('rejects a non-participant without persistence or events', () async {
      final fixture = await _createResignationFixture('non-participant');
      final before = await fixture.state();
      final saveCallsBefore = fixture.store.saveStateCalls;

      await expectLater(
        fixture.hub.resignMatch(
          store: fixture.store,
          userIdentifier: 'stranger-user',
          matchId: fixture.match.id,
        ),
        throwsA(_multiplayerError('not_match_player')),
      );
      final after = await fixture.state();

      expect(after.match.toJson(), before.match.toJson());
      expect(after.snapshot.toJson(), before.snapshot.toJson());
      expect(fixture.store.saveStateCalls, saveCallsBefore);
      expect(await fixture.store.listEvents(fixture.match.id, -1), isEmpty);
    });

    test(
      'uses Wire humans minus kicked and ignores offline and phantoms',
      () async {
        final fixture = await _createResignationFixture('phantom-winner');
        final kicked = fixture.player('owner-user');
        final actor = fixture.player('guest-one');
        final survivor = fixture.player('guest-two');
        final stored = await fixture.state();
        final save = GameSave.fromJson(stored.snapshot.save);
        final state = PersistentGameState.fromJson(stored.snapshot.state);
        const savePhantomId = 'state-and-save-phantom';
        const statePhantomId = 'state-only-phantom';
        final savePhantom = save.players.first.copyWith(
          id: savePhantomId,
          name: 'Phantom empire',
        );
        final savePhantomUnit = state.units.first.copyWith(
          id: 'save-phantom-unit',
          ownerPlayerId: savePhantomId,
        );
        final statePhantomUnit = state.units.first.copyWith(
          id: 'state-phantom-unit',
          ownerPlayerId: statePhantomId,
        );
        await fixture.store.saveState(
          stored.copyWith(
            match: stored.match.copyWith(
              players: [
                for (final player in stored.match.players)
                  player.id == survivor.id
                      ? player.copyWith(
                          connectionState: WirePlayerConnectionState.offline,
                        )
                      : player,
              ],
            ),
            snapshot: stored.snapshot.copyWith(
              save: save
                  .copyWith(
                    players: [...save.players, savePhantom],
                    playerStates: {
                      ...save.playerStates,
                      savePhantomId: PlayerTurnState.active,
                    },
                  )
                  .toJson(),
              state: state
                  .copyWith(
                    units: [...state.units, savePhantomUnit, statePhantomUnit],
                    runtimeState: state.runtimeState.copyWith(
                      submittedPlayerIds: {statePhantomId},
                      afkPlayerIds: {survivor.id},
                      kickedPlayerIds: {kicked.id},
                    ),
                  )
                  .toJson(),
            ),
          ),
        );

        final result = await fixture.resign(actor);
        final updated = await fixture.state();

        expect(result.state, 'finished');
        expect(result.outcomeCondition, 'resignation');
        expect(result.winnerPlayerId, survivor.id);
        expect(result.winnerPlayerId, isNot(kicked.id));
        expect(result.winnerPlayerId, isNot(savePhantomId));
        expect(result.winnerPlayerId, isNot(statePhantomId));
        final updatedState = PersistentGameState.fromJson(
          updated.snapshot.state,
        );
        expect(updatedState.runtimeState.afkPlayerIds, contains(survivor.id));
        expect(
          updatedState.runtimeState.submittedPlayerIds,
          contains(statePhantomId),
        );
        expect(
          updatedState.runtimeState.kickedPlayerIds,
          isNot(contains(survivor.id)),
        );
        expect(
          updated.match.players
              .singleWhere((player) => player.id == survivor.id)
              .connectionState,
          WirePlayerConnectionState.offline,
        );
      },
    );

    test('uses all_players_resigned when no human seat remains', () async {
      final fixture = await _createResignationFixture('all-resigned');
      final actor = fixture.player('guest-two');
      final alreadyResigned = {
        fixture.player('owner-user').id,
        fixture.player('guest-one').id,
      };
      final stored = await fixture.state();
      final state = PersistentGameState.fromJson(stored.snapshot.state);
      await fixture.store.saveState(
        stored.copyWith(
          snapshot: stored.snapshot.copyWith(
            state: state
                .copyWith(
                  runtimeState: state.runtimeState.copyWith(
                    afkPlayerIds: alreadyResigned,
                    kickedPlayerIds: alreadyResigned,
                  ),
                )
                .toJson(),
          ),
        ),
      );

      final result = await fixture.resign(actor);
      final updated = await fixture.state();

      expect(result.state, 'abandoned');
      expect(result.endedAt, fixture.endedAt);
      expect(result.outcomeCondition, isNull);
      expect(result.winnerPlayerId, isNull);
      expect(updated.snapshot.state['phase'], 'abandoned');
      expect(updated.snapshot.state['reason'], 'all_players_resigned');
    });

    test(
      'does not count a living AI seat as a resignation contender',
      () async {
        final fixture = await _createResignationFixture('ai-seat');
        final winner = fixture.player('owner-user');
        final actor = fixture.player('guest-one');
        final aiSeat = fixture.player('guest-two');
        const wireAi = WireAiPlayer(
          strategyId: AiStrategyId.basic,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
        );
        final stored = await fixture.state();
        final save = GameSave.fromJson(stored.snapshot.save);
        await fixture.store.saveState(
          stored.copyWith(
            match: stored.match.copyWith(
              players: [
                for (final player in stored.match.players)
                  player.id == aiSeat.id
                      ? player.copyWith(kind: WirePlayerKind.ai, ai: wireAi)
                      : player,
              ],
            ),
          ),
        );

        final result = await fixture.resign(actor);

        expect(result.state, 'finished');
        expect(result.outcomeCondition, 'resignation');
        expect(result.winnerPlayerId, winner.id);
        expect(result.winnerPlayerId, isNot(aiSeat.id));
        final updatedSave = GameSave.fromJson(
          (await fixture.state()).snapshot.save,
        );
        expect(
          updatedSave.players
              .singleWhere((player) => player.id == aiSeat.id)
              .kind,
          PlayerKind.human,
        );
        expect(
          save.players.singleWhere((player) => player.id == aiSeat.id).kind,
          PlayerKind.human,
        );
      },
    );

    test('preserves a terminal resignation outcome on later calls', () async {
      final fixture = await _createResignationFixture('terminal-no-op');
      await fixture.resign(fixture.player('guest-one'));
      await fixture.resign(fixture.player('guest-two'));
      final finished = await fixture.state();
      final winner = fixture.player('owner-user');
      final saveCallsBefore = fixture.store.saveStateCalls;

      final result = await fixture.resign(winner);
      final after = await fixture.state();

      expect(result.state, 'finished');
      expect(result.outcomeCondition, 'resignation');
      expect(result.winnerPlayerId, winner.id);
      expect(after.match.toJson(), finished.match.toJson());
      expect(after.snapshot.toJson(), finished.snapshot.toJson());
      expect(fixture.store.saveStateCalls, saveCallsBefore + 1);
      expect(await fixture.store.listEvents(fixture.match.id, -1), isEmpty);
    });
  });
}
