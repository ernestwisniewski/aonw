import 'package:aonw/game/application/ports/replay_store.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_database.dart';
import 'package:sembast/sembast.dart';

class WebReplayStore implements ReplayStore {
  static final StoreRef<String, Map<String, Object?>> _store =
      stringMapStoreFactory.store('replay_initial_snapshots');

  final WebDatabase database;

  const WebReplayStore({required this.database});

  @override
  Future<SaveSnapshot?> initialSnapshot(String saveId) async {
    final json = await _store.record(saveId).get(database.database);
    if (json == null) return null;
    return SaveSnapshotCodec.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  Future<void> saveInitialSnapshot(String saveId, SaveSnapshot snapshot) async {
    if (await _store.record(saveId).exists(database.database)) return;
    await _store
        .record(saveId)
        .put(database.database, SaveSnapshotCodec.toJson(snapshot));
  }

  @override
  Future<void> delete(String saveId) async {
    await _store.record(saveId).delete(database.database);
  }
}
