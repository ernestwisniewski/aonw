import 'package:aonw_core/ai/ai_persona.dart';
import 'package:aonw_core/ai/civilization/persona_weights.dart';
import 'package:aonw_core/ai/civilization/tech_branch_preferences.dart';
import 'package:aonw_core/game/domain/player.dart';

class CivilizationProfile {
  final PlayerCountry country;
  final String displayName;
  final AiPersona defaultPersona;
  final PersonaWeights civBias;
  final double belligerence;
  final double expansionDistance;
  final double frontierTolerance;
  final TechBranchPreferences techBias;

  const CivilizationProfile({
    required this.country,
    required this.displayName,
    required this.defaultPersona,
    required this.civBias,
    required this.belligerence,
    required this.expansionDistance,
    required this.frontierTolerance,
    required this.techBias,
  });

  PersonaWeights effectiveWeights(AiPersona persona) {
    return persona.weights.multiply(civBias);
  }

  @override
  bool operator ==(Object other) {
    return other is CivilizationProfile &&
        other.country == country &&
        other.displayName == displayName &&
        other.defaultPersona == defaultPersona &&
        other.civBias == civBias &&
        other.belligerence == belligerence &&
        other.expansionDistance == expansionDistance &&
        other.frontierTolerance == frontierTolerance &&
        other.techBias == techBias;
  }

  @override
  int get hashCode {
    return Object.hash(
      country,
      displayName,
      defaultPersona,
      civBias,
      belligerence,
      expansionDistance,
      frontierTolerance,
      techBias,
    );
  }
}
