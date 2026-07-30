import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('current snapshot is stable through the compatibility adapter', () {
    final snapshot = SaveSnapshot(
      save: GameSave(
        id: 'current_snapshot',
        name: 'Current snapshot',
        mapName: 'verdantia',
        mapSource: MapSource.asset,
        turn: 2,
        playerStates: const {'player_1': PlayerTurnState.active},
        savedAt: DateTime.utc(2026, 5, 31, 13, 26, 23),
        camera: CameraState.zero,
        players: const [
          Player(id: 'player_1', name: 'player_1', colorValue: 0xFF4a7fc4),
        ],
      ),
      playerColors: const {'player_1': 0xFF4a7fc4},
      playerCountries: const {'player_1': PlayerCountry.poland},
      eventLogOffset: 2,
    );
    final expected = SaveSnapshotCodec.toJson(snapshot);
    final firstOutput = _roundTripThroughCompatibility(snapshot);
    final secondOutput = _roundTripThroughCompatibility(
      SaveSnapshotCodec.fromJson(firstOutput),
    );

    expect(
      (firstOutput['save'] as Map<String, dynamic>)['schemaVersion'],
      gameSaveCurrentSchemaVersion,
    );
    expect(firstOutput, expected);
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
