import 'package:aonw_core/game/domain/technology/player_research_state.dart';
import 'package:aonw_core/game/domain/technology/technology_id.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';

enum TechnologyAvailability {
  unlocked,
  active,
  available,
  lockedByPrerequisites,
  lockedByTechnology,
}

abstract final class TechnologyAvailabilityService {
  static TechnologyAvailability availabilityFor({
    required TechnologyId technologyId,
    required PlayerResearchState playerResearch,
    required TechnologyRuleset ruleset,
  }) {
    if (playerResearch.hasUnlocked(technologyId)) {
      return TechnologyAvailability.unlocked;
    }
    final definition = ruleset.definitionFor(technologyId);
    final isBlocked = definition.blockedBy.any(playerResearch.hasUnlocked);
    if (isBlocked) {
      return TechnologyAvailability.lockedByTechnology;
    }

    final hasPrerequisites = definition.prerequisites.every(
      playerResearch.hasUnlocked,
    );
    if (!hasPrerequisites) {
      return TechnologyAvailability.lockedByPrerequisites;
    }

    if (playerResearch.activeTechnologyId == technologyId) {
      return TechnologyAvailability.active;
    }

    return TechnologyAvailability.available;
  }
}
