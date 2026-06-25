import 'dart:convert';
import 'dart:io';

import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/id_generator.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/infrastructure/persistence/json_game_repository.dart';
import 'package:aonw/game/infrastructure/persistence/json_replay_store.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonGameRepository', () {
    late Directory tempDir;
    late JsonGameRepository repository;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('json_game_repo_');
      repository = JsonGameRepository(
        savesDir: tempDir,
        clock: _FixedClock(_fixedNow),
        idGenerator: _SequenceIdGenerator(),
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('creates and loads a snapshot-only save', () async {
      const players = [
        Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4),
        Player(id: 'p2', name: 'Bob', colorValue: 0xFFc45050),
      ];

      final saveId = await repository.create(
        const NewGameRequest(
          name: 'Campaign',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
          players: players,
        ),
      );

      final snapshot = await repository.load(saveId);

      expect(snapshot.save.name, 'Campaign');
      expect(snapshot.playerColors, {'p1': 0xFF4a7fc4, 'p2': 0xFFc45050});
      expect(snapshot.playerCountries, {
        'p1': PlayerCountry.poland,
        'p2': PlayerCountry.poland,
      });
      expect(snapshot.units.map((unit) => unit.ownerPlayerId).toSet(), {
        'p1',
        'p2',
      });
      expect(snapshot.runtimeState, GameRuntimeState.empty);
      expect(
        await File('${tempDir.path}/$saveId/snapshot.json').exists(),
        isTrue,
      );
      expect(saveId, 'save_1');
      expect(snapshot.save.matchRules, MatchRules.standard);
      expect(snapshot.save.savedAt, _fixedNow);
      expect(await File('${tempDir.path}/$saveId/game.json').exists(), isFalse);
      expect(
        await File('${tempDir.path}/$saveId/units.json').exists(),
        isFalse,
      );
    });

    test('stores match rules from new game request', () async {
      final matchRules = MatchRules.forGameLength(GameLengthConfig.standard60);

      final saveId = await repository.create(
        NewGameRequest(
          name: 'Blitz',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
          matchRules: matchRules,
        ),
      );

      final snapshot = await repository.load(saveId);
      expect(snapshot.save.matchRules, matchRules);
    });

    test('marks unreadable saves as corrupted in list()', () async {
      final saveId = await repository.create(
        const NewGameRequest(
          name: 'Old save',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
        ),
      );
      final snapshotFile = File('${tempDir.path}/$saveId/snapshot.json');
      final raw =
          jsonDecode(await snapshotFile.readAsString()) as Map<String, dynamic>;
      ((raw['state'] as Map<String, dynamic>)['save']
              as Map<String, dynamic>)['schemaVersion'] =
          2;
      await snapshotFile.writeAsString(jsonEncode(raw));

      final saves = await repository.list();

      expect(saves, hasLength(1));
      expect(saves.single.id, saveId);
      expect(saves.single.corrupted, isTrue);
      expect(
        saves.single.corruptionMessage,
        contains('Unsupported save schema'),
      );
      await expectLater(repository.load(saveId), throwsA(isA<StateError>()));
    });

    test('creates new saves with known fog around starting warriors', () async {
      const players = [Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4)];
      final mapData = MapData(
        cols: 5,
        rows: 5,
        tiles: [
          for (var row = 0; row < 5; row++)
            for (var col = 0; col < 5; col++)
              TileData(
                col: col,
                row: row,
                terrains: const [TerrainType.plains],
                resources: const [],
                height: 0,
              ),
        ],
      );

      final saveId = await repository.create(
        NewGameRequest(
          name: 'Campaign',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
          players: players,
          mapData: mapData,
        ),
      );

      final snapshot = await repository.load(saveId);
      final warrior = snapshot.units.singleWhere(
        (unit) => unit.type == GameUnitType.warrior,
      );
      final settler = snapshot.units.singleWhere(
        (unit) => unit.type == GameUnitType.settler,
      );

      expect(warrior.army, isEmpty);
      expect(settler.ownerPlayerId, 'p1');
      expect(
        '${settler.col}:${settler.row}',
        isNot('${warrior.col}:${warrior.row}'),
      );
      expect(snapshot.fogOfWar.playerIds, contains('p1'));
      expect(
        snapshot.fogOfWar.isKnown(
          'p1',
          HexCoordinate(col: warrior.col, row: warrior.row),
        ),
        isTrue,
      );
    });

    test('uses start position seed when creating initial units', () async {
      const players = [
        Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4),
        Player(id: 'p2', name: 'Bob', colorValue: 0xFFc45050),
        Player(id: 'p3', name: 'Celina', colorValue: 0xFF50a050),
        Player(id: 'p4', name: 'Darek', colorValue: 0xFFc4a020),
      ];
      final mapData = _flatMap(cols: 8, rows: 8);

      final saveId = await repository.create(
        NewGameRequest(
          name: 'Campaign',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
          players: players,
          mapData: mapData,
          startPositionSeed: 11,
        ),
      );

      final snapshot = await repository.load(saveId);
      final expectedUnits = StartingUnits.unitsForPlayers(
        players,
        mapData: mapData,
        startPositionSeed: 11,
      );

      expect(
        _warriorPositionsByPlayer(snapshot.units),
        _warriorPositionsByPlayer(expectedUnits),
      );
    });

    test('saves complete state to snapshot.json only', () async {
      final saveId = await repository.create(
        const NewGameRequest(
          name: 'Game',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
        ),
      );
      final original = await repository.load(saveId);
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'p1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
      );
      final unit = GameUnit.startingCommander(ownerPlayerId: 'p1');

      await repository.save(
        SaveSnapshot(
          save: original.save.copyWith(turn: 3),
          playerColors: const {'p1': 0xFF4a7fc4},
          units: [unit],
          cities: [city],
          runtimeState: const GameRuntimeState(
            pendingAction: PendingCityWorkedHexSelection(
              ownerPlayerId: 'p1',
              cityId: 'city_1',
            ),
          ),
          eventLogOffset: 7,
        ),
      );

      final reloaded = await repository.load(saveId);
      expect(reloaded.save.turn, 3);
      expect(reloaded.units.single.id, unit.id);
      expect(reloaded.cities.single.id, city.id);
      expect(reloaded.eventLogOffset, 7);
      expect(
        reloaded.runtimeState.pendingAction,
        isA<PendingCityWorkedHexSelection>(),
      );
      expect(await File('${tempDir.path}/$saveId/game.json').exists(), isFalse);
      expect(
        await File('${tempDir.path}/$saveId/cities.json').exists(),
        isFalse,
      );
      expect(
        await File('${tempDir.path}/$saveId/runtime_state.json').exists(),
        isFalse,
      );
    });

    test('keeps replay initial snapshot immutable after later saves', () async {
      final saveId = await repository.create(
        const NewGameRequest(
          name: 'Game',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
        ),
      );
      final original = await repository.load(saveId);
      final replayStore = JsonReplayStore(savesDir: tempDir);

      await repository.save(
        original.copyWith(
          save: original.save.copyWith(turn: 5),
          eventLogOffset: 12,
        ),
      );

      final replaySeed = await replayStore.initialSnapshot(saveId);
      final current = await repository.load(saveId);
      final listed = await repository.list();

      expect(replaySeed, isNotNull);
      expect(replaySeed!.save.turn, 1);
      expect(replaySeed.eventLogOffset, 0);
      expect(current.save.turn, 5);
      expect(current.eventLogOffset, 12);
      expect(listed.single.replayAvailable, isTrue);
      expect(
        await File(
          '${tempDir.path}/$saveId/replay_initial_snapshot.json',
        ).exists(),
        isTrue,
      );
    });

    test(
      'load reads snapshot.json even when stray legacy files exist',
      () async {
        final saveId = await repository.create(
          const NewGameRequest(
            name: 'Game',
            mapName: 'verdantia',
            mapSource: MapSource.asset,
          ),
        );
        final original = await repository.load(saveId);
        final unit = GameUnit.startingCommander(
          ownerPlayerId: 'p1',
          col: 2,
          row: 1,
        );

        await repository.save(
          SaveSnapshot(
            save: original.save.copyWith(turn: 4),
            units: [unit],
            eventLogOffset: 11,
          ),
        );

        await File('${tempDir.path}/$saveId/units.json').writeAsString('[]');

        final reloaded = await repository.load(saveId);
        expect(reloaded.save.turn, 4);
        expect(reloaded.units.single.id, unit.id);
        expect(reloaded.eventLogOffset, 11);
      },
    );
  });
}

final _fixedNow = DateTime.utc(2026, 4, 24, 12);

class _FixedClock extends Clock {
  final DateTime value;

  const _FixedClock(this.value);

  @override
  DateTime now() => value;
}

class _SequenceIdGenerator implements IdGenerator {
  int _next = 1;

  @override
  String nextId() => 'save_${_next++}';
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
            resources: const [],
            height: 0,
          ),
    ],
  );
}

Map<String, String> _warriorPositionsByPlayer(List<GameUnit> units) {
  return {
    for (final unit in units.where((unit) => unit.type == GameUnitType.warrior))
      unit.ownerPlayerId: '${unit.col}:${unit.row}',
  };
}
