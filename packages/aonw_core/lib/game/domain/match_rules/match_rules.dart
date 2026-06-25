import 'package:aonw_core/game/domain/match_rules/game_length_config.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/match_rules/victory_rules.dart';
import 'package:aonw_core/util/collection_equality.dart';

class MatchRules {
  final GameLengthConfig gameLength;
  final VictoryRules victory;
  final Map<String, dynamic> balance;

  const MatchRules({
    required this.gameLength,
    required this.victory,
    this.balance = const {},
  });

  static const standard = MatchRules(
    gameLength: GameLengthConfig.unlimited,
    victory: VictoryRules.standard,
  );

  static MatchRules forGameLength(GameLengthConfig gameLength) {
    return MatchRules(
      gameLength: gameLength,
      victory: VictoryRules.forGameLength(gameLength),
    );
  }

  PaceBalance get paceBalance => PaceBalance.forGameLength(gameLength);

  factory MatchRules.fromJson(Map<String, dynamic> json) {
    return MatchRules(
      gameLength: GameLengthConfig.fromJson(_readMap(json, 'gameLength')),
      victory: VictoryRules.fromJson(_readMap(json, 'victory')),
      balance: _readOptionalMap(json, 'balance'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameLength': gameLength.toJson(),
      'victory': victory.toJson(),
      'balance': balance,
    };
  }

  MatchRules copyWith({
    GameLengthConfig? gameLength,
    VictoryRules? victory,
    Map<String, dynamic>? balance,
  }) {
    return MatchRules(
      gameLength: gameLength ?? this.gameLength,
      victory: victory ?? this.victory,
      balance: balance ?? this.balance,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MatchRules &&
        other.gameLength == gameLength &&
        other.victory == victory &&
        mapEquals(other.balance, balance);
  }

  @override
  int get hashCode => Object.hash(gameLength, victory, mapHash(balance));

  @override
  String toString() {
    return 'MatchRules(gameLength: $gameLength, victory: $victory, '
        'balance: $balance)';
  }
}

Map<String, dynamic> _readMap(Map<String, dynamic> json, String key) {
  final raw = json[key];
  if (raw is Map<Object?, Object?>) {
    return Map<String, dynamic>.from(raw);
  }
  throw FormatException('Missing required object field "$key".');
}

Map<String, dynamic> _readOptionalMap(Map<String, dynamic> json, String key) {
  final raw = json[key];
  if (raw == null) return const {};
  if (raw is Map<Object?, Object?>) {
    return Map<String, dynamic>.from(raw);
  }
  throw FormatException('Expected object field "$key".');
}
