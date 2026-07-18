import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology/research_overflow_rules.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/technology_availability_service.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_rulesets.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Persistence-neutral result of selecting an active technology.
final class SelectTechnologyResult {
  const SelectTechnologyResult._accepted({required this.research})
    : accepted = true,
      reason = null;

  const SelectTechnologyResult._rejected({
    required this.research,
    required this.reason,
  }) : accepted = false;

  final bool accepted;
  final String? reason;
  final ResearchState research;
}

/// Applies technology-selection rules without depending on a state container.
abstract final class SelectTechnologyResolver {
  static SelectTechnologyResult selectTechnology({
    required ResearchState research,
    required Iterable<GameCity> cities,
    required Iterable<FieldImprovement> fieldImprovements,
    required SelectTechnologyCommand command,
    required String actorPlayerId,
    MapTileLookup? mapTiles,
    TechnologyRuleset ruleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    if (command.playerId != actorPlayerId) {
      return _reject(research, 'technology_player_not_controlled');
    }

    final playerResearch = research.forPlayer(command.playerId);
    final availability = TechnologyAvailabilityService.availabilityFor(
      technologyId: command.technologyId,
      playerResearch: playerResearch,
      ruleset: ruleset,
    );
    if (availability != TechnologyAvailability.available) {
      return _reject(research, 'technology_not_available');
    }

    final updatedPlayer = ResearchOverflowRules.applyToSelectedTechnology(
      playerId: command.playerId,
      playerResearch: playerResearch,
      technologyId: command.technologyId,
      cities: cities,
      fieldImprovements: fieldImprovements,
      mapTiles: mapTiles,
      ruleset: ruleset,
      paceBalance: paceBalance,
    );
    return SelectTechnologyResult._accepted(
      research: research.updatePlayer(command.playerId, updatedPlayer),
    );
  }

  static SelectTechnologyResult _reject(ResearchState research, String reason) {
    return SelectTechnologyResult._rejected(research: research, reason: reason);
  }
}
