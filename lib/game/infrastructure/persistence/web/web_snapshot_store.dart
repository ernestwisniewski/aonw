import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_database.dart';
import 'package:sembast/sembast.dart';

class WebSnapshotStore implements SnapshotStore {
  static final StoreRef<String, Map<String, Object?>> _store =
      stringMapStoreFactory.store('snapshots');

  final WebDatabase database;

  const WebSnapshotStore({required this.database});

  @override
  Future<Snapshot?> latest(String saveId) async {
    final record = await _store.record(saveId).get(database.database);
    if (record == null) return null;
    final rawState = Map<String, dynamic>.from(record['state'] as Map);
    var state = SaveSnapshotCodec.fromJson(rawState);
    final legacyOffset = record['offset'];
    if (legacyOffset is int && rawState['eventLogOffset'] == null) {
      state = state.copyWith(eventLogOffset: legacyOffset);
    } else if (legacyOffset is int && legacyOffset != state.eventLogOffset) {
      throw StateError(
        'Snapshot offset mismatch: record=$legacyOffset, '
        'canonical=${state.eventLogOffset}.',
      );
    }
    return Snapshot(
      createdAt: DateTime.parse(record['createdAt'] as String).toUtc(),
      state: state,
    );
  }

  @override
  Future<void> save(String saveId, Snapshot snapshot) async {
    await _store.record(saveId).put(database.database, {
      'createdAt': snapshot.createdAt.toUtc().toIso8601String(),
      'state': SaveSnapshotCodec.toJson(snapshot.state),
    });
  }

  Future<void> delete(String saveId) async {
    await _store.record(saveId).delete(database.database);
  }
}
