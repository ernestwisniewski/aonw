import 'dart:io';

import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/id_generator.dart';
import 'package:aonw/game/application/use_cases/bootstrap_game_state_use_case.dart';
import 'package:aonw/game/application/use_cases/create_local_game_use_case.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/infrastructure/persistence/json_event_log.dart';
import 'package:aonw/game/infrastructure/persistence/json_game_repository.dart';
import 'package:aonw/game/infrastructure/persistence/json_snapshot_store.dart';
import 'package:aonw/game/infrastructure/transport/local_command_transport.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/persistence/map_catalog.dart';
import 'package:aonw/map/persistence/map_loader.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/map_validation.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'creates, saves, and reloads a local game with fresh adapters',
    () async {
      final workspaceDir = await Directory.systemTemp.createTemp(
        'local_game_persistence_flow_',
      );
      addTearDown(() async {
        if (await workspaceDir.exists()) {
          await workspaceDir.delete(recursive: true);
        }
      });
      final savesDir = Directory('${workspaceDir.path}/saves');
      final mapsDir = Directory('${workspaceDir.path}/maps');

      const selection = MapSelection(
        name: 'critical_map',
        source: MapSource.saved,
      );
      const players = [
        Player(id: 'player_1', name: 'Alice', colorValue: 0xFF3D5FA8),
        Player(id: 'player_2', name: 'Bob', colorValue: 0xFFB83A3A),
      ];
      final mapData = _flatMap(cols: 20, rows: 20);
      final validation = MapValidator.validate(
        mapData: mapData,
        playerCount: players.length,
        gameLength: MatchRules.standard.gameLength,
      );
      expect(validation.errors, isEmpty);
      await _persistSavedMap(
        mapsDir: mapsDir,
        selection: selection,
        mapData: mapData,
      );
      final firstRuntime = _LocalRuntime.open(
        savesDir: savesDir,
        mapData: mapData,
        clock: _FixedClock(_createdAt),
      );
      final createGame = CreateLocalGameUseCase(
        repository: firstRuntime.repository,
        clock: _FixedClock(_createdAt),
      );

      expect(createGame.defaultNameFor(selection), 'Critical Map — 2026-07-14');
      final saveId = await createGame.execute(
        name: '   ',
        selection: selection,
        mapData: mapData,
        gameMode: GameMode.hotSeat,
        matchRules: MatchRules.standard,
        players: players,
        startPositionSeed: 17,
      );
      final initial = await firstRuntime.bootstrap.executeWithResult(
        saveId: saveId,
      );
      final warrior = initial.state.units.singleWhere(
        (unit) =>
            unit.ownerPlayerId == players.first.id &&
            unit.type == GameUnitType.warrior,
      );

      expect(saveId, 'critical_save');
      expect(initial.offset, 0);
      expect(initial.state.activePlayerId, players.first.id);
      expect(warrior.posture, UnitPosture.active);

      final fortified = await firstRuntime.dispatch.execute(
        saveId: saveId,
        currentState: initial.state,
        command: FortifyUnitCommand(warrior.id),
        context: const GameCommandContext(actorPlayerId: 'player_1'),
      );

      expect(fortified.offset, 1);
      expect(fortified.storedSnapshot, isTrue);
      expect(
        fortified.state.unitById(warrior.id)?.posture,
        UnitPosture.fortified,
      );
      expect(fortified.state.unitById(warrior.id)?.movementPoints, 0);

      final metadataRepository = JsonGameRepository(
        savesDir: savesDir,
        snapshotStore: JsonSnapshotStore(
          savesDir: savesDir,
          clock: _FixedClock(_reloadedAt),
        ),
        clock: _FixedClock(_reloadedAt),
        idGenerator: const _FixedIdGenerator(),
      );
      final saves = await metadataRepository.list();
      expect(saves, hasLength(1));
      expect(saves.single.id, saveId);
      expect(saves.single.name, 'Critical Map — 2026-07-14');
      expect(saves.single.mapName, selection.name);
      expect(saves.single.mapSource, selection.source);

      final persistedSelection = MapSelection(
        name: saves.single.mapName,
        source: saves.single.mapSource,
      );
      final reloadedMap = await MapCatalog.loadMap(
        persistedSelection,
        savedMapsDirectory: mapsDir,
      );
      expect(reloadedMap.mapName, selection.name);
      expect(reloadedMap.cols, mapData.cols);
      expect(reloadedMap.rows, mapData.rows);

      final freshRuntime = _LocalRuntime.open(
        savesDir: savesDir,
        mapData: reloadedMap,
        clock: _FixedClock(_reloadedAt),
      );
      final commands = await freshRuntime.eventLog.readAll(saveId).toList();
      final reloaded = await freshRuntime.bootstrap.executeWithResult(
        saveId: saveId,
      );
      final reloadedWarrior = reloaded.state.unitById(warrior.id);

      expect(await freshRuntime.eventLog.latestOffset(saveId), 1);
      expect(commands, hasLength(1));
      expect(commands.single.offset, 1);
      expect(commands.single.actorPlayerId, players.first.id);
      expect(commands.single.command, FortifyUnitCommand(warrior.id));
      expect(reloaded.offset, 1);
      expect(reloaded.state.activePlayerId, players.first.id);
      expect(reloadedWarrior?.posture, UnitPosture.fortified);
      expect(reloadedWarrior?.movementPoints, 0);
    },
  );
}

final _createdAt = DateTime.utc(2026, 7, 14, 10);
final _reloadedAt = DateTime.utc(2026, 7, 14, 11);

class _LocalRuntime {
  final JsonGameRepository repository;
  final JsonEventLog eventLog;
  final DispatchCommandUseCase dispatch;
  final BootstrapGameStateUseCase bootstrap;

  const _LocalRuntime({
    required this.repository,
    required this.eventLog,
    required this.dispatch,
    required this.bootstrap,
  });

  factory _LocalRuntime.open({
    required Directory savesDir,
    required MapData mapData,
    required Clock clock,
  }) {
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
}

class _FixedClock extends Clock {
  final DateTime value;

  const _FixedClock(this.value);

  @override
  DateTime now() => value;
}

class _FixedIdGenerator implements IdGenerator {
  const _FixedIdGenerator();

  @override
  String nextId() => 'critical_save';
}

MapData _flatMap({required int cols, required int rows}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
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

Future<void> _persistSavedMap({
  required Directory mapsDir,
  required MapSelection selection,
  required MapData mapData,
}) async {
  final file = File('${mapsDir.path}/${selection.name}/map.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(MapLoader.toJson(mapData), flush: true);
}
