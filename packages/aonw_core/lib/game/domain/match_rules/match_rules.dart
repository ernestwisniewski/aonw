import 'dart:collection';

import 'package:aonw_core/game/domain/match_rules/game_length_config.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/match_rules/victory_rules.dart';

final class MatchRules {
  final GameLengthConfig gameLength;
  final VictoryRules victory;
  final Map<String, dynamic> balance;

  factory MatchRules({
    required GameLengthConfig gameLength,
    required VictoryRules victory,
    Map<String, dynamic> balance = const {},
  }) {
    return MatchRules._owned(
      gameLength: gameLength,
      victory: victory,
      balance: _ownBalance(balance, fromJson: false),
    );
  }

  const MatchRules._owned({
    required this.gameLength,
    required this.victory,
    required this.balance,
  });

  static const standard = MatchRules._owned(
    gameLength: GameLengthConfig.unlimited,
    victory: VictoryRules.standard,
    balance: {},
  );

  static MatchRules forGameLength(GameLengthConfig gameLength) {
    return MatchRules(
      gameLength: gameLength,
      victory: VictoryRules.forGameLength(gameLength),
    );
  }

  PaceBalance get paceBalance => PaceBalance.forGameLength(gameLength);

  factory MatchRules.fromJson(Map<String, dynamic> json) {
    final rawBalance = json['balance'];
    return MatchRules._owned(
      gameLength: GameLengthConfig.fromJson(_readMap(json, 'gameLength')),
      victory: VictoryRules.fromJson(_readMap(json, 'victory')),
      balance: switch (rawBalance) {
        null => const {},
        final Map<Object?, Object?> value => _ownBalance(value, fromJson: true),
        _ => throw const FormatException('Expected object field "balance".'),
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameLength': gameLength.toJson(),
      'victory': victory.toJson(),
      'balance': _detachBalance(balance),
    };
  }

  MatchRules copyWith({
    GameLengthConfig? gameLength,
    VictoryRules? victory,
    Map<String, dynamic>? balance,
  }) {
    return MatchRules._owned(
      gameLength: gameLength ?? this.gameLength,
      victory: victory ?? this.victory,
      balance: balance == null
          ? this.balance
          : _ownBalance(balance, fromJson: false),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MatchRules &&
        other.gameLength == gameLength &&
        other.victory == victory &&
        _jsonMapEquals(other.balance, balance);
  }

  @override
  int get hashCode => Object.hash(gameLength, victory, _jsonValueHash(balance));

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

Map<String, dynamic> _ownBalance(
  Map<Object?, Object?> source, {
  required bool fromJson,
}) {
  return _ownJsonValue(
        source,
        path: r'$balance',
        ancestors: HashSet<Object>.identity(),
        fromJson: fromJson,
      )
      as Map<String, dynamic>;
}

Object? _ownJsonValue(
  Object? value, {
  required String path,
  required Set<Object> ancestors,
  required bool fromJson,
}) {
  if (value == null || value is bool || value is String) return value;
  if (value is num) {
    if (value.isFinite) return value;
    return _invalidBalanceValue(path, 'numbers must be finite', fromJson);
  }
  if (value is List<Object?>) {
    return _ownJsonList(
      value,
      path: path,
      ancestors: ancestors,
      fromJson: fromJson,
    );
  }
  if (value is Map<Object?, Object?>) {
    return _ownJsonMap(
      value,
      path: path,
      ancestors: ancestors,
      fromJson: fromJson,
    );
  }
  return _invalidBalanceValue(
    path,
    'expected null, bool, String, finite num, List, or Map',
    fromJson,
  );
}

List<dynamic> _ownJsonList(
  List<Object?> source, {
  required String path,
  required Set<Object> ancestors,
  required bool fromJson,
}) {
  if (!ancestors.add(source)) {
    return _invalidBalanceValue(path, 'cycles are not valid JSON', fromJson);
  }
  try {
    if (source.isEmpty) return const [];
    return List<dynamic>.unmodifiable([
      for (var index = 0; index < source.length; index++)
        _ownJsonValue(
          source[index],
          path: '$path[$index]',
          ancestors: ancestors,
          fromJson: fromJson,
        ),
    ]);
  } finally {
    ancestors.remove(source);
  }
}

Map<String, dynamic> _ownJsonMap(
  Map<Object?, Object?> source, {
  required String path,
  required Set<Object> ancestors,
  required bool fromJson,
}) {
  if (!ancestors.add(source)) {
    return _invalidBalanceValue(path, 'cycles are not valid JSON', fromJson);
  }
  try {
    if (source.isEmpty) return const {};
    final owned = <String, dynamic>{};
    for (final entry in source.entries) {
      final key = entry.key;
      if (key is! String) {
        return _invalidBalanceValue(
          path,
          'object keys must be strings',
          fromJson,
        );
      }
      owned[key] = _ownJsonValue(
        entry.value,
        path: '$path.$key',
        ancestors: ancestors,
        fromJson: fromJson,
      );
    }
    return Map<String, dynamic>.unmodifiable(owned);
  } finally {
    ancestors.remove(source);
  }
}

Never _invalidBalanceValue(String path, String reason, bool fromJson) {
  final message = 'Invalid JSON balance value at $path: $reason.';
  if (fromJson) throw FormatException(message);
  throw ArgumentError(message, 'balance');
}

Map<String, dynamic> _detachBalance(Map<String, dynamic> source) {
  return {
    for (final entry in source.entries)
      entry.key: _detachJsonValue(entry.value),
  };
}

Object? _detachJsonValue(Object? value) {
  if (value is List<Object?>) {
    return <dynamic>[for (final element in value) _detachJsonValue(element)];
  }
  if (value is Map<String, dynamic>) return _detachBalance(value);
  return value;
}

bool _jsonMapEquals(Map<String, dynamic> left, Map<String, dynamic> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) ||
        !_jsonValueEquals(entry.value, right[entry.key])) {
      return false;
    }
  }
  return true;
}

bool _jsonValueEquals(Object? left, Object? right) {
  if (identical(left, right)) return true;
  if (left is List<Object?> && right is List<Object?>) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!_jsonValueEquals(left[index], right[index])) return false;
    }
    return true;
  }
  if (left is Map<String, dynamic> && right is Map<String, dynamic>) {
    return _jsonMapEquals(left, right);
  }
  return left == right;
}

int _jsonValueHash(Object? value) {
  if (value is List<Object?>) {
    return Object.hash('list', Object.hashAll(value.map(_jsonValueHash)));
  }
  if (value is Map<String, dynamic>) {
    return Object.hash(
      'map',
      Object.hashAllUnordered([
        for (final entry in value.entries)
          Object.hash(entry.key, _jsonValueHash(entry.value)),
      ]),
    );
  }
  return value.hashCode;
}
