import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _one = 'player_1';
const _two = 'player_2';
final _savedAt = DateTime.utc(2026, 7, 30, 12);

void main() {
  group('player turn commands', () {
    test('partial submit records readiness without advancing the turn', () {
      final snapshot = _snapshot();

      final accepted = _accepted(
        _apply(snapshot, const SubmitTurnCommand(_one)),
      );

      expect(accepted.snapshot.domain.turn, 7);
      expect(accepted.snapshot.session.submittedPlayerIds, {_one});
      expect(accepted.snapshot.session.turnStatesByPlayerId, {
        _one: PlayerTurnState.finished,
        _two: PlayerTurnState.active,
      });
      expect(accepted.events, isEmpty);
    });

    test('all submitted players finalize in exact canonical event order', () {
      final snapshot = _snapshot(submittedPlayerIds: {_one});

      final accepted = _accepted(
        _apply(snapshot, const SubmitTurnCommand(_two), actorPlayerId: _two),
      );

      expect(accepted.snapshot.domain.turn, 8);
      expect(accepted.snapshot.session.submittedPlayerIds, isEmpty);
      expect(accepted.events.map((event) => event.runtimeType).toList(), [
        AllPlayersSubmittedEvent,
        TurnEndedEvent,
        TurnEndedEvent,
      ]);
      expect(
        accepted.events.whereType<TurnEndedEvent>().map(
          (event) => event.playerId,
        ),
        [_one, _two],
      );
    });

    test('sequential end finalizes only the acting player', () {
      final snapshot = _snapshot(gameMode: GameMode.hotSeat);

      final accepted = _accepted(_apply(snapshot, const EndTurnCommand(_one)));

      expect(accepted.snapshot.domain.turn, 7);
      expect(accepted.events.map((event) => event.runtimeType).toList(), [
        TurnEndedEvent,
      ]);
      expect(accepted.snapshot.session.turnStatesByPlayerId, {
        _one: PlayerTurnState.finished,
        _two: PlayerTurnState.active,
      });
    });

    test('sequential end begins the next player turn atomically', () {
      final snapshot = _snapshot(
        gameMode: GameMode.hotSeat,
        participants: const [
          Player(id: _two, name: 'Two', colorValue: 2),
          Player(id: _one, name: 'One', colorValue: 1),
        ],
        units: [
          GameUnit(
            id: 'queued_unit',
            ownerPlayerId: _one,
            type: GameUnitType.warrior,
            name: GameUnitType.warrior.defaultNameToken,
            col: 0,
            row: 0,
            movementPoints: 0,
            queuedPath: QueuedMovePath(
              targetCol: 1,
              targetRow: 0,
              steps: const [
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
              ],
            ),
          ),
        ],
      );

      final accepted = _accepted(
        _apply(
          snapshot,
          const EndTurnCommand(_two),
          actorPlayerId: _two,
          turnPlayerIds: const [_two, _one],
        ),
      );

      expect(accepted.snapshot.eventLogOffset, snapshot.eventLogOffset);
      expect(accepted.snapshot.domain.units.single.col, 1);
      expect(accepted.snapshot.domain.units.single.queuedPath, isNull);
      expect(accepted.events.map((event) => event.runtimeType), [
        TurnEndedEvent,
        UnitMovedEvent,
      ]);
      expect(accepted.movementDelta.beforeUnits.single.col, 0);
      expect(accepted.movementDelta.afterUnits.single.col, 1);
      expect(accepted.movementDelta.executions, hasLength(1));
      expect(accepted.movementDelta.executions.single.unitId, 'queued_unit');
    });

    test('sequential end advances the round after the last player', () {
      final snapshot =
          _snapshot(
            gameMode: GameMode.hotSeat,
            participants: const [
              Player(id: _two, name: 'Two', colorValue: 2),
              Player(id: _one, name: 'One', colorValue: 1),
            ],
            units: [
              GameUnit(
                id: 'queued_unit',
                ownerPlayerId: _two,
                type: GameUnitType.warrior,
                name: GameUnitType.warrior.defaultNameToken,
                col: 0,
                row: 0,
                movementPoints: 0,
                queuedPath: QueuedMovePath(
                  targetCol: 1,
                  targetRow: 0,
                  steps: const [
                    UnitMovementStep(
                      col: 1,
                      row: 0,
                      enterCost: 1,
                      cumulativeCost: 1,
                    ),
                  ],
                ),
              ),
            ],
          ).copyWith(
            session: _snapshot(gameMode: GameMode.hotSeat).session.copyWith(
              turnStatesByPlayerId: const {
                _two: PlayerTurnState.finished,
                _one: PlayerTurnState.active,
              },
            ),
          );

      final accepted = _accepted(
        _apply(
          snapshot,
          const EndTurnCommand(_one),
          turnPlayerIds: const [_two, _one],
        ),
      );

      expect(accepted.snapshot.domain.turn, 8);
      expect(accepted.snapshot.session.turnStatesByPlayerId, {
        _one: PlayerTurnState.active,
        _two: PlayerTurnState.active,
      });
      expect(accepted.snapshot.domain.units.single.col, 1);
      expect(accepted.movementDelta.executions, hasLength(1));
    });

    test('simultaneous finalization begins players exactly once', () {
      final snapshot = _snapshot(
        submittedPlayerIds: {_one},
        units: [
          GameUnit(
            id: 'queued_unit',
            ownerPlayerId: _two,
            type: GameUnitType.warrior,
            name: GameUnitType.warrior.defaultNameToken,
            col: 0,
            row: 0,
            movementPoints: 0,
            queuedPath: QueuedMovePath(
              targetCol: 1,
              targetRow: 0,
              steps: const [
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
              ],
            ),
          ),
        ],
      );

      final accepted = _accepted(
        _apply(snapshot, const SubmitTurnCommand(_two), actorPlayerId: _two),
      );

      expect(accepted.snapshot.domain.turn, 8);
      expect(accepted.snapshot.domain.units.single.col, 1);
      expect(accepted.snapshot.domain.units.single.queuedPath, isNull);
      expect(accepted.movementDelta.beforeUnits.single.col, 0);
      expect(accepted.movementDelta.afterUnits.single.col, 1);
      expect(accepted.movementDelta.executions, hasLength(1));
    });

    test('duplicate submit is an accepted identity no-op', () {
      final snapshot = _snapshot(submittedPlayerIds: {_one});

      final accepted = _accepted(
        _apply(snapshot, const SubmitTurnCommand(_one)),
      );

      expect(accepted.snapshot, same(snapshot));
      expect(accepted.events, isEmpty);

      final completedSnapshot = _snapshot(submittedPlayerIds: {_one, _two});
      final completedDuplicate = _accepted(
        _apply(
          completedSnapshot,
          const SubmitTurnCommand(_two),
          actorPlayerId: _two,
        ),
      );
      expect(completedDuplicate.snapshot, same(completedSnapshot));
      expect(completedDuplicate.events, isEmpty);
    });
  });

  group('server system commands', () {
    test(
      'timeout finalizes and reports skipped players before turn events',
      () {
        final snapshot = _snapshot(submittedPlayerIds: {_one});

        final accepted = _accepted(
          _applySystem(
            snapshot,
            const FinalizeTimedOutTurn(
              playerIds: [_one, _two],
              skippedPlayerIds: [_two],
            ),
          ),
        );

        expect(accepted.snapshot.domain.turn, 8);
        expect(accepted.events.map((event) => event.runtimeType).toList(), [
          PlayerTimedOutEvent,
          AllPlayersSubmittedEvent,
          TurnEndedEvent,
          TurnEndedEvent,
        ]);
        expect(accepted.snapshot.session.timeoutStreaksByPlayerId, {_two: 1});
      },
    );

    test('kick removes readiness and marks the participant unavailable', () {
      final snapshot = _snapshot(submittedPlayerIds: {_one});

      final accepted = _accepted(
        _applySystem(
          snapshot,
          const KickParticipant(
            playerId: _one,
            reason: 'turn_timeout',
            timeoutStreak: 3,
          ),
        ),
      );

      expect(accepted.snapshot.session.kickedPlayerIds, {_one});
      expect(accepted.snapshot.session.afkPlayerIds, {_one});
      expect(accepted.snapshot.session.submittedPlayerIds, isEmpty);
      expect(
        accepted.snapshot.session.turnStatesByPlayerId[_one],
        PlayerTurnState.finished,
      );
      expect(
        accepted.events.single,
        isA<PlayerKickedEvent>()
            .having((event) => event.playerId, 'playerId', _one)
            .having((event) => event.reason, 'reason', 'turn_timeout')
            .having((event) => event.timeoutStreak, 'timeoutStreak', 3),
      );
    });

    test('kick accepts a canonical participant with sparse turn state', () {
      final base = _snapshot();
      final snapshot = base.copyWith(
        domain: base.domain.copyWith(
          participants: const [Player(id: _one, name: 'One', colorValue: 1)],
        ),
        session: base.session.copyWith(turnStatesByPlayerId: const {}),
      );

      final accepted = _accepted(
        _applySystem(
          snapshot,
          const KickParticipant(
            playerId: _one,
            reason: 'resignation',
            timeoutStreak: 0,
          ),
        ),
      );

      expect(accepted.snapshot.session.turnStatesByPlayerId, isEmpty);
      expect(accepted.snapshot.session.afkPlayerIds, contains(_one));
      expect(accepted.snapshot.session.kickedPlayerIds, contains(_one));
    });

    test('kick rejects an identity outside the canonical roster', () {
      final snapshot = _snapshot();
      final result = _applySystem(
        snapshot,
        const KickParticipant(
          playerId: 'ghost',
          reason: 'resignation',
          timeoutStreak: 0,
        ),
      );

      expect(result, isA<GameEngineRejected>());
      expect((result as GameEngineRejected).reason, 'turn_player_not_active');
    });

    test('canonical snapshot rejects a stale turn-state-only identity', () {
      final base = _snapshot();

      expect(
        () => base.copyWith(
          session: base.session.copyWith(
            turnStatesByPlayerId: {
              ...base.session.turnStatesByPlayerId,
              'ghost': PlayerTurnState.active,
            },
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}

GameEngineResult _apply(
  CanonicalGameSnapshot snapshot,
  DomainCommand command, {
  String actorPlayerId = _one,
  List<String> turnPlayerIds = const [_one, _two],
}) {
  return const GameEngine().apply(
    snapshot: snapshot,
    command: command,
    context: GameEngineContext(
      actorPlayerId: actorPlayerId,
      mapView: _map,
      ruleset: GameRuleset.defaults,
      commandTick: 7,
      turnPlayerIds: turnPlayerIds,
      requiredTurnSubmissionPlayerIds: turnPlayerIds,
      savedAt: _savedAt,
    ),
  );
}

GameEngineResult _applySystem(
  CanonicalGameSnapshot snapshot,
  SystemCommand command,
) {
  return const GameEngine().applySystem(
    snapshot: snapshot,
    command: command,
    context: GameEngineContext(
      actorPlayerId: 'server',
      mapView: _map,
      ruleset: GameRuleset.defaults,
      commandTick: 7,
      savedAt: _savedAt,
    ),
  );
}

GameEngineAccepted _accepted(GameEngineResult result) {
  expect(result, isA<GameEngineAccepted>());
  return result as GameEngineAccepted;
}

CanonicalGameSnapshot _snapshot({
  GameMode gameMode = GameMode.multiplayer,
  Set<String> submittedPlayerIds = const {},
  List<GameUnit> units = const [],
  List<Player> participants = const [
    Player(id: _one, name: 'One', colorValue: 1),
    Player(id: _two, name: 'Two', colorValue: 2),
  ],
}) {
  return CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: 7,
      matchRules: MatchRules.standard,
      participants: participants,
      units: units,
    ),
    session: MatchSessionState.snapshot(
      gameMode: gameMode,
      turnStatesByPlayerId: const {
        _one: PlayerTurnState.active,
        _two: PlayerTurnState.active,
      },
      submittedPlayerIds: submittedPlayerIds,
      turnStartedAt: DateTime.utc(2026, 7, 30, 11),
    ),
    metadata: GameSnapshotMetadata(
      id: 'turn',
      schemaVersion: 3,
      name: 'Turn',
      world: const WorldReference(name: 'turn', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 30, 11),
      camera: GameSnapshotCamera.zero,
    ),
  );
}

final _map = WorldMapReadView(
  WorldMap(
    cols: 2,
    rows: 1,
    tiles: [
      WorldTile(
        coordinate: const HexCoord(col: 0, row: 0),
        terrains: const [TerrainType.grassland],
        resources: const [],
        height: 0,
      ),
      WorldTile(
        coordinate: const HexCoord(col: 1, row: 0),
        terrains: const [TerrainType.grassland],
        resources: const [],
        height: 0,
      ),
    ],
  ),
);
