import 'package:aonw_core/ai/ai_persona.dart';
import 'package:aonw_core/ai/civilization/persona_weights.dart';
import 'package:aonw_core/ai/civilization/tech_branch_preferences.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/util/collection_equality.dart';

class UniqueUnitOverride {
  const UniqueUnitOverride();
}

class UniqueBuildingOverride {
  const UniqueBuildingOverride();
}

class StartingBonus {
  const StartingBonus();
}

class CivilizationProfile {
  final PlayerCountry country;
  final String displayName;
  final AiPersona defaultPersona;
  final PersonaWeights civBias;
  final double belligerence;
  final double expansionDistance;
  final double frontierTolerance;
  final TechBranchPreferences techBias;
  final List<UniqueUnitOverride> uniqueUnits;
  final List<UniqueBuildingOverride> uniqueBuildings;
  final List<StartingBonus> startingBonuses;

  const CivilizationProfile({
    required this.country,
    required this.displayName,
    required this.defaultPersona,
    required this.civBias,
    required this.belligerence,
    required this.expansionDistance,
    required this.frontierTolerance,
    required this.techBias,
    this.uniqueUnits = const [],
    this.uniqueBuildings = const [],
    this.startingBonuses = const [],
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
        other.techBias == techBias &&
        listEquals(other.uniqueUnits, uniqueUnits) &&
        listEquals(other.uniqueBuildings, uniqueBuildings) &&
        listEquals(other.startingBonuses, startingBonuses);
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
      Object.hashAll(uniqueUnits),
      Object.hashAll(uniqueBuildings),
      Object.hashAll(startingBonuses),
    );
  }
}
