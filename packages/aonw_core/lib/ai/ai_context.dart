import 'package:aonw_core/ai/ai_difficulty.dart';
import 'package:aonw_core/ai/ai_persona.dart';
import 'package:aonw_core/ai/ai_rng.dart';
import 'package:aonw_core/ai/civilization/civilization_profile.dart';
import 'package:aonw_core/ai/civilization/civilization_profiles.dart';
import 'package:aonw_core/ai/civilization/persona_weights.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class AiContext {
  final GameRuleset ruleset;
  final MapData mapData;
  final int turn;
  final AiRng rng;
  final AiPersona persona;
  final AiDifficulty difficulty;
  final CivilizationProfile civProfile;
  final StrategicPlan? strategicPlan;
  final ScoreRaceAnalysis? scoreRace;
  final DateTime? deadline;

  const AiContext({
    required this.ruleset,
    required this.mapData,
    required this.turn,
    required this.rng,
    this.persona = AiPersona.balanced,
    this.difficulty = AiDifficulty.normal,
    this.civProfile = CivilizationProfiles.poland,
    this.strategicPlan,
    this.scoreRace,
    this.deadline,
  });

  AiDifficultyProfile get difficultyProfile => difficulty.profile;

  PersonaWeights get effectiveWeights {
    return civProfile
        .effectiveWeights(persona)
        .multiply(difficultyProfile.weightMultiplier);
  }

  AiContext copyWith({
    GameRuleset? ruleset,
    MapData? mapData,
    int? turn,
    AiRng? rng,
    AiPersona? persona,
    AiDifficulty? difficulty,
    CivilizationProfile? civProfile,
    StrategicPlan? strategicPlan,
    ScoreRaceAnalysis? scoreRace,
    DateTime? deadline,
  }) {
    return AiContext(
      ruleset: ruleset ?? this.ruleset,
      mapData: mapData ?? this.mapData,
      turn: turn ?? this.turn,
      rng: rng ?? this.rng,
      persona: persona ?? this.persona,
      difficulty: difficulty ?? this.difficulty,
      civProfile: civProfile ?? this.civProfile,
      strategicPlan: strategicPlan ?? this.strategicPlan,
      scoreRace: scoreRace ?? this.scoreRace,
      deadline: deadline ?? this.deadline,
    );
  }
}
