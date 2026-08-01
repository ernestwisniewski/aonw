import 'dart:convert';

import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';

/// Canonical JSON codec for the persisted current-snapshot envelope.
abstract final class SaveSnapshotEnvelopeCodec {
  static String encode(Snapshot snapshot) {
    return jsonEncode({
      'createdAt': snapshot.createdAt.toUtc().toIso8601String(),
      'state': SaveSnapshotCodec.toJson(snapshot.state),
    });
  }

  static Snapshot decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final rawState = json['state'] as Map<String, dynamic>;
    var state = SaveSnapshotCodec.fromJson(rawState);
    final legacyOffset = json['offset'];
    if (legacyOffset is int) {
      if (rawState['eventLogOffset'] == null) {
        state = state.copyWith(eventLogOffset: legacyOffset);
      } else if (legacyOffset != state.eventLogOffset) {
        throw StateError(
          'Snapshot offset mismatch: envelope=$legacyOffset, '
          'canonical=${state.eventLogOffset}.',
        );
      }
    }
    return Snapshot(
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      state: state,
    );
  }
}
