import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/infrastructure/transport/local_command_transport.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalCommandTransport', () {
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

    test('applies client-only commands without replay log entries', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final save = _save(players: const [_player1]);
      final repository = _MemoryGameRepository(
        SaveSnapshot(save: save, units: [commander]),
      );
      final eventLog = _MemoryEventLog();
      final transport = LocalCommandTransport(
        reducer: GameStateReducer(mapData: _map()),
        gameRepository: repository,
        eventLog: eventLog,
        snapshotStore: _MemorySnapshotStore(),
        clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
      );

      final result = await transport.dispatch(
        saveId: save.id,
        currentState: GameState(
          units: [commander],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
        command: SelectUnitCommand(commander.id),
        context: const GameCommandContext(actorPlayerId: 'player_1'),
      );

      expect(result.offset, 0);
      expect(result.state.selectedUnitId, commander.id);
      expect(result.storedSnapshot, isFalse);
      expect(eventLog.commands, isEmpty);
      expect(repository.snapshot.eventLogOffset, 0);
    });

    test(
      'logs authoritative movement instead of tile tap confirmation',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final save = _save(players: const [_player1]);
        final mapData = _map();
        final repository = _MemoryGameRepository(
          SaveSnapshot(save: save, units: [commander]),
        );
        final eventLog = _MemoryEventLog();
        final transport = LocalCommandTransport(
          reducer: GameStateReducer(mapData: mapData),
          gameRepository: repository,
          eventLog: eventLog,
          snapshotStore: _MemorySnapshotStore(),
          clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
        );
        final selectedState = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          interaction: GameInteractionState(
            selection: GameSelection.unit(
              commander,
              tile: mapData.tileAt(0, 0),
            ),
            moveCommandActive: true,
          ),
        );

        final preview = await transport.dispatch(
          saveId: save.id,
          currentState: selectedState,
          command: const TileTappedCommand(1, 0),
          context: const GameCommandContext(actorPlayerId: 'player_1'),
        );
        final moved = await transport.dispatch(
          saveId: save.id,
          currentState: preview.state,
          command: const TileTappedCommand(1, 0),
          context: const GameCommandContext(actorPlayerId: 'player_1'),
        );

        expect(preview.offset, 0);
        expect(preview.state.movePreview?.targetCol, 1);
        expect(eventLog.commands, hasLength(1));
        expect(
          eventLog.commands.single.command,
          isA<MoveUnitCommand>()
              .having((command) => command.unitId, 'unitId', commander.id)
              .having((command) => command.targetCol, 'targetCol', 1)
              .having((command) => command.targetRow, 'targetRow', 0),
        );
        expect(moved.offset, 1);
        expect(moved.state.units.single.col, 1);
        expect(repository.snapshot.eventLogOffset, 1);
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
          LoggedCommand(
            offset: 1,
            timestamp: DateTime.utc(2026, 4, 24, 11),
            turn: 1,
            command: const SetActivePlayerCommand('player_1', canAct: true),
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
        expect(
          result.uiEffects.whereType<AnimateUnitMoveEffect>().single,
          isA<AnimateUnitMoveEffect>()
              .having((effect) => effect.unitId, 'unitId', 'commander_player_1')
              .having((effect) => effect.fromCol, 'fromCol', 0)
              .having((effect) => effect.steps.last.col, 'last col', 2),
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
          result.uiEffects.whereType<AnimateUnitMoveEffect>().single,
          isA<AnimateUnitMoveEffect>()
              .having((effect) => effect.unitId, 'unitId', 'scout_1')
              .having((effect) => effect.fromCol, 'fromCol', 1)
              .having((effect) => effect.fromRow, 'fromRow', 0),
        );
      },
    );

    test('seeds combat resolution from the loaded save turn', () async {
      final attacker = GameUnit.produced(
        id: 'attacker',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final defender = GameUnit.produced(
        id: 'defender',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 1,
        row: 0,
      );
      final save = _save(players: const [_player1, _player2], turn: 7);
      final repository = _MemoryGameRepository(
        SaveSnapshot(save: save, units: [attacker, defender]),
      );
      final eventLog = _MemoryEventLog();
      final transport = LocalCommandTransport(
        reducer: GameStateReducer(mapData: _map()),
        gameRepository: repository,
        eventLog: eventLog,
        snapshotStore: _MemorySnapshotStore(),
        clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
      );

      final result = await transport.dispatch(
        saveId: save.id,
        currentState: GameState(
          units: [attacker, defender],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          fogOfWar: _visible('player_1', const [
            HexCoordinate(col: 0, row: 0),
            HexCoordinate(col: 1, row: 0),
          ]),
        ),
        command: const AttackHexCommand('attacker', 1, 0),
        context: const GameCommandContext(actorPlayerId: 'player_1'),
      );

      final outcome = result.events
          .whereType<CombatResolvedEvent>()
          .single
          .outcome;
      final seed = outcome.steps.whereType<RollStep>().first.seed;
      expect(
        seed,
        CombatRng.fromTurn(
          turn: 7,
          attackerId: 'attacker',
          defenderId: 'defender',
        ).seed,
      );
      expect(
        eventLog.commands.single.activity
            .where((entry) => entry.event is CombatResolvedEvent)
            .map((entry) => entry.playerId),
        ['player_1', 'player_2'],
      );
    });
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
  Future<SaveSnapshot> load(String saveId) async => snapshot;

  @override
  Future<void> save(SaveSnapshot snapshot) async {
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
  final commands = <LoggedCommand>[];

  @override
  Future<void> append(String saveId, LoggedCommand command) async {
    commands.add(command);
  }

  @override
  Future<int> latestOffset(String saveId) async {
    return commands.fold<int>(0, (latest, command) {
      return command.offset > latest ? command.offset : latest;
    });
  }

  @override
  Stream<LoggedCommand> readAll(String saveId) {
    return readSince(saveId);
  }

  @override
  Stream<LoggedCommand> readSince(String saveId, {int offset = 0}) async* {
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

const _damagedCity = GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'City 1',
  center: CityHex(col: 0, row: 0),
  hitPoints: 10,
);

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

MapData _map({int cols = 3, int rows = 3}) => MapData(
  cols: cols,
  rows: rows,
  tiles: [
    for (var row = 0; row < rows; row++)
      for (var col = 0; col < cols; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);
