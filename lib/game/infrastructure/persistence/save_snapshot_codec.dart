import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw_core/game/domain/state.dart';

abstract final class SaveSnapshotCodec {
  static Map<String, dynamic> toJson(CanonicalGameSnapshot snapshot) {
    final data = CanonicalGameSnapshotCodec.encode(snapshot);
    return {
      'save': data.save,
      ...data.state,
      'eventLogOffset': data.eventLogOffset,
    };
  }

  static CanonicalGameSnapshot fromJson(Map<String, dynamic> json) {
    final rawSave = json['save'] as Map<String, dynamic>;
    final schemaVersion = rawSave['schemaVersion'];
    if (schemaVersion != gameSaveCurrentSchemaVersion) {
      throw StateError(
        'Unsupported save schema version: $schemaVersion '
        '(expected $gameSaveCurrentSchemaVersion)',
      );
    }
    final state = <String, dynamic>{
      for (final entry in json.entries)
        if (entry.key != 'save' && entry.key != 'eventLogOffset')
          entry.key: entry.value,
    };

    try {
      return CanonicalGameSnapshotCodec.decode(
        CanonicalGameSnapshotData(
          save: rawSave,
          state: state,
          eventLogOffset: json['eventLogOffset'] as int? ?? 0,
        ),
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Invalid current save snapshot: $error');
    }
  }
}
