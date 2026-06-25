import 'dart:io';

import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/infrastructure/persistence/json_snapshot_store.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonSnapshotStore', () {
    late Directory tempDir;
    late JsonSnapshotStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('json_snapshot_store_');
      store = JsonSnapshotStore(savesDir: tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('latest returns null when snapshot is missing', () async {
      expect(await store.latest('save_1'), isNull);
    });

    test('saves and replaces snapshot.json atomically', () async {
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

    test('keeps snapshot readable after overlapping saves', () async {
      await store.save(
        'save_1',
        Snapshot(
          offset: 1,
          createdAt: DateTime.utc(2026, 4, 24, 11),
          state: SaveSnapshot(save: _save(turn: 1), eventLogOffset: 1),
        ),
      );

      await Future.wait([
        for (var offset = 2; offset <= 80; offset++)
          store.save(
            'save_1',
            Snapshot(
              offset: offset,
              createdAt: DateTime.utc(2026, 4, 24, 11, offset),
              state: SaveSnapshot(
                save: _save(turn: offset),
                eventLogOffset: offset,
              ),
            ),
          ),
      ]);

      final snapshot = await store.latest('save_1');
      final leftovers = tempDir
          .listSync(recursive: true)
          .where((entity) => entity.path.endsWith('.tmp'));

      expect(snapshot, isNotNull);
      expect(snapshot!.offset, inInclusiveRange(2, 80));
      expect(snapshot.state.save.turn, snapshot.offset);
      expect(snapshot.state.eventLogOffset, snapshot.offset);
      expect(leftovers, isEmpty);
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
