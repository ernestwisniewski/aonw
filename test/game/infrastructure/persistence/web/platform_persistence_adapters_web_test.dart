import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/id_generator.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/infrastructure/persistence/web/platform_persistence_adapters_web.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_database.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  test(
    'platform adapters delegate through one lazily resolved database',
    () async {
      final database = await WebDatabase.open(
        name: 'platform-adapters-test.db',
        factory: newDatabaseFactoryMemory(),
      );
      addTearDown(database.close);
      final databaseFuture = Future.value(database);
      final repository = createPlatformGameRepository(
        clock: const _FixedClock(),
        idGenerator: _SequenceIdGenerator(),
        databaseFuture: databaseFuture,
      );
      final eventLog = createPlatformEventLog(databaseFuture: databaseFuture);
      final snapshotStore = createPlatformSnapshotStore(
        clock: const _FixedClock(),
        databaseFuture: databaseFuture,
      );
      final replayStore = createPlatformReplayStore(
        databaseFuture: databaseFuture,
      );

      expect(
        repository.defaultSaveName('Verdantia', DateTime.utc(2026, 8, 1)),
        'Verdantia — 2026-08-01',
      );
      final saveId = await repository.create(
        const NewGameRequest(
          name: 'Adapter save',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
          players: [
            Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4),
          ],
        ),
      );
      final initial = await repository.load(saveId);
      expect(await repository.list(), hasLength(1));

      await snapshotStore.save(
        saveId,
        Snapshot(state: initial, createdAt: DateTime.utc(2026, 8, 1)),
      );
      expect((await snapshotStore.latest(saveId))?.state.metadata.id, saveId);

      await eventLog.append(
        saveId,
        RecordedDomainCommand(
          offset: 1,
          timestamp: DateTime.utc(2026, 8, 1),
          turn: 1,
          command: const SkipUnitTurnCommand('unit_1'),
        ),
      );
      expect(await eventLog.latestOffset(saveId), 1);
      expect(await eventLog.readAll(saveId).toList(), hasLength(1));

      await replayStore.saveInitialSnapshot(saveId, initial);
      expect((await replayStore.initialSnapshot(saveId))?.metadata.id, saveId);
      await replayStore.delete(saveId);
      expect(await replayStore.initialSnapshot(saveId), isNull);

      await repository.save(initial);
      await repository.delete(saveId);
      expect(await repository.list(), isEmpty);
    },
  );
}

class _FixedClock extends Clock {
  const _FixedClock();

  @override
  DateTime now() => DateTime.utc(2026, 8, 1);
}

class _SequenceIdGenerator implements IdGenerator {
  var _next = 0;

  @override
  String nextId() => 'save_${++_next}';
}
