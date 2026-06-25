import 'dart:convert';
import 'dart:io';

import 'package:aonw/game/application/ports/replay_store.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/infrastructure/persistence/game_storage.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';

class JsonReplayStore implements ReplayStore {
  final Directory? savesDir;

  const JsonReplayStore({this.savesDir});

  @override
  Future<SaveSnapshot?> initialSnapshot(String saveId) async {
    final file = await _file(saveId);
    if (!await file.exists()) return null;

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return SaveSnapshotCodec.fromJson(json);
  }

  @override
  Future<void> saveInitialSnapshot(String saveId, SaveSnapshot snapshot) async {
    final file = await _file(saveId);
    await file.parent.create(recursive: true);
    if (await file.exists()) return;
    await file.writeAsString(
      jsonEncode(SaveSnapshotCodec.toJson(snapshot)),
      flush: true,
    );
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
