import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentTurnPipeline', () {
    test('advancePlayer advances one player without simultaneous events', () {
      final result = PersistentTurnPipeline.advancePlayer(
        state: const PersistentGameState(),
        playerId: 'player_1',
        mapData: _mapData(),
      );

      expect(result.events.whereType<AllPlayersSubmittedEvent>(), isEmpty);
      expect(
        result.events.whereType<TurnEndedEvent>().map(
          (event) => event.playerId,
        ),
        ['player_1'],
      );
    });

    test(
      'advancePlayer applies plain peace decay when turn number is unknown',
      () {
        const state = PersistentGameState(
          playerWarWeariness: {'player_1': 7},
          runtimeState: GameRuntimeState(
            diplomacy: DiplomacyState(
              relations: {
                'player_1|player_2': DiplomaticRelation(
                  playerAId: 'player_1',
                  playerBId: 'player_2',
                  status: DiplomaticRelationStatus.truce,
                  lastChangedTurn: 1,
                ),
              },
            ),
          ),
        );

        final result = PersistentTurnPipeline.advancePlayer(
          state: state,
          playerId: 'player_1',
          mapData: _mapData(),
        );

        expect(result.state.playerWarWeariness['player_1'], 6);
      },
    );

    test(
      'simultaneousFinalize advances a shared turn and clears submissions',
      () {
        const state = PersistentGameState(
          runtimeState: GameRuntimeState(
            submittedPlayerIds: {'player_1', 'player_2'},
            intendedAttacks: [
              IntendedAttack(
                attackerUnitId: 'missing_attacker',
                defenderCol: 2,
                defenderRow: 2,
                declaredAtTick: 1,
                declaringPlayerId: 'player_1',
              ),
            ],
          ),
        );

        final result = PersistentTurnPipeline.simultaneousFinalize(
          PersistentTurnPipelineRequest.simultaneousFinalize(
            save: _save(),
            state: state,
            playerIds: const ['player_2', 'player_1', 'player_1'],
            savedAt: _savedAt,
            worldMap: _worldMap(),
          ),
        );

        expect(result.save.turn, 2);
        expect(result.save.savedAt, _savedAt.toUtc());
        expect(
          result.save.playerStates.values,
          everyElement(PlayerTurnState.active),
        );
        expect(result.state.runtimeState.submittedPlayerIds, isEmpty);
        expect(result.state.runtimeState.intendedAttacks, isEmpty);
        expect(result.state.runtimeState.turnStartedAt, _savedAt.toUtc());
        expect(result.events.first, isA<AllPlayersSubmittedEvent>());
        expect(
          result.events.whereType<AllPlayersSubmittedEvent>().single.playerIds,
          ['player_2', 'player_1'],
        );
        expect(
          result.events.whereType<TurnEndedEvent>().map(
            (event) => event.playerId,
          ),
          ['player_2', 'player_1'],
        );
      },
    );

    test('simultaneousFinalize preserves server-only finished players', () {
      final result = PersistentTurnPipeline.simultaneousFinalize(
        PersistentTurnPipelineRequest.simultaneousFinalize(
          save: _save(
            playerStates: const {
              'player_1': PlayerTurnState.active,
              'player_2': PlayerTurnState.active,
              'player_3': PlayerTurnState.finished,
            },
          ),
          state: const PersistentGameState(),
          playerIds: const ['player_1', 'player_2'],
          skippedPlayerIds: const ['player_2'],
          savedAt: _savedAt,
          worldMap: _worldMap(),
          preserveNonParticipantPlayerStates: true,
          trackTimeoutStreaks: true,
        ),
      );

      expect(result.save.turn, 2);
      expect(result.save.playerStates['player_1'], PlayerTurnState.active);
      expect(result.save.playerStates['player_2'], PlayerTurnState.active);
      expect(result.save.playerStates['player_3'], PlayerTurnState.finished);
      expect(result.state.runtimeState.timeoutStreaksByPlayerId, {
        'player_2': 1,
      });
      expect(
        result.events.whereType<PlayerTimedOutEvent>().map(
          (event) => event.playerId,
        ),
        ['player_2'],
      );
    });

    test('simultaneousFinalize advances artifact excavation only once', () {
      final unit = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        name: GameUnitType.scout.defaultNameToken,
        col: 1,
        row: 1,
        excavatingArtifactId: 'artifact_1',
      );
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

      final result = PersistentTurnPipeline.simultaneousFinalize(
        PersistentTurnPipelineRequest.simultaneousFinalize(
          save: _save(),
          state: PersistentGameState(
            units: [unit],
            artifacts: const [artifact],
          ),
          playerIds: const ['player_1', 'player_2'],
          savedAt: _savedAt,
          worldMap: _worldMap(),
        ),
      );

      expect(result.state.units.single.excavatingArtifactId, 'artifact_1');
      expect(result.state.units.single.carriedArtifactId, isNull);
      expect(result.state.artifacts.single.location.isBeingExcavated, isTrue);
      expect(result.state.artifacts.single.location.remainingTurns, 1);
    });
  });
}

final _savedAt = DateTime.utc(2026, 7, 9, 12);

GameSave _save({
  Map<String, PlayerTurnState> playerStates = const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.active,
  },
}) {
  return GameSave(
    id: 'save_1',
    name: 'Save 1',
    mapName: 'test_map',
    turn: 1,
    playerStates: playerStates,
    savedAt: DateTime.utc(2026, 7, 9),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Player 1', colorValue: 0xFF000001),
      Player(id: 'player_2', name: 'Player 2', colorValue: 0xFF000002),
      Player(id: 'player_3', name: 'Player 3', colorValue: 0xFF000003),
    ],
  );
}

MapData _mapData() {
  return MapData(
    cols: 3,
    rows: 3,
    tiles: [
      for (var col = 0; col < 3; col++)
        for (var row = 0; row < 3; row++)
          TileData(
            col: col,
            row: row,
            terrains: [TerrainType.grassland],
            resources: const [],
            height: 1,
          ),
    ],
  );
}

WorldMap _worldMap() => LegacyWorldMapAdapter.fromMapData(_mapData());
