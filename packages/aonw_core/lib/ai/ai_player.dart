import 'package:aonw_core/ai/ai_difficulty.dart';
import 'package:aonw_core/ai/ai_persona.dart';
import 'package:aonw_core/ai/ai_strategy_id.dart';
import 'package:aonw_core/ai/civilization/civilization_profile.dart';
import 'package:aonw_core/util/wire_json.dart';

class AiPlayer {
  final AiStrategyId strategyId;
  final AiDifficulty difficulty;
  final AiPersona persona;
  final int seed;

  const AiPlayer({
    required this.strategyId,
    this.difficulty = AiDifficulty.normal,
    this.persona = AiPersona.balanced,
    required this.seed,
  });

  factory AiPlayer.random({required int seed}) {
    return AiPlayer(strategyId: AiStrategyId.random, seed: seed);
  }

  AiPersona personaForProfile(CivilizationProfile profile) {
    return persona == AiPersona.balanced ? profile.defaultPersona : persona;
  }

  factory AiPlayer.fromJson(Map<String, dynamic> json) {
    return AiPlayer(
      strategyId: enumByName(
        json['strategyId'],
        AiStrategyId.values,
        'AiPlayer.strategyId',
      ),
      difficulty: enumByName(
        json['difficulty'] ?? AiDifficulty.normal.name,
        AiDifficulty.values,
        'AiPlayer.difficulty',
      ),
      persona: enumByName(
        json['persona'] ?? AiPersona.balanced.name,
        AiPersona.values,
        'AiPlayer.persona',
      ),
      seed: requiredIntValue(json['seed'], 'AiPlayer.seed'),
    );
  }

  Map<String, dynamic> toJson() => {
    'strategyId': strategyId.name,
    'difficulty': difficulty.name,
    'persona': persona.name,
    'seed': seed,
  };

  AiPlayer copyWith({
    AiStrategyId? strategyId,
    AiDifficulty? difficulty,
    AiPersona? persona,
    int? seed,
  }) {
    return AiPlayer(
      strategyId: strategyId ?? this.strategyId,
      difficulty: difficulty ?? this.difficulty,
      persona: persona ?? this.persona,
      seed: seed ?? this.seed,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AiPlayer &&
        other.strategyId == strategyId &&
        other.difficulty == difficulty &&
        other.persona == persona &&
        other.seed == seed;
  }

  @override
  int get hashCode => Object.hash(strategyId, difficulty, persona, seed);

  @override
  String toString() {
    return 'AiPlayer(strategyId: $strategyId, difficulty: $difficulty, '
        'persona: $persona, seed: $seed)';
  }
}
