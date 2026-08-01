import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/event_log_replay_service.dart';
import 'package:aonw/game/application/use_cases/bootstrap_game_state_use_case.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGameRepository implements GameRepository {
  final Map<String, CanonicalGameSnapshot> snapshots;
  final bool throwOnLoad;

  _FakeGameRepository({required this.snapshots, this.throwOnLoad = false});

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) async => 'save';

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<List<GameSaveIndex>> list() async => const [];

  @override
  Future<CanonicalGameSnapshot> load(String saveId) async {
    if (throwOnLoad) throw StateError('broken save');
    final snapshot = snapshots[saveId];
    if (snapshot == null) throw StateError('missing save');
    return snapshot;
  }

  @override
  Future<void> save(CanonicalGameSnapshot snapshot) async {}

  @override
  Future<CanonicalGameSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    throw UnimplementedError();
  }
}

class _SequenceGameRepository extends _FakeGameRepository {
  final List<CanonicalGameSnapshot> sequence;
  var loadCount = 0;

  _SequenceGameRepository(this.sequence) : super(snapshots: const {});

  @override
  Future<CanonicalGameSnapshot> load(String saveId) async {
    if (sequence.isEmpty) throw StateError('missing save');
    final index = loadCount < sequence.length ? loadCount : sequence.length - 1;
    loadCount++;
    return sequence[index];
  }
}

class _FakeCommandTransport implements CommandTransport {
  DomainCommand? command;
  final List<DomainCommand> commands = [];
  GameCommandContext? context;
  GameClientState? currentState;

  @override
  Future<CommandTransportResult> dispatch({
    required String saveId,
    required GameClientState currentState,
    required DomainCommand command,
    GameCommandContext context = const GameCommandContext(),
    bool fromMovePreviewConfirmation = false,
  }) async {
    this.command = command;
    commands.add(command);
    this.context = context;
    this.currentState = currentState;
    return CommandTransportResult(
      state: currentState.copyWithInteraction(moveCommandActive: true),
      snapshot: GameSnapshotFactory.create(save: _save),
      offset: 1,
    );
  }
}

class _FakeEventLog implements EventLog {
  final List<RecordedDomainCommand> commands;

  const _FakeEventLog(this.commands);

  @override
  Future<void> append(String saveId, RecordedDomainCommand command) async {}

  @override
  Stream<RecordedDomainCommand> readSince(String saveId, {int offset = 0}) {
    return Stream.fromIterable(
      commands.where((command) => command.offset >= offset),
    );
  }

  @override
  Stream<RecordedDomainCommand> readAll(String saveId) => readSince(saveId);

  @override
  Future<int> latestOffset(String saveId) async {
    var latest = 0;
    for (final command in commands) {
      if (command.offset > latest) latest = command.offset;
    }
    return latest;
  }
}

const _player = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);

final _save = GameSave(
  id: 'save_1',
  name: 'Game',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 1,
  playerStates: const {'player_1': PlayerTurnState.active},
  savedAt: DateTime.utc(2026, 4, 16),
  camera: CameraState.zero,
  players: const [_player],
);

void main() {
  test('loads a snapshot with active player already synchronized', () async {
    final transport = _FakeCommandTransport();
    final useCase = BootstrapGameStateUseCase(
      repository: _FakeGameRepository(
        snapshots: {
          _save.id: GameSnapshotFactory.create(
            save: _save,
            playerColors: const {'player_1': 0xFF4a7fc4},
          ),
        },
      ),
      dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
    );

    final state = await useCase.execute(saveId: _save.id);

    expect(state.activePlayerId, 'player_1');
    expect(state.moveCommandActive, isFalse);
    expect(transport.command, isNull);
    expect(state.playerColors, const {'player_1': 0xFF4a7fc4});
  });

  test('prefers the requested player when bootstrapping control', () async {
    final transport = _FakeCommandTransport();
    final save = _save.copyWith(
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
      players: const [
        _player,
        Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050),
      ],
    );
    final useCase = BootstrapGameStateUseCase(
      repository: _FakeGameRepository(
        snapshots: {save.id: GameSnapshotFactory.create(save: save)},
      ),
      dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
    );

    final state = await useCase.execute(
      saveId: save.id,
      preferredPlayerId: 'player_2',
    );

    expect(state.activePlayerId, 'player_2');
    expect(transport.command, isNull);
  });

  test(
    'does not send turn-start presentation through command transport',
    () async {
      final transport = _FakeCommandTransport();
      final save = _save.copyWith(gameMode: GameMode.multiplayer);
      final useCase = BootstrapGameStateUseCase(
        repository: _FakeGameRepository(
          snapshots: {save.id: GameSnapshotFactory.create(save: save)},
        ),
        dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
      );

      await useCase.execute(saveId: save.id);

      expect(transport.commands, isEmpty);
    },
  );

  test('replays multiplayer events after a stale snapshot', () async {
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final transport = _FakeCommandTransport();
    final save = _save.copyWith(gameMode: GameMode.multiplayer);
    final useCase = BootstrapGameStateUseCase(
      repository: _FakeGameRepository(
        snapshots: {
          save.id: GameSnapshotFactory.fromClientState(
            save: save,
            state: GameClientState(units: [commander]),
            eventLogOffset: 1,
          ),
        },
      ),
      dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
      eventReplay: EventLogReplayService(
        eventLog: _FakeEventLog([
          RecordedDomainCommand(
            offset: 2,
            timestamp: DateTime.utc(2026, 4, 16, 12),
            turn: 1,
            actorPlayerId: 'player_1',
            command: MoveUnitCommand(commander.id, 1, 0),
          ),
        ]),
        reducer: GameStateReducer(mapData: _map()),
      ),
    );

    final result = await useCase.executeWithResult(saveId: save.id);

    expect(result.offset, 2);
    expect(result.state.units.single.col, 1);
    expect(transport.commands, isEmpty);
  });

  test('reloads the authoritative snapshot after redacted history', () async {
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final save = _save.copyWith(gameMode: GameMode.multiplayer);
    final first = GameSnapshotFactory.fromClientState(
      save: save,
      state: GameClientState(units: [commander]),
      eventLogOffset: 1,
    );
    final second = GameSnapshotFactory.fromClientState(
      save: save,
      state: GameClientState(units: [commander.copyWith(col: 1)]),
      eventLogOffset: 2,
    );
    final repository = _SequenceGameRepository([first, second]);
    final transport = _FakeCommandTransport();
    final useCase = BootstrapGameStateUseCase(
      repository: repository,
      dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
      eventReplay: EventLogReplayService(
        eventLog: _FakeEventLog([
          RecordedDomainCommand(
            offset: 2,
            timestamp: DateTime.utc(2026, 4, 16, 12),
            turn: 1,
            actorPlayerId: 'player_2',
            command: null,
          ),
        ]),
        reducer: GameStateReducer(mapData: _map()),
      ),
    );

    final result = await useCase.executeWithResult(saveId: save.id);

    expect(repository.loadCount, 2);
    expect(result.offset, 2);
    expect(result.state.units.single.col, 1);
    expect(transport.commands, isEmpty);
  });

  test(
    'returns only the latest snapshot when both replay attempts redact',
    () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final save = _save.copyWith(gameMode: GameMode.multiplayer);
      final snapshot = GameSnapshotFactory.fromClientState(
        save: save,
        state: GameClientState(units: [commander]),
        eventLogOffset: 1,
      );
      final repository = _SequenceGameRepository([snapshot, snapshot]);
      final transport = _FakeCommandTransport();
      final useCase = BootstrapGameStateUseCase(
        repository: repository,
        dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
        eventReplay: EventLogReplayService(
          eventLog: _FakeEventLog([
            RecordedDomainCommand(
              offset: 2,
              timestamp: DateTime.utc(2026, 4, 16, 12),
              turn: 1,
              actorPlayerId: 'player_2',
              command: null,
            ),
          ]),
          reducer: GameStateReducer(mapData: _map()),
        ),
      );

      final result = await useCase.executeWithResult(saveId: save.id);

      expect(repository.loadCount, 2);
      expect(result.offset, 1);
      expect(result.state.units.single.col, 0);
      expect(result.state.activePlayerId, 'player_1');
      expect(transport.commands, isEmpty);
    },
  );

  test('surfaces repository load failures', () async {
    final transport = _FakeCommandTransport();
    final useCase = BootstrapGameStateUseCase(
      repository: _FakeGameRepository(snapshots: const {}, throwOnLoad: true),
      dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
    );

    await expectLater(
      useCase.execute(saveId: 'broken'),
      throwsA(isA<StateError>()),
    );
    expect(transport.command, isNull);
  });
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
