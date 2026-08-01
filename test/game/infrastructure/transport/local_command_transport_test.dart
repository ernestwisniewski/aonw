import 'dart:convert';

import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/replay_store.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/services/game_intent_resolver.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/application/services/replay_service.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw/game/infrastructure/transport/local_command_transport.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

part 'local_command_transport_combat_tests.dart';
part 'local_command_transport_movement_presentation_tests.dart';
part 'local_command_transport_preview_fast_path_tests.dart';
part 'local_command_transport_test_support.dart';
part 'local_command_transport_unit_action_tests.dart';
part 'local_command_transport_worker_replay_tests.dart';
part 'local_command_transport_worker_replay_support.dart';

void main() {
  group('LocalCommandTransport', () {
    _registerWorkerReplayTests();
    _registerPreviewFastPathTests();
    _registerUnitActionTransportTests();
    _registerMovementPresentationTransportTests();
    _registerCombatTransportTests();

    test(
      'logs command events and saves the updated repository snapshot',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final save = _save(players: const [_player1]);
        final repository = _MemoryGameRepository(
          SaveSnapshot(save: save, units: [commander]),
        );
        final eventLog = _MemoryEventLog();
        final snapshotStore = _MemorySnapshotStore();
        final transport = LocalCommandTransport(
          reducer: GameStateReducer(mapData: _map()),
          gameRepository: repository,
          eventLog: eventLog,
          snapshotStore: snapshotStore,
          clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
        );

        final result = await transport.dispatch(
          saveId: save.id,
          currentState: GameState(
            units: [commander],
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
          ),
          command: MoveUnitCommand(commander.id, 1, 0),
          context: const GameCommandContext(actorPlayerId: 'player_1'),
        );

        expect(result.offset, 1);
        expect(result.state.units.single.col, 1);
        expect(result.events, isNotEmpty);
        expect(result.storedSnapshot, isFalse);
        expect(eventLog.commands.single.actorPlayerId, 'player_1');
        expect(eventLog.commands.single.events, isNotEmpty);
        expect(repository.snapshot.units.single.col, 1);
        expect(repository.snapshot.eventLogOffset, 1);
        expect(repository.snapshot.save.savedAt, DateTime.utc(2026, 4, 24, 12));
        expect(snapshotStore.latestSnapshot, isNull);
      },
    );

    test('stores periodic snapshots at the configured interval', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final save = _save(players: const [_player1]);
      final repository = _MemoryGameRepository(
        SaveSnapshot(save: save, units: [commander]),
      );
      final eventLog = _MemoryEventLog()
        ..commands.add(
          RecordedDomainCommand(
            offset: 1,
            timestamp: DateTime.utc(2026, 4, 24, 11),
            turn: 1,
            command: null,
          ),
        );
      final snapshotStore = _MemorySnapshotStore();
      final transport = LocalCommandTransport(
        reducer: GameStateReducer(mapData: _map()),
        gameRepository: repository,
        eventLog: eventLog,
        snapshotStore: snapshotStore,
        snapshotEvery: 2,
        clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
      );

      final result = await transport.dispatch(
        saveId: save.id,
        currentState: GameState(
          units: [commander],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
        command: MoveUnitCommand(commander.id, 1, 0),
      );

      expect(result.offset, 2);
      expect(result.storedSnapshot, isTrue);
      expect(snapshotStore.latestSnapshot?.offset, 2);
      expect(snapshotStore.latestSnapshot?.state.units.single.col, 1);
    });

    test(
      'end turn updates save turn metadata and always stores a snapshot',
      () async {
        final save = _save(players: const [_player1, _player2]);
        final repository = _MemoryGameRepository(SaveSnapshot(save: save));
        final snapshotStore = _MemorySnapshotStore();
        final transport = LocalCommandTransport(
          reducer: GameStateReducer(mapData: _map()),
          gameRepository: repository,
          eventLog: _MemoryEventLog(),
          snapshotStore: snapshotStore,
          clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
        );

        final result = await transport.dispatch(
          saveId: save.id,
          currentState: const GameState(activePlayerId: 'player_1'),
          command: const EndTurnCommand('player_1'),
        );

        expect(result.storedSnapshot, isTrue);
        expect(repository.snapshot.save.turn, 1);
        expect(
          repository.snapshot.save.playerStates['player_1'],
          PlayerTurnState.finished,
        );
        expect(
          snapshotStore.latestSnapshot?.state.save.playerStates['player_1'],
          PlayerTurnState.finished,
        );
      },
    );

    test('submit turn marks a local multiplayer player as finished', () async {
      final save = _save(
        players: const [_player1, _player2],
        gameMode: GameMode.multiplayer,
      );
      final repository = _MemoryGameRepository(SaveSnapshot(save: save));
      final transport = LocalCommandTransport(
        reducer: GameStateReducer(mapData: _map()),
        gameRepository: repository,
        eventLog: _MemoryEventLog(),
        snapshotStore: _MemorySnapshotStore(),
        clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
      );

      final result = await transport.dispatch(
        saveId: save.id,
        currentState: const GameState(
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
        command: const SubmitTurnCommand('player_1'),
      );

      expect(result.storedSnapshot, isTrue);
      expect(result.state.submittedPlayerIds, {'player_1'});
      expect(repository.snapshot.save.turn, 1);
      expect(
        repository.snapshot.save.playerStates['player_1'],
        PlayerTurnState.finished,
      );
      expect(result.events.whereType<AllPlayersSubmittedEvent>(), isEmpty);
    });

    test(
      'submit turn finalizes local multiplayer when all players submitted',
      () async {
        final save = _save(
          players: const [_player1, _player2],
          gameMode: GameMode.multiplayer,
          playerStates: const {
            'player_1': PlayerTurnState.finished,
            'player_2': PlayerTurnState.active,
          },
        );
        final repository = _MemoryGameRepository(
          SaveSnapshot(
            save: save,
            units: [_queuedCommander()],
            cities: const [_damagedCity],
            runtimeState: const GameRuntimeState(
              submittedPlayerIds: {'player_1'},
            ),
          ),
        );
        final transport = LocalCommandTransport(
          reducer: GameStateReducer(mapData: _map()),
          gameRepository: repository,
          eventLog: _MemoryEventLog(),
          snapshotStore: _MemorySnapshotStore(),
          clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
        );

        final result = await transport.dispatch(
          saveId: save.id,
          currentState: GameState(
            units: [_queuedCommander()],
            cities: const [_damagedCity],
            activePlayerId: 'player_2',
            activePlayerCanAct: true,
            submittedPlayerIds: const {'player_1'},
          ),
          command: const SubmitTurnCommand('player_2'),
        );

        expect(repository.snapshot.save.turn, 2);
        expect(
          repository.snapshot.save.playerStates.values,
          everyElement(PlayerTurnState.active),
        );
        expect(result.state.submittedPlayerIds, isEmpty);
        expect(repository.snapshot.units.single.col, 2);
        expect(repository.snapshot.units.single.row, 0);
        expect(repository.snapshot.cities.single.hitPoints, 11);
        final move = result.movementExecutions.single;
        expect(move.unitId, 'commander_player_1');
        expect((move.fromCol, move.fromRow), (0, 0));
        expect(
          [for (final step in move.steps) (step.col, step.row)],
          const [(1, 0), (2, 0)],
        );
        expect(
          result.events.whereType<AllPlayersSubmittedEvent>(),
          hasLength(1),
        );
        expect(result.events.whereType<TurnEndedEvent>(), hasLength(2));
      },
    );

    test(
      'submit turn emits animation effects for auto-exploring scout movement',
      () async {
        final scout =
            GameUnit.produced(
                  id: 'scout_1',
                  ownerPlayerId: 'player_1',
                  type: GameUnitType.scout,
                  col: 1,
                  row: 0,
                )
                .copyWith(movementPoints: 0)
                .copyWithPosture(UnitPosture.autoExploring);
        final fog = FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              discoveredHexes: {
                const HexCoordinate(col: 0, row: 0),
                const HexCoordinate(col: 1, row: 0),
                const HexCoordinate(col: 2, row: 0),
              },
              visibleHexes: {
                const HexCoordinate(col: 0, row: 0),
                const HexCoordinate(col: 1, row: 0),
                const HexCoordinate(col: 2, row: 0),
              },
            ),
          },
        );
        final save = _save(
          players: const [_player1, _player2],
          gameMode: GameMode.multiplayer,
          playerStates: const {
            'player_1': PlayerTurnState.finished,
            'player_2': PlayerTurnState.active,
          },
        );
        final repository = _MemoryGameRepository(
          SaveSnapshot(
            save: save,
            units: [scout],
            fogOfWar: fog,
            runtimeState: const GameRuntimeState(
              submittedPlayerIds: {'player_1'},
            ),
          ),
        );
        final transport = LocalCommandTransport(
          reducer: GameStateReducer(mapData: _map(cols: 6, rows: 1)),
          gameRepository: repository,
          eventLog: _MemoryEventLog(),
          snapshotStore: _MemorySnapshotStore(),
          clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
        );

        final result = await transport.dispatch(
          saveId: save.id,
          currentState: GameState(
            units: [scout],
            fogOfWar: fog,
            activePlayerId: 'player_2',
            activePlayerCanAct: true,
            submittedPlayerIds: const {'player_1'},
          ),
          command: const SubmitTurnCommand('player_2'),
        );

        final movedScout = result.state.units.single;
        expect(movedScout.id, 'scout_1');
        expect(movedScout.occupies(1, 0), isFalse);
        expect(
          result.movementExecutions.single,
          isA<MovementCommandExecution>()
              .having((effect) => effect.unitId, 'unitId', 'scout_1')
              .having((effect) => effect.fromCol, 'fromCol', 1)
              .having((effect) => effect.fromRow, 'fromRow', 0),
        );
      },
    );

    test(
      'submit turn advances artifact excavation once during finalization',
      () async {
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
        final save = _save(
          players: const [_player1, _player2],
          gameMode: GameMode.multiplayer,
          playerStates: const {
            'player_1': PlayerTurnState.finished,
            'player_2': PlayerTurnState.active,
          },
        );
        final repository = _MemoryGameRepository(
          SaveSnapshot(
            save: save,
            units: [unit],
            artifacts: const [artifact],
            runtimeState: const GameRuntimeState(
              submittedPlayerIds: {'player_1'},
            ),
          ),
        );
        final transport = LocalCommandTransport(
          reducer: GameStateReducer(mapData: _map()),
          gameRepository: repository,
          eventLog: _MemoryEventLog(),
          snapshotStore: _MemorySnapshotStore(),
          clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
        );

        final result = await transport.dispatch(
          saveId: save.id,
          currentState: GameState(
            units: [unit],
            artifacts: const [artifact],
            activePlayerId: 'player_2',
            activePlayerCanAct: true,
            submittedPlayerIds: const {'player_1'},
          ),
          command: const SubmitTurnCommand('player_2'),
        );

        expect(result.state.units.single.excavatingArtifactId, 'artifact_1');
        expect(result.state.units.single.carriedArtifactId, isNull);
        expect(result.state.artifacts.single.location.remainingTurns, 1);
        expect(repository.snapshot.artifacts.single.location.remainingTurns, 1);
      },
    );
  });
}

class _FixedClock extends Clock {
  final DateTime value;

  const _FixedClock(this.value);

  @override
  DateTime now() => value;
}

class _MemoryGameRepository implements GameRepository {
  SaveSnapshot snapshot;
  var loadCalls = 0;
  var saveCalls = 0;

  _MemoryGameRepository(this.snapshot);

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) async => snapshot.save.id;

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<List<GameSaveIndex>> list() async => const [];

  @override
  Future<SaveSnapshot> load(String saveId) async {
    loadCalls++;
    return snapshot;
  }

  @override
  Future<void> save(SaveSnapshot snapshot) async {
    saveCalls++;
    this.snapshot = snapshot;
  }

  @override
  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    throw UnimplementedError();
  }
}

class _MemoryEventLog implements EventLog {
  final commands = <RecordedDomainCommand>[];
  final int latestOffsetFloor;
  var accessCalls = 0;

  _MemoryEventLog({this.latestOffsetFloor = 0});

  @override
  Future<void> append(String saveId, RecordedDomainCommand command) async {
    accessCalls++;
    commands.add(command);
  }

  @override
  Future<int> latestOffset(String saveId) async {
    accessCalls++;
    return commands.fold<int>(latestOffsetFloor, (latest, command) {
      return command.offset > latest ? command.offset : latest;
    });
  }

  @override
  Stream<RecordedDomainCommand> readAll(String saveId) {
    return readSince(saveId);
  }

  @override
  Stream<RecordedDomainCommand> readSince(
    String saveId, {
    int offset = 0,
  }) async* {
    accessCalls++;
    for (final command in commands) {
      if (command.offset >= offset) yield command;
    }
  }
}

const _player1 = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);
const _player2 = Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050);

GameSave _save({
  required List<Player> players,
  int turn = 1,
  GameMode gameMode = GameMode.hotSeat,
  Map<String, PlayerTurnState>? playerStates,
}) {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: turn,
    playerStates:
        playerStates ??
        {for (final player in players) player.id: PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: players,
    gameMode: gameMode,
  );
}

FogOfWarState _visible(String playerId, Iterable<HexCoordinate> hexes) {
  return FogOfWarState(
    players: {
      playerId: PlayerFogOfWar(
        playerId: playerId,
        visibleHexes: Set<HexCoordinate>.of(hexes),
      ),
    },
  );
}

GameUnit _queuedCommander() {
  return GameUnit.startingCommander(ownerPlayerId: 'player_1')
      .copyWith(movementPoints: 0)
      .copyWithQueuedPath(
        QueuedMovePath(
          targetCol: 2,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
            UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
          ],
        ),
      );
}
