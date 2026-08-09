import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('current schema round-trips explicit save origin', () {
    final snapshot = GameSnapshotFactory.create(
      save: _save(origin: GameSaveOrigin.network),
    );

    final encoded = SaveSnapshotCodec.toJson(snapshot);
    final restored = SaveSnapshotCodec.fromJson(encoded);

    expect(
      (encoded['save'] as Map<String, dynamic>)['origin'],
      GameSaveOrigin.network.name,
    );
    expect(restored.save.origin, GameSaveOrigin.network);
    expect(restored.save.schemaVersion, gameSaveCurrentSchemaVersion);
  });

  test('same-schema legacy snapshot without origin decodes as legacy', () {
    final encoded = SaveSnapshotCodec.toJson(
      GameSnapshotFactory.create(save: _save()),
    );
    final legacySave = Map<String, dynamic>.from(
      encoded['save'] as Map<String, dynamic>,
    )..remove('origin');

    final restored = SaveSnapshotCodec.fromJson({
      ...encoded,
      'save': legacySave,
    });

    expect(restored.save.origin, GameSaveOrigin.legacy);
    expect(restored.save.schemaVersion, gameSaveCurrentSchemaVersion);
  });
}

GameSave _save({GameSaveOrigin origin = GameSaveOrigin.local}) {
  return GameSave(
    id: 'save_1',
    name: 'Campaign',
    mapName: 'verdantia',
    turn: 1,
    playerStates: const {},
    savedAt: DateTime.utc(2026, 8, 9),
    camera: CameraState.zero,
    origin: origin,
  );
}
