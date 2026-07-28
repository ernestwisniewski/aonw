import 'dart:io';

import 'package:aonw/game/application/ports/replay_store.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/infrastructure/persistence/game_storage.dart';
import 'package:aonw/game/infrastructure/persistence/isolated_save_snapshot_codec.dart';

class JsonReplayStore implements ReplayStore {
  final Directory? savesDir;

  const JsonReplayStore({this.savesDir});

  @override
  Future<SaveSnapshot?> initialSnapshot(String saveId) async {
    final file = await _file(saveId);
    if (!await file.exists()) return null;

    return IsolatedSaveSnapshotCodec.decode(await file.readAsString());
  }

  @override
  Future<void> saveInitialSnapshot(String saveId, SaveSnapshot snapshot) async {
    final file = await _file(saveId);
    await file.parent.create(recursive: true);
    if (await file.exists()) return;
    final encoded = await IsolatedSaveSnapshotCodec.encode(snapshot);
    await file.writeAsString(encoded, flush: true);
  }

  @override
  Future<void> delete(String saveId) async {
    final file = await _file(saveId);
    if (await file.exists()) await file.delete();
  }

  Future<File> _file(String saveId) async {
    final dir = await GameStorage.saveDirectory(saveId, savesDir: savesDir);
    return File('${dir.path}/replay_initial_snapshot.json');
  }
}
