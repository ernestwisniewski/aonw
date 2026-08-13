part of '../server_command_reducer_test.dart';

const _turnTimeoutReducerDriver = ServerCommandReducerTestDriver();

void _registerServerCommandReducerTurnTimeoutTests() {
  group('ServerCommandReducer turn timeouts', () {
    test(
      'finalizes when the remaining unsubmitted player is offline',
      () async {
        final players = _wirePlayers();
        final reducer = ServerCommandReducer(
          mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
        );

        final reduction = await _turnTimeoutReducerDriver.reduce(
          reducer: reducer,
          match: _runningMatch(
            players: [
              players[0],
              players[1].copyWith(
                connectionState: WirePlayerConnectionState.offline,
              ),
            ],
          ),
          wireSnapshot: _snapshot(_diplomacyState()),
          wireCommand: _wireCommand(const SubmitTurnCommand('player_1')),
          actorPlayerId: 'player_1',
          now: DateTime.utc(2026, 6, 30, 11, 1),
        );
        final nextSnapshot = reduction.nextSnapshot!;

        expect(reduction.accepted, isTrue);
        expect(nextSnapshot.domain.turn, 2);
        expect(nextSnapshot.domain.timeoutStreaksByPlayerId, {'player_2': 1});
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

      final reduction = await _turnTimeoutReducerDriver.reduce(
        reducer: reducer,
        match: _runningMatch(),
        wireSnapshot: _snapshot(_diplomacyState()),
        wireCommand: _wireCommand(const SubmitTurnCommand('player_1')),
        actorPlayerId: 'player_1',
        now: DateTime.utc(2026, 6, 30, 11, 1),
      );
      final nextSnapshot = reduction.nextSnapshot!;

      expect(reduction.accepted, isTrue);
      expect(nextSnapshot.domain.turn, 1);
      expect(
        nextSnapshot.domain.turnStatesByPlayerId['player_1'],
        PlayerTurnState.finished,
      );
      expect(nextSnapshot.domain.submittedPlayerIds, {'player_1'});
      expect(reduction.events, isEmpty);
      expect(reduction.movementExecutions, isEmpty);
    });

    test(
      'preserves global queued and automatic movement execution order',
      _preservesGlobalTurnMovementExecutionOrder,
    );

    test('finalizes an already submitted turn after the deadline', () async {
      final reducer = ServerCommandReducer(
        mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
        turnTimeout: const Duration(seconds: 10),
      );
      final snapshot = _snapshot(
        _diplomacyState(
          submittedPlayerIds: const {'player_1'},
          turnStartedAt: DateTime.utc(2026, 6, 30, 11),
        ),
        save: _save(
          playerStates: const {
            'player_1': PlayerTurnState.finished,
            'player_2': PlayerTurnState.active,
          },
        ),
      );

      final reduction = await _turnTimeoutReducerDriver.reduce(
        reducer: reducer,
        match: _runningMatch(),
        wireSnapshot: snapshot,
        wireCommand: _wireCommand(const SubmitTurnCommand('player_1')),
        actorPlayerId: 'player_1',
        now: DateTime.utc(2026, 6, 30, 11, 0, 11),
      );
      final nextSnapshot = reduction.nextSnapshot!;

      expect(reduction.accepted, isTrue);
      expect(nextSnapshot.domain.turn, 2);
      expect(nextSnapshot.domain.timeoutStreaksByPlayerId, {'player_2': 1});
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

      final reduction = await _turnTimeoutReducerDriver.reduce(
        reducer: reducer,
        match: _runningMatch(players: [players[0], aiPlayer]),
        wireSnapshot: _snapshot(
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

      expect(reduction.accepted, isTrue);
      expect(reduction.nextSnapshot!.domain.turn, 2);
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

      final reduction = await _turnTimeoutReducerDriver.reduce(
        reducer: reducer,
        match: _runningMatch(),
        wireSnapshot: _snapshot(
          DomainState.snapshot(
            participants: _domainPlayers(),
            units: [unit],
            artifacts: const [artifact],

            submittedPlayerIds: {'player_1'},
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
      final domain = reduction.nextSnapshot!.domain;

      expect(reduction.accepted, isTrue);
      expect(domain.units.single.excavatingArtifactId, 'artifact_1');
      expect(domain.units.single.carriedArtifactId, isNull);
      expect(domain.artifacts.single.location.remainingTurns, 1);
    });
  });
}

Future<void> _preservesGlobalTurnMovementExecutionOrder() async {
  final reduction = await _turnTimeoutReducerDriver.reduce(
    reducer: ServerCommandReducer(
      mapCatalog: _FakeMapCatalog(_turnMovementExecutionMap()),
    ),
    match: _runningMatch(),
    wireSnapshot: _turnMovementExecutionSnapshot(),
    wireCommand: _wireCommand(
      const SubmitTurnCommand('player_2'),
      actorPlayerId: 'player_2',
    ),
    actorPlayerId: 'player_2',
    now: DateTime.utc(2026, 6, 30, 11, 1),
  );
  final domain = reduction.nextSnapshot!.domain;

  expect(reduction.accepted, isTrue);
  expect(
    (domain.units.byId('unit_a')!.col, domain.units.byId('unit_a')!.row),
    (3, 0),
  );
  expect(
    (domain.units.byId('unit_b')!.col, domain.units.byId('unit_b')!.row),
    (1, 1),
  );
  expect(reduction.movementExecutions.map(_movementExecutionSnapshot), [
    'unit_a:0,0->1,0;enter=2;total=2',
    'unit_b:0,1->1,1;enter=2;total=2',
    'unit_a:1,0->2,0;enter=2;total=2|3,0;enter=2;total=4',
  ]);
  expect(() => reduction.movementExecutions.clear(), throwsUnsupportedError);
}

WireSnapshot _turnMovementExecutionSnapshot() {
  return _snapshot(
    _diplomacyState(submittedPlayerIds: {'player_1'}).copyWith(
      units: [
        _queuedTurnMovementUnit(
          id: 'unit_a',
          ownerPlayerId: 'player_1',
          type: GameUnitType.scout,
          row: 0,
          posture: UnitPosture.autoExploring,
        ),
        _queuedTurnMovementUnit(
          id: 'unit_b',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          row: 1,
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': _originFog(playerId: 'player_1', row: 0),
          'player_2': _originFog(playerId: 'player_2', row: 1),
        },
      ),
    ),
    save: _save(
      playerStates: const {
        'player_1': PlayerTurnState.finished,
        'player_2': PlayerTurnState.active,
      },
    ),
  );
}

GameUnit _queuedTurnMovementUnit({
  required String id,
  required String ownerPlayerId,
  required GameUnitType type,
  required int row,
  UnitPosture posture = UnitPosture.active,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: id,
    col: 0,
    row: row,
    movementPoints: 0,
    posture: posture,
  ).copyWithQueuedPath(
    QueuedMovePath(
      targetCol: 1,
      targetRow: row,
      steps: [
        UnitMovementStep(col: 0, row: row, enterCost: 0, cumulativeCost: 0),
        UnitMovementStep(col: 1, row: row, enterCost: 2, cumulativeCost: 2),
      ],
    ),
  );
}

PlayerFogOfWar _originFog({required String playerId, required int row}) {
  final origin = HexCoordinate(col: 0, row: row);
  return PlayerFogOfWar(
    playerId: playerId,
    discoveredHexes: {origin},
    visibleHexes: {origin},
  );
}

String _movementExecutionSnapshot(MovementCommandExecution execution) {
  final steps = execution.steps
      .map(
        (step) =>
            '${step.col},${step.row};enter=${step.enterCost};'
            'total=${step.cumulativeCost}',
      )
      .join('|');
  return '${execution.unitId}:${execution.fromCol},${execution.fromRow}->$steps';
}

WorldMap _turnMovementExecutionMap() {
  return WorldMap(
    cols: 6,
    rows: 2,
    tiles: [
      for (var row = 0; row < 2; row++)
        for (var col = 0; col < 6; col++)
          WorldTile(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
