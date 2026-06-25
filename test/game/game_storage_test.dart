import 'dart:io';

import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/infrastructure/persistence/game_storage.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Player', () {
    test('round-trips through JSON', () {
      const player = Player(id: 'abc', name: 'Ernest', colorValue: 0xFF4a7fc4);
      final json = player.toJson();
      final back = Player.fromJson(json);
      expect(back.id, player.id);
      expect(back.name, player.name);
      expect(back.colorValue, player.colorValue);
    });

    test('palette uses vivid map-readable player colors', () {
      expect(Player.palette, const [
        0xFF3D5FA8,
        0xFFB83A3A,
        0xFF6D4A8C,
        0xFFC8741F,
      ]);
    });

    test('forIndex wraps palette cyclically', () {
      expect(Player.forIndex(0).colorValue, Player.palette[0]);
      expect(Player.forIndex(4).colorValue, Player.palette[0]);
    });
  });

  group('CameraState', () {
    test('round-trips through JSON', () {
      const cam = CameraState(x: 1.5, y: -2.0, zoom: 1.25);
      final json = cam.toJson();
      final back = CameraState.fromJson(json);
      expect(back.x, cam.x);
      expect(back.y, cam.y);
      expect(back.zoom, cam.zoom);
    });
  });

  group('GameUnit', () {
    test('startingCommander creates a general owned by the player', () {
      final unit = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      expect(unit.id, 'commander_player_1');
      expect(unit.ownerPlayerId, 'player_1');
      expect(unit.type, GameUnitType.commander);
      expect(unit.name, GameUnitType.commander.name);
      expect(unit.col, 0);
      expect(unit.row, 0);
    });

    test('round-trips through JSON', () {
      final unit = GameUnit(
        id: 'commander_player_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.commander,
        name: GameUnitType.commander.defaultNameToken,
        col: 2,
        row: 3,
      );
      final back = GameUnit.fromJson(unit.toJson());
      expect(back.id, unit.id);
      expect(back.ownerPlayerId, unit.ownerPlayerId);
      expect(back.type, unit.type);
      expect(back.name, unit.name);
      expect(back.col, 2);
      expect(back.row, 3);
    });
  });

  group('StartingUnits', () {
    test('creates one starting warrior per player', () {
      final units = StartingUnits.warriorsForPlayers(const [
        Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4),
        Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050),
        Player(id: 'player_3', name: 'Celina', colorValue: 0xFF50a050),
      ]);

      expect(units, hasLength(3));
      expect(units.map((unit) => unit.id), [
        'warrior_player_1',
        'warrior_player_2',
        'warrior_player_3',
      ]);
      expect(units.map((unit) => unit.type).toSet(), {GameUnitType.warrior});
      expect(units.map((unit) => unit.ownerPlayerId), [
        'player_1',
        'player_2',
        'player_3',
      ]);
      expect(
        units.map((unit) => '${unit.col}:${unit.row}').toSet(),
        hasLength(3),
      );
    });

    test(
      'uses separate land tiles near map corners when map data is available',
      () {
        final mapData = MapData(
          cols: 5,
          rows: 5,
          tiles: [
            for (var row = 0; row < 5; row++)
              for (var col = 0; col < 5; col++)
                TileData(
                  col: col,
                  row: row,
                  terrains: col == 0 && row == 0
                      ? const [TerrainType.ocean]
                      : const [TerrainType.plains],
                  resources: const [],
                  height: 0,
                ),
          ],
        );

        final units = StartingUnits.warriorsForPlayers(const [
          Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4),
          Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050),
          Player(id: 'player_3', name: 'Celina', colorValue: 0xFF50a050),
          Player(id: 'player_4', name: 'Darek', colorValue: 0xFFc4a020),
        ], mapData: mapData);

        expect(units, hasLength(4));
        expect(
          units.map((unit) => '${unit.col}:${unit.row}').toSet(),
          hasLength(4),
        );
        // Anchors are now quadrant centres: (cols/4, rows/4) = (1,1) and
        // (3*cols/4, 3*rows/4) = (3,3) for a 5x5 map.
        expect(units.first.col, 1);
        expect(units.first.row, 1);
        expect(units[1].col, 3);
        expect(units[1].row, 3);
      },
    );

    test('skips mixed-terrain mountain blockers when placing warriors', () {
      final mapData = MapData(
        cols: 3,
        rows: 3,
        tiles: [
          for (var row = 0; row < 3; row++)
            for (var col = 0; col < 3; col++)
              TileData(
                col: col,
                row: row,
                terrains: col == 0 && row == 0
                    ? const [TerrainType.grassland, TerrainType.mountain]
                    : const [TerrainType.plains],
                resources: const [],
                height: 0,
              ),
        ],
      );

      final units = StartingUnits.warriorsForPlayers(const [
        Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4),
      ], mapData: mapData);

      expect(units, hasLength(1));
      expect(units.single.col == 0 && units.single.row == 0, isFalse);
    });

    test(
      'keeps warriors inside the map when there are fewer tiles than players',
      () {
        final mapData = MapData(
          cols: 1,
          rows: 1,
          tiles: const [
            TileData(
              col: 0,
              row: 0,
              terrains: [TerrainType.plains],
              resources: [],
              height: 0,
            ),
          ],
        );

        final units = StartingUnits.warriorsForPlayers(const [
          Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4),
          Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050),
        ], mapData: mapData);

        expect(units, hasLength(2));
        expect(units.every((unit) => unit.col == 0 && unit.row == 0), isTrue);
      },
    );
  });

  group('GameSave', () {
    test('round-trips through JSON', () {
      final save = GameSave(
        id: '20260415_103000',
        name: 'Verdantia — 15 kwi 2026',
        mapName: 'verdantia',
        mapSource: MapSource.asset,
        turn: 12,
        playerStates: {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.finished,
        },
        savedAt: DateTime.utc(2026, 4, 15, 10, 30),
        camera: const CameraState(x: 0.0, y: 0.0, zoom: 1.0),
        players: const [
          Player(id: 'player_1', name: 'Ernest', colorValue: 0xFF4a7fc4),
          Player(id: 'player_2', name: 'Anna', colorValue: 0xFFc45050),
        ],
      );
      final json = save.toJson();
      final back = GameSave.fromJson(json);
      expect(back.id, save.id);
      expect(back.name, save.name);
      expect(back.mapName, save.mapName);
      expect(back.mapSource, save.mapSource);
      expect(back.turn, save.turn);
      expect(back.playerStates['player_1'], PlayerTurnState.active);
      expect(back.playerStates['player_2'], PlayerTurnState.finished);
      expect(back.savedAt, save.savedAt);
      expect(back.camera.x, save.camera.x);
      expect(back.camera.zoom, save.camera.zoom);
      expect(back.players.length, 2);
      expect(back.players[0].name, 'Ernest');
      expect(back.players[1].colorValue, 0xFFc45050);
    });

    test('fromJson with explicit empty players returns empty list', () {
      final json = {
        'id': 'x',
        'schemaVersion': gameSaveCurrentSchemaVersion,
        'name': 'n',
        'mapName': 'verdantia',
        'mapSource': 'asset',
        'turn': 1,
        'playerStates': <String, dynamic>{},
        'savedAt': '2026-04-15T00:00:00.000Z',
        'camera': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
        'ruleset': MatchRules.standard.toJson(),
        'players': <dynamic>[],
        'gameMode': 'hotSeat',
      };
      final back = GameSave.fromJson(json);
      expect(back.players, isEmpty);
    });
  });

  group('GameSaveIndex', () {
    test('fromJson reads id, name, mapName, turn, savedAt', () {
      final json = {
        'id': 'abc',
        'name': 'My Game',
        'mapName': 'verdantia',
        'mapSource': 'asset',
        'turn': 3,
        'savedAt': '2026-04-15T10:30:00.000Z',
        'camera': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
      };
      final idx = GameSaveIndex.fromJson(json);
      expect(idx.id, 'abc');
      expect(idx.name, 'My Game');
      expect(idx.mapName, 'verdantia');
      expect(idx.turn, 3);
      expect(idx.savedAt, DateTime.utc(2026, 4, 15, 10, 30));
    });
  });

  group('GameStorage.defaultSaveName', () {
    test('formats a language-neutral date stamp', () {
      final name = GameStorage.defaultSaveName(
        'Verdantia',
        DateTime(2026, 4, 15),
      );
      expect(name, 'Verdantia — 2026-04-15');
    });

    test('zero-pads single digit month and day', () {
      final name = GameStorage.defaultSaveName('X', DateTime(2026, 1, 5));
      expect(name, 'X — 2026-01-05');
    });
  });

  group('GameStorage directory helpers', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('game_storage_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('deleteSave removes entire folder', () async {
      const id = 'save_to_delete';
      Directory('${tempDir.path}/$id').createSync(recursive: true);
      File('${tempDir.path}/$id/snapshot.json').writeAsStringSync('{}');

      await GameStorage.deleteSave(id, savesDir: tempDir);

      expect(Directory('${tempDir.path}/$id').existsSync(), isFalse);
    });
  });
}
