import 'dart:convert';

import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';

/// Canonical JSON codec for the persisted current-snapshot envelope.
abstract final class SaveSnapshotEnvelopeCodec {
  static String encode(Snapshot snapshot) {
    return jsonEncode({
      'offset': snapshot.offset,
      'createdAt': snapshot.createdAt.toUtc().toIso8601String(),
      'state': SaveSnapshotCodec.toJson(snapshot.state),
    });
  }

  static Snapshot decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return Snapshot(
      offset: json['offset'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      state: SaveSnapshotCodec.fromJson(json['state'] as Map<String, dynamic>),
    );
  }
}
