import 'package:aonw_core/ai/ai_difficulty.dart';
import 'package:aonw_core/ai/ai_persona.dart';
import 'package:aonw_core/ai/ai_rng.dart';
import 'package:aonw_core/ai/civilization/civilization_profile.dart';
import 'package:aonw_core/ai/civilization/civilization_profiles.dart';
import 'package:aonw_core/ai/civilization/persona_weights.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_context.freezed.dart';

@freezed
abstract class AiContext with _$AiContext {
  const AiContext._();

  const factory AiContext({
    required GameRuleset ruleset,
    required MapReadView mapData,
    required int turn,
    required AiRng rng,
    @Default(AiPersona.balanced) AiPersona persona,
    @Default(AiDifficulty.normal) AiDifficulty difficulty,
    @Default(CivilizationProfiles.poland) CivilizationProfile civProfile,
    StrategicPlan? strategicPlan,
    ScoreRaceAnalysis? scoreRace,
    DateTime? deadline,
    @Default(0.0) double ownControlPercent,
    @Default(1) int knownPlayerCount,
  }) = _AiContext;

  AiDifficultyProfile get difficultyProfile => difficulty.profile;

  PersonaWeights get effectiveWeights {
    return civProfile
        .effectiveWeights(persona)
        .multiply(difficultyProfile.weightMultiplier);
  }
}
