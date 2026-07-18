import 'package:aonw_core/game/domain/city/city_expansion_command_resolver.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_rulesets.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainCityExpansionResult {
  const DomainCityExpansionResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final String? reason;
}

/// Canonical-state adapter for the persistence-neutral expansion resolver.
final class DomainCityExpansionResolver {
  const DomainCityExpansionResolver();

  DomainCityExpansionResult selectExpansionHex({
    required DomainState state,
    required SelectCityExpansionHexCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    final result = CityExpansionCommandResolver.selectExpansionHex(
      cities: state.cities,
      research: state.research,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    );
    if (!result.accepted) {
      return DomainCityExpansionResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    return DomainCityExpansionResult(
      accepted: true,
      state: identical(result.cities, state.cities)
          ? state
          : state.copyWith(cities: result.cities),
    );
  }
}
