import 'package:aonw/game/domain/game_save.dart';

abstract final class GameSaveMigrator {
  static const currentSchemaVersion = gameSaveCurrentSchemaVersion;

  static Map<String, dynamic> migrate(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != currentSchemaVersion) {
      throw StateError(
        'Unsupported save schema version: $schemaVersion '
        '(expected $currentSchemaVersion)',
      );
    }
    return Map<String, dynamic>.from(json);
  }
}
