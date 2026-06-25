import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/id_generator.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_database.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_game_repository.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_snapshot_store.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  group('WebGameRepository', () {
    late WebDatabase db;
    late WebSnapshotStore snapshotStore;
    late WebGameRepository repository;

    setUp(() async {
      db = await WebDatabase.open(
        name: 'test.db',
        factory: newDatabaseFactoryMemory(),
      );
      snapshotStore = WebSnapshotStore(database: db);
      repository = WebGameRepository(
        database: db,
        snapshotStore: snapshotStore,
        clock: const _FixedClock(),
        idGenerator: _SequenceIdGenerator(),
      );
    });

    tearDown(() async => db.close());

    test('list returns empty when no saves exist', () async {
      expect(await repository.list(), isEmpty);
    });

    test('create stores a save listed by list()', () async {
      final id = await repository.create(
        const NewGameRequest(
          name: 'Test save',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
          players: [Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4)],
        ),
      );

      final saves = await repository.list();
      expect(saves, hasLength(1));
      expect(saves.single.id, id);
      expect(saves.single.name, 'Test save');
      expect(saves.single.mapName, 'verdantia');
    });

    test('save updates snapshot and reflects in list()', () async {
      final id = await repository.create(
        const NewGameRequest(
          name: 'Test save',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
          players: [Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4)],
        ),
      );

      final loaded = await repository.load(id);
      final updated = loaded.copyWith(
        save: loaded.save.copyWith(turn: 5, savedAt: DateTime.utc(2026, 6, 1)),
      );
      await repository.save(updated);

      final saves = await repository.list();
      expect(saves.single.turn, 5);
    });

    test(
      'marks saves with unreadable snapshots as corrupted in list()',
      () async {
        final id = await repository.create(
          const NewGameRequest(
            name: 'Old save',
            mapName: 'verdantia',
            mapSource: MapSource.asset,
            players: [Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4)],
          ),
        );
        final loaded = await repository.load(id);
        await snapshotStore.save(
          id,
          Snapshot(
            offset: 0,
            state: loaded.copyWith(
              save: loaded.save.copyWith(schemaVersion: 2),
            ),
            createdAt: DateTime.utc(2026, 4, 24),
          ),
        );

        final saves = await repository.list();

        expect(saves, hasLength(1));
        expect(saves.single.id, id);
        expect(saves.single.corrupted, isTrue);
        expect(
          saves.single.corruptionMessage,
          contains('Unsupported save schema'),
        );
      },
    );

    test('delete removes save from list and snapshot store', () async {
      final id = await repository.create(
        const NewGameRequest(
          name: 'Test save',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
          players: [Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4)],
        ),
      );
      expect(await repository.list(), hasLength(1));

      await repository.delete(id);

      expect(await repository.list(), isEmpty);
      expect(await snapshotStore.latest(id), isNull);
    });

    test('list sorts saves by savedAt descending', () async {
      final firstId = await repository.create(
        const NewGameRequest(
          name: 'Older',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
          players: [Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4)],
        ),
      );
      final firstLoaded = await repository.load(firstId);
      await repository.save(
        firstLoaded.copyWith(
          save: firstLoaded.save.copyWith(savedAt: DateTime.utc(2026, 1, 1)),
        ),
      );
      final secondId = await repository.create(
        const NewGameRequest(
          name: 'Newer',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
          players: [Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4)],
        ),
      );
      final secondLoaded = await repository.load(secondId);
      await repository.save(
        secondLoaded.copyWith(
          save: secondLoaded.save.copyWith(savedAt: DateTime.utc(2026, 6, 1)),
        ),
      );

      final saves = await repository.list();
      expect(saves.map((s) => s.name).toList(), ['Newer', 'Older']);
    });
  });
}

class _FixedClock extends Clock {
  const _FixedClock();

  @override
  DateTime now() => DateTime.utc(2026, 4, 24, 12);
}

class _SequenceIdGenerator implements IdGenerator {
  int _next = 1;

  @override
  String nextId() => 'save_${_next++}';
}
