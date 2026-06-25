import 'dart:io';

import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/id_generator.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/infrastructure/persistence/json_game_repository.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameRepository contract: JsonGameRepository', () {
    late Directory tempDir;
    late GameRepository repository;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'game_repository_contract_',
      );
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

    test('create makes a loadable save and a list entry', () async {
      final saveId = await repository.create(
        const NewGameRequest(
          name: 'Contract Game',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
          players: [_player1, _player2],
        ),
      );

      final snapshot = await repository.load(saveId);
      final saves = await repository.list();

      expect(snapshot.save.id, saveId);
      expect(saveId, 'save_1');
      expect(snapshot.save.name, 'Contract Game');
      expect(snapshot.save.savedAt, _fixedNow);
      expect(snapshot.save.players.map((player) => player.id), [
        'player_1',
        'player_2',
      ]);
      expect(snapshot.playerColors, {
        'player_1': 0xFF4a7fc4,
        'player_2': 0xFFc45050,
      });
      expect(saves.map((save) => save.id), contains(saveId));
    });

    test('save persists the complete snapshot for later load', () async {
      final saveId = await repository.create(
        const NewGameRequest(
          name: 'Contract Game',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
        ),
      );
      final original = await repository.load(saveId);
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 1, row: 1),
      );
      final unit = GameUnit.startingCommander(ownerPlayerId: 'player_1');

      await repository.save(
        SaveSnapshot(
          save: original.save.copyWith(turn: 4),
          playerColors: const {'player_1': 0xFF4a7fc4},
          units: [unit],
          cities: [city],
          runtimeState: const GameRuntimeState(
            pendingAction: PendingCityWorkedHexSelection(
              ownerPlayerId: 'player_1',
              cityId: 'city_1',
            ),
          ),
          eventLogOffset: 9,
        ),
      );

      final reloaded = await repository.load(saveId);

      expect(reloaded.save.turn, 4);
      expect(reloaded.playerColors, {'player_1': 0xFF4a7fc4});
      expect(reloaded.units.single.id, unit.id);
      expect(reloaded.cities.single.id, city.id);
      expect(
        reloaded.runtimeState.pendingAction,
        isA<PendingCityWorkedHexSelection>(),
      );
      expect(reloaded.eventLogOffset, 9);
    });

    test('saveCamera updates camera metadata and persists it', () async {
      final saveId = await repository.create(
        const NewGameRequest(
          name: 'Contract Game',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
        ),
      );
      final savedAt = DateTime.utc(2026, 4, 24, 12);
      const camera = CameraState(x: 10, y: 20, zoom: 1.5);

      final updated = await repository.saveCamera(
        saveId,
        camera,
        savedAt: savedAt,
      );
      final reloaded = await repository.load(saveId);

      expect(updated.save.camera.toJson(), camera.toJson());
      expect(updated.save.savedAt, savedAt);
      expect(reloaded.save.camera.toJson(), camera.toJson());
      expect(reloaded.save.savedAt, savedAt);
    });

    test('delete removes the save from the list', () async {
      final saveId = await repository.create(
        const NewGameRequest(
          name: 'Contract Game',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
        ),
      );

      await repository.delete(saveId);

      expect(
        (await repository.list()).map((save) => save.id),
        isNot(contains(saveId)),
      );
    });
  });
}

const _player1 = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);
const _player2 = Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050);

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
