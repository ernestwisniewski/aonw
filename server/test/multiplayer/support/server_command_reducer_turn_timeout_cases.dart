part of '../server_command_reducer_test.dart';

void _registerServerCommandReducerTurnTimeoutTests() {
  group('ServerCommandReducer turn timeouts', () {
    test(
      'finalizes when the remaining unsubmitted player is offline',
      () async {
        final players = _wirePlayers();
        final reducer = ServerCommandReducer(
          mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
        );

        final reduction = await reducer.reduce(
          match: _runningMatch(
            players: [
              players[0],
              players[1].copyWith(
                connectionState: WirePlayerConnectionState.offline,
              ),
            ],
          ),
          snapshot: _snapshot(_diplomacyState()),
          wireCommand: _wireCommand(const SubmitTurnCommand('player_1')),
          actorPlayerId: 'player_1',
          now: DateTime.utc(2026, 6, 30, 11, 1),
        );
        final save = GameSave.fromJson(reduction.snapshot.save);
        final state = PersistentGameState.fromJson(reduction.snapshot.state);

        expect(reduction.accepted, isTrue);
        expect(save.turn, 2);
        expect(state.runtimeState.timeoutStreaksByPlayerId, {'player_2': 1});
        expect(
          reduction.events.whereType<PlayerTimedOutEvent>().single.playerId,
          'player_2',
        );
      },
    );

    test('keeps waiting for connected players before the deadline', () async {
      final reducer = ServerCommandReducer(
        mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
      );

      final reduction = await reducer.reduce(
        match: _runningMatch(),
        snapshot: _snapshot(_diplomacyState()),
        wireCommand: _wireCommand(const SubmitTurnCommand('player_1')),
        actorPlayerId: 'player_1',
        now: DateTime.utc(2026, 6, 30, 11, 1),
      );
      final save = GameSave.fromJson(reduction.snapshot.save);
      final state = PersistentGameState.fromJson(reduction.snapshot.state);

      expect(reduction.accepted, isTrue);
      expect(save.turn, 1);
      expect(save.playerStates['player_1'], PlayerTurnState.finished);
      expect(state.runtimeState.submittedPlayerIds, {'player_1'});
      expect(reduction.events, isEmpty);
    });

    test('finalizes an already submitted turn after the deadline', () async {
      final reducer = ServerCommandReducer(
        mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
        turnTimeout: const Duration(seconds: 10),
      );
      final snapshot = _snapshot(
        _diplomacyState(
          runtimeState: GameRuntimeState(
            submittedPlayerIds: const {'player_1'},
            turnStartedAt: DateTime.utc(2026, 6, 30, 11),
          ),
        ),
        save: _save(
          playerStates: const {
            'player_1': PlayerTurnState.finished,
            'player_2': PlayerTurnState.active,
          },
        ),
      );

      final reduction = await reducer.reduce(
        match: _runningMatch(),
        snapshot: snapshot,
        wireCommand: _wireCommand(const SubmitTurnCommand('player_1')),
        actorPlayerId: 'player_1',
        now: DateTime.utc(2026, 6, 30, 11, 0, 11),
      );
      final save = GameSave.fromJson(reduction.snapshot.save);
      final state = PersistentGameState.fromJson(reduction.snapshot.state);

      expect(reduction.accepted, isTrue);
      expect(save.turn, 2);
      expect(state.runtimeState.timeoutStreaksByPlayerId, {'player_2': 1});
      expect(
        reduction.events.whereType<PlayerTimedOutEvent>().single.playerId,
        'player_2',
      );
    });

    test('does not wait for AI players in multiplayer snapshots', () async {
      final players = _wirePlayers();
      final aiPlayer = players[1].copyWith(
        kind: WirePlayerKind.ai,
        ai: const WireAiPlayer(
          strategyId: AiStrategyId.basic,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
        ),
      );
      final reducer = ServerCommandReducer(
        mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
      );

      final reduction = await reducer.reduce(
        match: _runningMatch(players: [players[0], aiPlayer]),
        snapshot: _snapshot(
          _diplomacyState(),
          save: _save(
            players: [
              _domainPlayers()[0],
              _domainPlayers()[1].copyWith(
                kind: PlayerKind.ai,
                ai: const AiPlayer(
                  strategyId: AiStrategyId.basic,
                  difficulty: AiDifficulty.normal,
                  persona: AiPersona.balanced,
                  seed: 1,
                ),
              ),
            ],
          ),
        ),
        wireCommand: _wireCommand(const SubmitTurnCommand('player_1')),
        actorPlayerId: 'player_1',
        now: DateTime.utc(2026, 6, 30, 11, 1),
      );
      final save = GameSave.fromJson(reduction.snapshot.save);

      expect(reduction.accepted, isTrue);
      expect(save.turn, 2);
    });

    test('advances artifact excavation once during finalization', () async {
      final unit = GameUnit.produced(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        col: 1,
        row: 1,
      ).copyWithExcavatingArtifact('artifact_1');
      const artifact = WorldArtifact(
        id: 'artifact_1',
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.excavation(
          unitId: 'scout_1',
          col: 1,
          row: 1,
          remainingTurns: 2,
        ),
      );
      final reducer = ServerCommandReducer(
        mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
      );

      final reduction = await reducer.reduce(
        match: _runningMatch(),
        snapshot: _snapshot(
          PersistentGameState(
            units: [unit],
            artifacts: const [artifact],
            runtimeState: const GameRuntimeState(
              submittedPlayerIds: {'player_1'},
            ),
          ),
          save: _save(
            playerStates: const {
              'player_1': PlayerTurnState.finished,
              'player_2': PlayerTurnState.active,
            },
          ),
        ),
        wireCommand: _wireCommand(
          const SubmitTurnCommand('player_2'),
          actorPlayerId: 'player_2',
        ),
        actorPlayerId: 'player_2',
        now: DateTime.utc(2026, 6, 30, 11, 1),
      );
      final state = PersistentGameState.fromJson(reduction.snapshot.state);

      expect(reduction.accepted, isTrue);
      expect(state.units.single.excavatingArtifactId, 'artifact_1');
      expect(state.units.single.carriedArtifactId, isNull);
      expect(state.artifacts.single.location.remainingTurns, 1);
    });
  });
}
