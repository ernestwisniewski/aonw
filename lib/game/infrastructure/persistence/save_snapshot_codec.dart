import 'package:aonw_core/game/domain/save.dart';
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
    if (!{gameSaveCurrentSchemaVersion, 4, 3}.contains(schemaVersion)) {
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
    final migratedSave = schemaVersion != gameSaveCurrentSchemaVersion
        ? {...rawSave, 'schemaVersion': gameSaveCurrentSchemaVersion}
        : rawSave;
    if (schemaVersion == 3) {
      state.putIfAbsent('transportNetwork', () => <dynamic>[]);
    }

    try {
      return CanonicalGameSnapshotCodec.decode(
        CanonicalGameSnapshotData(
          save: migratedSave,
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
