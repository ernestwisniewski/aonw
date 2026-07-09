import 'package:aonw_core/game/domain/match_rules/game_length_config.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'victory_rules.freezed.dart';

@freezed
abstract class VictoryRules with _$VictoryRules {
  const VictoryRules._();

  const factory VictoryRules({
    required bool conquestEnabled,
    required bool dominationEnabled,
    required double dominationControlPercent,
    required int dominationHoldTurns,
    required bool scoreFallbackEnabled,
    int? turnLimit,
    int? hardTimeLimitMinutes,
    @Default(true) bool culturalEnabled,
    @Default(6) int culturalRequiredArtifacts,
    @Default(5) int culturalHoldTurns,
  }) = _VictoryRules;

  static const standard = VictoryRules(
    conquestEnabled: true,
    dominationEnabled: true,
    dominationControlPercent: 60,
    dominationHoldTurns: 5,
    scoreFallbackEnabled: false,
    culturalEnabled: true,
    culturalRequiredArtifacts: 6,
    culturalHoldTurns: 5,
  );

  static VictoryRules forGameLength(GameLengthConfig gameLength) {
    return VictoryRules(
      conquestEnabled: true,
      dominationEnabled: true,
      dominationControlPercent: _dominationControlPercent(
        gameLength.paceProfile,
      ),
      dominationHoldTurns: _dominationHoldTurns(gameLength.paceProfile),
      scoreFallbackEnabled: gameLength.scoreFallbackEnabled,
      turnLimit: gameLength.turnLimit,
      culturalEnabled: true,
      culturalRequiredArtifacts: 6,
      culturalHoldTurns: 5,
    );
  }

  factory VictoryRules.fromJson(Map<String, dynamic> json) {
    return VictoryRules(
      conquestEnabled: _readBool(json, 'conquestEnabled'),
      dominationEnabled: _readBool(json, 'dominationEnabled'),
      dominationControlPercent: _readPercent(json, 'dominationControlPercent'),
      dominationHoldTurns: _readPositiveInt(json, 'dominationHoldTurns'),
      scoreFallbackEnabled: _readBool(json, 'scoreFallbackEnabled'),
      turnLimit: _readOptionalPositiveInt(json, 'turnLimit'),
      hardTimeLimitMinutes: _readOptionalPositiveInt(
        json,
        'hardTimeLimitMinutes',
      ),
      culturalEnabled: _readBool(json, 'culturalEnabled'),
      culturalRequiredArtifacts: _readPositiveInt(
        json,
        'culturalRequiredArtifacts',
      ),
      culturalHoldTurns: _readPositiveInt(json, 'culturalHoldTurns'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conquestEnabled': conquestEnabled,
      'dominationEnabled': dominationEnabled,
      'dominationControlPercent': dominationControlPercent,
      'dominationHoldTurns': dominationHoldTurns,
      'scoreFallbackEnabled': scoreFallbackEnabled,
      if (turnLimit != null) 'turnLimit': turnLimit,
      if (hardTimeLimitMinutes != null)
        'hardTimeLimitMinutes': hardTimeLimitMinutes,
      'culturalEnabled': culturalEnabled,
      'culturalRequiredArtifacts': culturalRequiredArtifacts,
      'culturalHoldTurns': culturalHoldTurns,
    };
  }
}

double _dominationControlPercent(PaceProfile paceProfile) {
  return switch (paceProfile) {
    PaceProfile.standard60 => 45,
    PaceProfile.normal90 => 47,
    PaceProfile.long120 => 50,
    PaceProfile.unlimited => 60,
  };
}

int _dominationHoldTurns(PaceProfile paceProfile) {
  return switch (paceProfile) {
    PaceProfile.standard60 => 10,
    PaceProfile.normal90 => 12,
    PaceProfile.unlimited => 5,
    PaceProfile.long120 => 14,
  };
}

bool _readBool(Map<String, dynamic> json, String key) {
  final raw = json[key];
  if (raw is bool) return raw;
  throw FormatException('Missing required boolean field "$key".');
}

double _readPercent(Map<String, dynamic> json, String key) {
  final raw = json[key];
  if (raw is! num || raw <= 0 || raw > 100) {
    throw FormatException('Expected percent field "$key" in range 0-100.');
  }
  return raw.toDouble();
}

int _readPositiveInt(Map<String, dynamic> json, String key) {
  final raw = json[key];
  if (raw is! num || raw <= 0) {
    throw FormatException('Expected positive integer field "$key".');
  }
  final value = raw.toInt();
  if (value != raw) {
    throw FormatException('Expected integer field "$key".');
  }
  return value;
}

int? _readOptionalPositiveInt(Map<String, dynamic> json, String key) {
  final raw = json[key];
  if (raw == null) return null;
  if (raw is! num || raw <= 0) {
    throw FormatException('Expected positive integer field "$key".');
  }
  final value = raw.toInt();
  if (value != raw) {
    throw FormatException('Expected integer field "$key".');
  }
  return value;
}
