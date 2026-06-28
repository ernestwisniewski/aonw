import 'package:aonw_core/ai/ai_player.dart';
import 'package:aonw_core/util/wire_json.dart';

enum PlayerTurnState { active, finished }

enum PlayerKind { human, ai }

enum PlayerCountry {
  poland,
  ukraine,
  germany,
  france,
  unitedKingdom,
  italy,
  spain,
  netherlands,
  sweden,
  russia,
  unitedStates,
  canada,
  china,
  korea,
  japan,
  portugal,
}

/// Immutable player value object. Color is assigned automatically by index
/// from [palette], so players cannot choose their own color.
class Player {
  const Player({
    required this.id,
    required this.name,
    required this.colorValue,
    this.country = PlayerCountry.poland,
    this.kind = PlayerKind.human,
    this.ai,
  }) : assert(ai == null || kind == PlayerKind.ai);

  final String id;
  final String name;
  final int colorValue;
  final PlayerCountry country;
  final PlayerKind kind;
  final AiPlayer? ai;

  static const List<int> palette = [
    0xFF3D5FA8,
    0xFFB83A3A,
    0xFF6D4A8C,
    0xFFC8741F,
  ];

  static Player forIndex(
    int index, {
    PlayerCountry country = PlayerCountry.poland,
    PlayerKind kind = PlayerKind.human,
    AiPlayer? ai,
  }) => Player(
    id: 'player_${index + 1}',
    name: 'player_${index + 1}',
    colorValue: palette[index % palette.length],
    country: country,
    kind: kind,
    ai: ai,
  );

  bool get isAi => kind == PlayerKind.ai;

  factory Player.fromJson(Map<String, dynamic> json) {
    final aiJson = json['ai'];
    return Player(
      id: requiredStringValue(json['id'], 'Player.id'),
      name: requiredStringValue(json['name'], 'Player.name'),
      colorValue: requiredIntValue(json['colorValue'], 'Player.colorValue'),
      country:
          optionalEnumByName(
            json['country'] ?? json['countryId'],
            PlayerCountry.values,
            'Player.country',
          ) ??
          PlayerCountry.poland,
      kind: enumByName(
        json['kind'] ??
            (aiJson == null ? PlayerKind.human.name : PlayerKind.ai.name),
        PlayerKind.values,
        'Player.kind',
      ),
      ai: switch (aiJson) {
        null => null,
        final Map<String, dynamic> value => AiPlayer.fromJson(value),
        final Map<Object?, Object?> value => AiPlayer.fromJson(
          Map<String, dynamic>.from(value),
        ),
        final value => throw ArgumentError.value(
          value,
          'Player.ai',
          'Expected a JSON object or null',
        ),
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
    'country': country.name,
    'kind': kind.name,
    if (ai != null) 'ai': ai!.toJson(),
  };

  Player copyWith({
    String? id,
    String? name,
    int? colorValue,
    PlayerCountry? country,
    PlayerKind? kind,
    Object? ai = _unset,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      country: country ?? this.country,
      kind: kind ?? this.kind,
      ai: identical(ai, _unset) ? this.ai : ai as AiPlayer?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Player &&
        other.id == id &&
        other.name == name &&
        other.colorValue == colorValue &&
        other.country == country &&
        other.kind == kind &&
        other.ai == ai;
  }

  @override
  int get hashCode => Object.hash(id, name, colorValue, country, kind, ai);

  @override
  String toString() {
    return 'Player(id: $id, name: $name, colorValue: $colorValue, '
        'country: $country, kind: $kind, ai: $ai)';
  }

  static const Object _unset = Object();
}
