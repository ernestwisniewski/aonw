import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/infrastructure/transport/local_command_transport.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cannot report a stored snapshot without carrying it', () {
    expect(
      () => CommandTransportResult(
        state: GameClientState(),
        snapshot: null,
        offset: 0,
        storedSnapshot: true,
      ),
      throwsAssertionError,
    );
  });

  group('CommandTransport contract: LocalCommandTransport', () {
    test(
      'dispatch applies the command, appends the log, and saves a snapshot',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final save = _save(players: const [_player1]);
        final repository = _MemoryGameRepository(
          GameSnapshotFactory.create(save: save, units: [commander]),
        );
        final eventLog = _MemoryEventLog();
        final transport = _transport(
          repository: repository,
          eventLog: eventLog,
          clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
        );

        final result = await transport.dispatch(
          saveId: save.id,
          currentState: GameClientState(
            units: [commander],
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
          ),
          command: MoveUnitCommand(commander.id, 1, 0),
          context: const GameCommandContext(actorPlayerId: 'player_1'),
        );

        expect(result.offset, 1);
        expect(result.state.units.single.col, 1);
        expect(result.snapshot, isNotNull);
        expect(result.snapshot!.eventLogOffset, 1);
        expect(result.storedSnapshot, isFalse);
        expect(eventLog.commands.single.offset, 1);
        expect(eventLog.commands.single.actorPlayerId, 'player_1');
        expect(repository.snapshot.units.single.col, 1);
        expect(repository.snapshot.save.savedAt, DateTime.utc(2026, 4, 24, 12));
      },
    );

    test(
      'dispatch stores a durable snapshot when the command requires it',
      () async {
        final save = _save(players: const [_player1, _player2]);
        final repository = _MemoryGameRepository(
          GameSnapshotFactory.create(save: save),
        );
        final snapshotStore = _MemorySnapshotStore();
        final transport = _transport(
          repository: repository,
          snapshotStore: snapshotStore,
          clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
        );

        final result = await transport.dispatch(
          saveId: save.id,
          currentState: GameClientState(activePlayerId: 'player_1'),
          command: const EndTurnCommand('player_1'),
        );

        expect(result.storedSnapshot, isTrue);
        expect(
          repository.snapshot.save.playerStates['player_1'],
          PlayerTurnState.finished,
        );
        expect(snapshotStore.latestSnapshot?.offset, result.offset);
        expect(
          snapshotStore.latestSnapshot?.state.save.playerStates['player_1'],
          PlayerTurnState.finished,
        );
      },
    );
  });
}

CommandTransport _transport({
  required _MemoryGameRepository repository,
  _MemoryEventLog? eventLog,
  _MemorySnapshotStore? snapshotStore,
  Clock? clock,
}) {
  return LocalCommandTransport(
    reducer: GameStateReducer(mapData: _map()),
    gameRepository: repository,
    eventLog: eventLog ?? _MemoryEventLog(),
    snapshotStore: snapshotStore ?? _MemorySnapshotStore(),
    clock: clock ?? _FixedClock(DateTime.utc(2026, 4, 24, 12)),
  );
}

class _FixedClock extends Clock {
  final DateTime value;

  const _FixedClock(this.value);

  @override
  DateTime now() => value;
}

class _MemoryGameRepository implements GameRepository {
  CanonicalGameSnapshot snapshot;

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
  Future<CanonicalGameSnapshot> load(String saveId) async => snapshot;

  @override
  Future<void> save(CanonicalGameSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Future<CanonicalGameSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    final updated = snapshot.withGameSave(
      snapshot.save.copyWith(
        camera: camera,
        savedAt: savedAt ?? snapshot.save.savedAt,
      ),
    );
    snapshot = updated;
    return updated;
  }
}

class _MemoryEventLog implements EventLog {
  final commands = <RecordedDomainCommand>[];

  @override
  Future<void> append(String saveId, RecordedDomainCommand command) async {
    commands.add(command);
  }

  @override
  Future<int> latestOffset(String saveId) async {
    return commands.fold<int>(0, (latest, command) {
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
    for (final command in commands) {
      if (command.offset >= offset) yield command;
    }
  }
}

class _MemorySnapshotStore implements SnapshotStore {
  Snapshot? latestSnapshot;

  @override
  Future<Snapshot?> latest(String saveId) async => latestSnapshot;

  @override
  Future<void> save(String saveId, Snapshot snapshot) async {
    latestSnapshot = snapshot;
  }
}

const _player1 = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);
const _player2 = Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050);

GameSave _save({required List<Player> players}) {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: {
      for (final player in players) player.id: PlayerTurnState.active,
    },
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: players,
  );
}

WorldMap _map() => WorldMap(
  cols: 3,
  rows: 3,
  tiles: [
    for (var row = 0; row < 3; row++)
      for (var col = 0; col < 3; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);
