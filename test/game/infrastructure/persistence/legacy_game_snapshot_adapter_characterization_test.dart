import 'dart:convert';
import 'dart:io';

import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schema-2 fixture is stable through the compatibility adapter', () {
    final fixture =
        jsonDecode(
              File('test/fixtures/save_snapshot_v2.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final rawState = fixture['state'] as Map<String, dynamic>;
    final rawSave = rawState['save'] as Map<String, dynamic>;

    final migrated = SaveSnapshotCodec.fromJson(rawState);
    final expectedSchema3 = SaveSnapshotCodec.toJson(migrated);
    final firstOutput = _roundTripThroughCompatibility(migrated);
    final secondOutput = _roundTripThroughCompatibility(
      SaveSnapshotCodec.fromJson(firstOutput),
    );

    expect(rawSave['schemaVersion'], 2);
    expect(
      (firstOutput['save'] as Map<String, dynamic>)['schemaVersion'],
      gameSaveCurrentSchemaVersion,
    );
    expect(firstOutput, expectedSchema3);
    expect(secondOutput, firstOutput);
  });
}

Map<String, dynamic> _roundTripThroughCompatibility(SaveSnapshot snapshot) {
  const adapter = LegacyGameSnapshotAdapter();
  final canonical = adapter.toCanonical(
    save: snapshot.save,
    state: snapshot.persistentState,
    eventLogOffset: snapshot.eventLogOffset,
  );
  final legacy = adapter.toLegacy(canonical);
  return SaveSnapshotCodec.toJson(
    SaveSnapshot.fromPersistentState(
      save: legacy.save,
      state: legacy.state,
      eventLogOffset: legacy.eventLogOffset,
    ),
  );
}
