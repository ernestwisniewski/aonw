import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol/wire_json.dart';

enum WirePlayerKind { human, ai }

enum WirePlayerConnectionState { connected, connecting, reconnecting, offline }

class WirePlayer {
  final String id;
  final String userId;
  final String name;
  final int colorValue;
  final PlayerCountry country;
  final WirePlayerKind kind;
  final WirePlayerConnectionState connectionState;
  final bool ready;
  final WireAiPlayer? ai;

  const WirePlayer({
    required this.id,
    required this.userId,
    required this.name,
    required this.colorValue,
    this.country = PlayerCountry.poland,
    required this.kind,
    required this.connectionState,
    this.ready = false,
    this.ai,
  }) : assert(ai == null || kind == WirePlayerKind.ai);

  factory WirePlayer.fromJson(Map<String, dynamic> json) {
    final kind = WireJson.requiredEnum(
      json,
      'WirePlayer',
      'kind',
      WirePlayerKind.values,
    );
    final ai = _optionalAi(json['ai']);
    if (kind == WirePlayerKind.ai && ai == null) {
      throw ArgumentError.value(
        json['ai'],
        'WirePlayer.ai',
        'Expected AI metadata',
      );
    }
    if (kind != WirePlayerKind.ai && ai != null) {
      throw ArgumentError.value(
        json['ai'],
        'WirePlayer.ai',
        'Expected null for non-AI player',
      );
    }
    return WirePlayer(
      id: WireJson.requiredString(json, 'WirePlayer', 'id'),
      userId: WireJson.requiredString(json, 'WirePlayer', 'userId'),
      name: WireJson.requiredString(json, 'WirePlayer', 'name'),
      colorValue: WireJson.requiredInt(json, 'WirePlayer', 'colorValue'),
      country: _optionalCountry(json['countryId'] ?? json['country']),
      kind: kind,
      connectionState: WireJson.requiredEnum(
        json,
        'WirePlayer',
        'connectionState',
        WirePlayerConnectionState.values,
      ),
      ready: WireJson.optionalBool(json, 'WirePlayer', 'ready') ?? false,
      ai: ai,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'colorValue': colorValue,
    'countryId': country.name,
    'kind': kind.name,
    'connectionState': connectionState.name,
    'ready': ready,
    if (ai != null) 'ai': ai!.toJson(),
  };

  WirePlayer copyWith({
    String? id,
    String? userId,
    String? name,
    int? colorValue,
    PlayerCountry? country,
    WirePlayerKind? kind,
    WirePlayerConnectionState? connectionState,
    bool? ready,
    WireAiPlayer? ai,
  }) {
    return WirePlayer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      country: country ?? this.country,
      kind: kind ?? this.kind,
      connectionState: connectionState ?? this.connectionState,
      ready: ready ?? this.ready,
      ai: ai ?? this.ai,
    );
  }

  static WireAiPlayer? _optionalAi(Object? value) {
    if (value == null) return null;
    return WireAiPlayer.fromJson(WireJson.requiredMap(value, 'WirePlayer.ai'));
  }

  static PlayerCountry _optionalCountry(Object? value) {
    if (value == null) return PlayerCountry.poland;
    if (value is! String || value.isEmpty) {
      throw ArgumentError.value(
        value,
        'WirePlayer.countryId',
        'Expected a non-empty String',
      );
    }
    for (final country in PlayerCountry.values) {
      if (country.name == value) return country;
    }
    throw ArgumentError.value(value, 'WirePlayer.countryId', 'Unknown country');
  }
}

class WireAiPlayer {
  final AiStrategyId strategyId;
  final AiDifficulty difficulty;
  final AiPersona persona;

  const WireAiPlayer({
    required this.strategyId,
    this.difficulty = AiDifficulty.normal,
    this.persona = AiPersona.balanced,
  });

  factory WireAiPlayer.fromJson(Map<String, dynamic> json) {
    return WireAiPlayer(
      strategyId: WireJson.requiredEnum(
        json,
        'WireAiPlayer',
        'strategyId',
        AiStrategyId.values,
      ),
      difficulty: WireJson.requiredEnum(
        json,
        'WireAiPlayer',
        'difficulty',
        AiDifficulty.values,
      ),
      persona: WireJson.requiredEnum(
        json,
        'WireAiPlayer',
        'persona',
        AiPersona.values,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'strategyId': strategyId.name,
    'difficulty': difficulty.name,
    'persona': persona.name,
  };

  WireAiPlayer copyWith({
    AiStrategyId? strategyId,
    AiDifficulty? difficulty,
    AiPersona? persona,
  }) {
    return WireAiPlayer(
      strategyId: strategyId ?? this.strategyId,
      difficulty: difficulty ?? this.difficulty,
      persona: persona ?? this.persona,
    );
  }
}
