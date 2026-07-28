import 'dart:io';

import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/infrastructure/persistence/game_storage.dart';
import 'package:aonw/game/infrastructure/persistence/isolated_save_snapshot_codec.dart';
import 'package:aonw/game/infrastructure/system/system_clock.dart';

class JsonSnapshotStore implements SnapshotStore {
  // Hot-seat AI can dispatch overlapping local commands for the same save.
  static final Map<String, Future<void>> _saveChains = {};
  static int _tmpCounter = 0;

  final Directory? savesDir;
  final Clock clock;

  const JsonSnapshotStore({this.savesDir, this.clock = const SystemClock()});

  @override
  Future<Snapshot?> latest(String saveId) async {
    final file = await _file(saveId);
    if (!await file.exists()) return null;

    return IsolatedSaveSnapshotCodec.decodeEnvelope(await file.readAsString());
  }

  @override
  Future<void> save(String saveId, Snapshot snapshot) async {
    final file = await _file(saveId);
    final previous = _saveChains[file.path] ?? Future<void>.value();
    late final Future<void> current;
    current = previous
        .then<void>((_) {}, onError: (Object _, StackTrace _) {})
        .then((_) => _write(file, snapshot));
    _saveChains[file.path] = current;

    try {
      await current;
    } finally {
      if (identical(_saveChains[file.path], current)) {
        final _ = _saveChains.remove(file.path);
      }
    }
  }

  Future<void> _write(File file, Snapshot snapshot) async {
    await file.parent.create(recursive: true);

    final tmp = File(_tmpPath(file, clock.nowUtc()));
    try {
      final encoded = await IsolatedSaveSnapshotCodec.encodeEnvelope(snapshot);
      await tmp.writeAsString(encoded, flush: true);
      await _replace(tmp, file);
    } catch (_) {
      if (await tmp.exists()) await tmp.delete();
      rethrow;
    }
  }

  Future<void> _replace(File tmp, File target) async {
    try {
      await tmp.rename(target.path);
    } on FileSystemException {
      if (await target.exists()) await target.delete();
      await tmp.rename(target.path);
    }
  }

  static String _tmpPath(File file, DateTime now) {
    _tmpCounter = (_tmpCounter + 1) & 0x3fffffff;
    return '${file.path}.${now.microsecondsSinceEpoch}.$_tmpCounter.tmp';
  }

  Future<File> _file(String saveId) async {
    final dir = await GameStorage.saveDirectory(saveId, savesDir: savesDir);
    return File('${dir.path}/snapshot.json');
  }
}
