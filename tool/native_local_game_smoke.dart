import 'dart:io';

import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/id_generator.dart';
import 'package:aonw/game/application/use_cases/bootstrap_game_state_use_case.dart';
import 'package:aonw/game/application/use_cases/create_local_game_use_case.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/infrastructure/persistence/json_event_log.dart';
import 'package:aonw/game/infrastructure/persistence/json_game_repository.dart';
import 'package:aonw/game/infrastructure/persistence/json_snapshot_store.dart';
import 'package:aonw/game/infrastructure/transport/local_command_transport.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/map_validation.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _runSmoke();
    exit(0);
  } catch (error, stackTrace) {
    stderr
      ..writeln('Native local-game smoke failed: $error')
      ..writeln(stackTrace);
    exit(1);
  }
}

Future<void> _runSmoke() async {
  final workspace = await Directory.systemTemp.createTemp(
    'aonw_native_local_game_smoke_',
  );
  try {
    final savesDir = Directory('${workspace.path}/saves');
    final map = _flatMap(cols: 20, rows: 20);
    const players = [
      Player(id: 'player_1', name: 'Alice', colorValue: 0xFF3D5FA8),
      Player(id: 'player_2', name: 'Bob', colorValue: 0xFFB83A3A),
    ];
    final validation = MapValidator.validate(
      mapData: map,
      playerCount: players.length,
      gameLength: MatchRules.standard.gameLength,
    );
    _require(validation.errors.isEmpty, 'Smoke map must be valid.');

    final first = _LocalRuntime.open(savesDir: savesDir, mapData: map);
    final saveId =
        await CreateLocalGameUseCase(
          repository: first.repository,
          clock: const _FixedClock(),
        ).execute(
          name: 'Native local smoke',
          selection: const MapSelection(
            name: 'native_smoke_map',
            source: MapSource.saved,
          ),
          mapData: map,
          gameMode: GameMode.hotSeat,
          matchRules: MatchRules.standard,
          players: players,
          startPositionSeed: 17,
        );
    final initial = await first.bootstrap.executeWithResult(saveId: saveId);

    final ended = await first.dispatch.execute(
      saveId: saveId,
      currentState: initial.state,
      command: const EndTurnCommand('player_1'),
      context: const GameCommandContext(actorPlayerId: 'player_1'),
    );

    _require(ended.offset == 1, 'End turn must advance the event offset.');
    _require(ended.storedSnapshot, 'End turn must persist a snapshot.');
    _require(
      ended.state.domain.turnStatesByPlayerId['player_1'] ==
          PlayerTurnState.finished,
      'End turn must persist player_1 as finished.',
    );

    final fresh = _LocalRuntime.open(savesDir: savesDir, mapData: map);
    final events = await fresh.eventLog.readAll(saveId).toList();
    final reloaded = await fresh.bootstrap.executeWithResult(saveId: saveId);

    _require(events.length == 1, 'Fresh runtime must read one command.');
    _require(
      events.single.command == const EndTurnCommand('player_1'),
      'Fresh runtime must read the persisted EndTurn command.',
    );
    _require(reloaded.offset == ended.offset, 'Reloaded offset must match.');
    _require(
      reloaded.state.domain == ended.state.domain,
      'Reloaded canonical domain must match the saved state.',
    );

    stdout.writeln(
      'Native local-game smoke passed: End turn -> save -> fresh reload.',
    );
  } finally {
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  }
}

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

final class _LocalRuntime {
  const _LocalRuntime({
    required this.repository,
    required this.eventLog,
    required this.dispatch,
    required this.bootstrap,
  });

  factory _LocalRuntime.open({
    required Directory savesDir,
    required WorldMap mapData,
  }) {
    const clock = _FixedClock();
    final snapshotStore = JsonSnapshotStore(savesDir: savesDir, clock: clock);
    final repository = JsonGameRepository(
      savesDir: savesDir,
      snapshotStore: snapshotStore,
      clock: clock,
      idGenerator: const _FixedIdGenerator(),
    );
    final eventLog = JsonEventLog(savesDir: savesDir);
    final dispatch = DispatchCommandUseCase(
      commandTransport: LocalCommandTransport(
        reducer: GameStateReducer(mapData: mapData),
        gameRepository: repository,
        eventLog: eventLog,
        snapshotStore: snapshotStore,
        snapshotEvery: 1,
        clock: clock,
      ),
    );
    return _LocalRuntime(
      repository: repository,
      eventLog: eventLog,
      dispatch: dispatch,
      bootstrap: BootstrapGameStateUseCase(
        repository: repository,
        dispatchCommand: dispatch,
      ),
    );
  }

  final JsonGameRepository repository;
  final JsonEventLog eventLog;
  final DispatchCommandUseCase dispatch;
  final BootstrapGameStateUseCase bootstrap;
}

final class _FixedClock extends Clock {
  const _FixedClock();

  @override
  DateTime now() => DateTime.utc(2026, 8, 11, 12);
}

final class _FixedIdGenerator implements IdGenerator {
  const _FixedIdGenerator();

  @override
  String nextId() => 'native_local_smoke';
}

WorldMap _flatMap({required int cols, required int rows}) {
  return WorldMap(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          WorldTile(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [
              ResourceType.wheat,
              ResourceType.iron,
              ResourceType.gold,
            ],
            height: 0,
          ),
    ],
  );
}
