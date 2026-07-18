import 'package:aonw_core/game/domain/city/city_production_command_resolver.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_rulesets.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainCityProductionResult {
  const DomainCityProductionResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final String? reason;
}

/// Canonical-state adapter for the state-neutral city-production resolver.
final class DomainCityProductionResolver {
  const DomainCityProductionResolver();

  DomainCityProductionResult startBuilding({
    required DomainState state,
    required StartBuildingCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final result = CityProductionCommandResolver.startBuilding(
      cities: state.cities,
      research: state.research,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
    return _fromCommandResult(state, result);
  }

  DomainCityProductionResult startCityProject({
    required DomainState state,
    required StartCityProjectCommand command,
    required String actorPlayerId,
    CityRuleset cityRuleset = CityRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final result = CityProductionCommandResolver.startCityProject(
      cities: state.cities,
      command: command,
      actorPlayerId: actorPlayerId,
      cityRuleset: cityRuleset,
      paceBalance: paceBalance,
    );
    return _fromCommandResult(state, result);
  }

  DomainCityProductionResult setCitySpecialization({
    required DomainState state,
    required SetCitySpecializationCommand command,
    required String actorPlayerId,
  }) {
    final result = CityProductionCommandResolver.setCitySpecialization(
      cities: state.cities,
      research: state.research,
      command: command,
      actorPlayerId: actorPlayerId,
    );
    return _fromCommandResult(state, result);
  }

  DomainCityProductionResult _fromCommandResult(
    DomainState state,
    CityProductionCommandResult result,
  ) {
    if (!result.accepted) {
      return DomainCityProductionResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    return DomainCityProductionResult(
      accepted: true,
      state: identical(result.cities, state.cities)
          ? state
          : state.copyWith(cities: result.cities),
    );
  }
}
