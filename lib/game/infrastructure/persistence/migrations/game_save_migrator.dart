import 'package:aonw/game/domain/game_save.dart';

abstract final class GameSaveMigrator {
  static const currentSchemaVersion = gameSaveCurrentSchemaVersion;
  static const _previousSchemaVersion = 2;
  static const _v3CulturalEnabledDefault = true;
  static const _v3CulturalRequiredArtifactsDefault = 6;
  static const _v3CulturalHoldTurnsDefault = 5;

  static Map<String, dynamic> migrate(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    return switch (schemaVersion) {
      currentSchemaVersion => Map<String, dynamic>.from(json),
      _previousSchemaVersion => _migrateV2ToV3(json),
      _ => throw _unsupportedSchemaVersion(schemaVersion),
    };
  }

  static Map<String, dynamic> _migrateV2ToV3(Map<String, dynamic> json) {
    final migrated = <String, dynamic>{
      ...json,
      'schemaVersion': currentSchemaVersion,
    };
    final rawRuleset = json['ruleset'];
    if (rawRuleset is! Map<Object?, Object?>) return migrated;
    final ruleset = Map<String, dynamic>.from(rawRuleset);
    final rawVictory = ruleset['victory'];
    if (rawVictory is! Map<Object?, Object?>) return migrated;

    // Early schema-2 saves predate cultural victory fields. Later schema-2
    // writers already emitted them, so preserve explicit values when present.
    final victory = Map<String, dynamic>.from(rawVictory)
      ..putIfAbsent('culturalEnabled', () => _v3CulturalEnabledDefault)
      ..putIfAbsent(
        'culturalRequiredArtifacts',
        () => _v3CulturalRequiredArtifactsDefault,
      )
      ..putIfAbsent('culturalHoldTurns', () => _v3CulturalHoldTurnsDefault);
    ruleset['victory'] = victory;
    migrated['ruleset'] = ruleset;
    return migrated;
  }

  static StateError _unsupportedSchemaVersion(Object? schemaVersion) {
    return StateError(
      'Unsupported save schema version: $schemaVersion '
      '(expected $_previousSchemaVersion or $currentSchemaVersion)',
    );
  }
}
