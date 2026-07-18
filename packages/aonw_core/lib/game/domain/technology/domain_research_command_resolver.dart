import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/technology/select_technology_resolver.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_rulesets.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainResearchCommandResult {
  const DomainResearchCommandResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final String? reason;
}

/// Canonical-state adapter for the persistence-neutral research resolver.
final class DomainResearchCommandResolver {
  const DomainResearchCommandResolver();

  DomainResearchCommandResult selectTechnology({
    required DomainState state,
    required SelectTechnologyCommand command,
    required String actorPlayerId,
    MapTileLookup? mapTiles,
    TechnologyRuleset ruleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final result = SelectTechnologyResolver.selectTechnology(
      research: state.research,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      ruleset: ruleset,
      paceBalance: paceBalance,
    );
    if (!result.accepted) {
      return DomainResearchCommandResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    return DomainResearchCommandResult(
      accepted: true,
      state: state.copyWith(research: result.research),
    );
  }
}
