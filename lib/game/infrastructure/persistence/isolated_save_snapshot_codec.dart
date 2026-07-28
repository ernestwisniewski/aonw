import 'dart:convert';
import 'dart:isolate';

import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';

/// Moves potentially large save/replay JSON work away from the UI isolate.
abstract final class IsolatedSaveSnapshotCodec {
  static const _isolateDecodeThreshold = 256 * 1024;

  static Future<SaveSnapshot> decode(String source) async {
    if (source.length < _isolateDecodeThreshold) {
      return _decode(source);
    }
    return Isolate.run(() {
      return _decode(source);
    });
  }

  static Future<String> encode(SaveSnapshot snapshot) {
    return Isolate.run(() => jsonEncode(SaveSnapshotCodec.toJson(snapshot)));
  }

  static Future<Snapshot> decodeEnvelope(String source) async {
    if (source.length < _isolateDecodeThreshold) {
      return _decodeEnvelope(source);
    }
    return Isolate.run(() {
      return _decodeEnvelope(source);
    });
  }

  static Future<String> encodeEnvelope(Snapshot snapshot) {
    return Isolate.run(
      () => jsonEncode({
        'offset': snapshot.offset,
        'createdAt': snapshot.createdAt.toUtc().toIso8601String(),
        'state': SaveSnapshotCodec.toJson(snapshot.state),
      }),
    );
  }
}

SaveSnapshot _decode(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  return SaveSnapshotCodec.fromJson(json);
}

Snapshot _decodeEnvelope(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  return Snapshot(
    offset: json['offset'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    state: SaveSnapshotCodec.fromJson(json['state'] as Map<String, dynamic>),
  );
}
