import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_database.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_snapshot_store.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  group('WebSnapshotStore', () {
    late WebDatabase db;
    late WebSnapshotStore store;

    setUp(() async {
      db = await WebDatabase.open(
        name: 'test.db',
        factory: newDatabaseFactoryMemory(),
      );
      store = WebSnapshotStore(database: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('latest returns null when snapshot is missing', () async {
      expect(await store.latest('save_1'), isNull);
    });

    test('saves and replaces snapshot for same saveId', () async {
      await store.save(
        'save_1',
        Snapshot(
          offset: 3,
          createdAt: DateTime.utc(2026, 4, 24, 12),
          state: SaveSnapshot(save: _save(turn: 1), eventLogOffset: 3),
        ),
      );
      await store.save(
        'save_1',
        Snapshot(
          offset: 4,
          createdAt: DateTime.utc(2026, 4, 24, 13),
          state: SaveSnapshot(save: _save(turn: 2), eventLogOffset: 4),
        ),
      );

      final snapshot = await store.latest('save_1');

      expect(snapshot, isNotNull);
      expect(snapshot!.offset, 4);
      expect(snapshot.createdAt, DateTime.utc(2026, 4, 24, 13));
      expect(snapshot.state.save.turn, 2);
      expect(snapshot.state.eventLogOffset, 4);
    });

    test('keeps each saveId independent', () async {
      await store.save(
        'save_a',
        Snapshot(
          offset: 1,
          createdAt: DateTime.utc(2026, 1, 1),
          state: SaveSnapshot(save: _save(turn: 1), eventLogOffset: 1),
        ),
      );
      await store.save(
        'save_b',
        Snapshot(
          offset: 7,
          createdAt: DateTime.utc(2026, 1, 2),
          state: SaveSnapshot(save: _save(turn: 9), eventLogOffset: 7),
        ),
      );

      expect((await store.latest('save_a'))!.state.save.turn, 1);
      expect((await store.latest('save_b'))!.state.save.turn, 9);
    });

    test('delete removes only the requested snapshot', () async {
      await store.save(
        'save_a',
        Snapshot(
          offset: 1,
          createdAt: DateTime.utc(2026, 1, 1),
          state: SaveSnapshot(save: _save(turn: 1), eventLogOffset: 1),
        ),
      );
      await store.save(
        'save_b',
        Snapshot(
          offset: 2,
          createdAt: DateTime.utc(2026, 1, 2),
          state: SaveSnapshot(save: _save(turn: 2), eventLogOffset: 2),
        ),
      );

      await store.delete('save_a');

      expect(await store.latest('save_a'), isNull);
      expect((await store.latest('save_b'))!.state.save.turn, 2);
    });
  });
}

GameSave _save({required int turn}) {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: turn,
    playerStates: const {'p1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: const [Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4)],
  );
}
