enum GameLengthKind { unlimited, targetMinutes }

enum PaceProfile { unlimited, standard60, normal90, long120 }

class GameLengthConfig {
  final GameLengthKind kind;
  final int? targetMinutes;
  final int? turnLimit;
  final PaceProfile paceProfile;
  final bool scoreFallbackEnabled;

  const GameLengthConfig({
    required this.kind,
    this.targetMinutes,
    this.turnLimit,
    required this.paceProfile,
    required this.scoreFallbackEnabled,
  });

  static const estimatedMultiplayerTurnSeconds = 30;
  static const standard60TurnLimit = 120;
  static const normal90TurnLimit = 180;
  static const long120TurnLimit = 240;

  static const unlimited = GameLengthConfig(
    kind: GameLengthKind.unlimited,
    paceProfile: PaceProfile.unlimited,
    scoreFallbackEnabled: false,
  );

  static const standard60 = GameLengthConfig(
    kind: GameLengthKind.targetMinutes,
    targetMinutes: 60,
    turnLimit: standard60TurnLimit,
    paceProfile: PaceProfile.standard60,
    scoreFallbackEnabled: true,
  );

  static const normal90 = GameLengthConfig(
    kind: GameLengthKind.targetMinutes,
    targetMinutes: 90,
    turnLimit: normal90TurnLimit,
    paceProfile: PaceProfile.normal90,
    scoreFallbackEnabled: true,
  );

  static const long120 = GameLengthConfig(
    kind: GameLengthKind.targetMinutes,
    targetMinutes: 120,
    turnLimit: long120TurnLimit,
    paceProfile: PaceProfile.long120,
    scoreFallbackEnabled: true,
  );

  static int turnLimitForTargetMinutes(
    int minutes, {
    int estimatedTurnSeconds = estimatedMultiplayerTurnSeconds,
  }) {
    if (minutes <= 0) {
      throw ArgumentError.value(minutes, 'minutes', 'Must be positive.');
    }
    if (estimatedTurnSeconds <= 0) {
      throw ArgumentError.value(
        estimatedTurnSeconds,
        'estimatedTurnSeconds',
        'Must be positive.',
      );
    }
    return ((minutes * 60) / estimatedTurnSeconds).ceil();
  }

  static GameLengthConfig targetDuration(int minutes) {
    if (minutes <= 0) {
      throw ArgumentError.value(minutes, 'minutes', 'Must be positive.');
    }
    return switch (minutes) {
      60 => standard60,
      90 => normal90,
      120 => long120,
      _ => throw ArgumentError.value(
        minutes,
        'minutes',
        'Supported durations are 60, 90 and 120 minutes.',
      ),
    };
  }

  factory GameLengthConfig.fromJson(Map<String, dynamic> json) {
    return GameLengthConfig(
      kind: _readEnum(
        json,
        'kind',
        GameLengthKind.values,
        (value) => value.name,
      ),
      targetMinutes: _readOptionalPositiveInt(json, 'targetMinutes'),
      turnLimit: _readOptionalPositiveInt(json, 'turnLimit'),
      paceProfile: _readEnum(
        json,
        'paceProfile',
        PaceProfile.values,
        (value) => value.name,
      ),
      scoreFallbackEnabled: _readBool(json, 'scoreFallbackEnabled'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kind': kind.name,
      if (targetMinutes != null) 'targetMinutes': targetMinutes,
      if (turnLimit != null) 'turnLimit': turnLimit,
      'paceProfile': paceProfile.name,
      'scoreFallbackEnabled': scoreFallbackEnabled,
    };
  }

  GameLengthConfig copyWith({
    GameLengthKind? kind,
    int? targetMinutes,
    int? turnLimit,
    PaceProfile? paceProfile,
    bool? scoreFallbackEnabled,
  }) {
    return GameLengthConfig(
      kind: kind ?? this.kind,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      turnLimit: turnLimit ?? this.turnLimit,
      paceProfile: paceProfile ?? this.paceProfile,
      scoreFallbackEnabled: scoreFallbackEnabled ?? this.scoreFallbackEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GameLengthConfig &&
        other.kind == kind &&
        other.targetMinutes == targetMinutes &&
        other.turnLimit == turnLimit &&
        other.paceProfile == paceProfile &&
        other.scoreFallbackEnabled == scoreFallbackEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      kind,
      targetMinutes,
      turnLimit,
      paceProfile,
      scoreFallbackEnabled,
    );
  }

  @override
  String toString() {
    return 'GameLengthConfig(kind: $kind, targetMinutes: $targetMinutes, '
        'turnLimit: $turnLimit, paceProfile: $paceProfile, '
        'scoreFallbackEnabled: $scoreFallbackEnabled)';
  }
}

T _readEnum<T extends Enum>(
  Map<String, dynamic> json,
  String key,
  List<T> values,
  String Function(T value) label,
) {
  final raw = json[key];
  if (raw is! String) {
    throw FormatException('Missing required enum field "$key".');
  }
  for (final value in values) {
    if (label(value) == raw) return value;
  }
  throw FormatException('Unsupported value "$raw" for "$key".');
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

bool _readBool(Map<String, dynamic> json, String key) {
  final raw = json[key];
  if (raw is bool) return raw;
  throw FormatException('Missing required boolean field "$key".');
}
