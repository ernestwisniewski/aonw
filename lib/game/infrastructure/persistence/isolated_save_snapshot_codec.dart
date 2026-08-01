import 'dart:convert';
import 'dart:isolate';

import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_envelope_codec.dart';

/// Moves potentially large save/replay JSON work away from the UI isolate.
abstract final class IsolatedSaveSnapshotCodec {
  static const _isolateDecodeThreshold = 256 * 1024;

  static Future<CanonicalGameSnapshot> decode(String source) async {
    if (source.length < _isolateDecodeThreshold) {
      return _decode(source);
    }
    return Isolate.run(() {
      return _decode(source);
    });
  }

  static Future<String> encode(CanonicalGameSnapshot snapshot) {
    return Isolate.run(() => jsonEncode(SaveSnapshotCodec.toJson(snapshot)));
  }

  static Future<Snapshot> decodeEnvelope(String source) async {
    if (source.length < _isolateDecodeThreshold) {
      return SaveSnapshotEnvelopeCodec.decode(source);
    }
    return Isolate.run(() {
      return SaveSnapshotEnvelopeCodec.decode(source);
    });
  }

  static Future<String> encodeEnvelope(Snapshot snapshot) {
    return Isolate.run(() => SaveSnapshotEnvelopeCodec.encode(snapshot));
  }
}

CanonicalGameSnapshot _decode(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  return SaveSnapshotCodec.fromJson(json);
}
