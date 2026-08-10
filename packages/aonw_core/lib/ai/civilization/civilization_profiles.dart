import 'package:aonw_core/ai/ai_persona.dart';
import 'package:aonw_core/ai/civilization/civilization_profile.dart';
import 'package:aonw_core/ai/civilization/persona_weights.dart';
import 'package:aonw_core/ai/civilization/tech_branch_preferences.dart';
import 'package:aonw_core/game/domain/player.dart';

part 'civilization_profile_catalog.dart';

abstract final class CivilizationProfiles {
  static const poland = CivilizationProfile(
    country: PlayerCountry.poland,
    displayName: 'Poland',
    defaultPersona: AiPersona.balanced,
    civBias: PersonaWeights(
      aggression: 1.00,
      expansion: 1.00,
      economy: 1.00,
      science: 1.00,
    ),
    belligerence: 1.00,
    expansionDistance: 1.00,
    frontierTolerance: 1.00,
    techBias: TechBranchPreferences.identity,
  );

  static const all = _civilizationProfiles;
}
