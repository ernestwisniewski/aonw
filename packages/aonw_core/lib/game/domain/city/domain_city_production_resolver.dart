import 'package:aonw_core/game/domain/city/city_production_command_resolver.dart';
import 'package:aonw_core/game/domain/city/city_production_queue.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/city/rush_production_command_resolver.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/match_rules/strategic_resource_economy_profile.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_rulesets.dart';
import 'package:aonw_core/game/domain/wonder/wonder_ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainCityProductionResult {
  const DomainCityProductionResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final List<GameEvent> events;
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
    return _fromTargetCommandResult(state, result, cityId: command.cityId);
  }

  DomainCityProductionResult startUnitProduction({
    required DomainState state,
    required StartUnitProductionCommand command,
    required String actorPlayerId,
    required MapReadView mapView,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final result = CityProductionCommandResolver.startUnitProduction(
      cities: state.cities,
      units: state.units,
      artifacts: state.artifacts,
      fieldImprovements: state.fieldImprovements,
      research: state.research,
      resourceTradeAgreements: state.resourceTradeAgreements,
      mapView: mapView,
      command: command,
      actorPlayerId: actorPlayerId,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
      strategicResources: state.strategicResources,
      strategicResourceEconomy: state.matchRules.strategicResourceEconomy,
    );
    return _fromTargetCommandResult(
      state,
      result,
      cityId: command.cityId,
      allocation: result.resourceAllocation,
    );
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
    return _fromTargetCommandResult(state, result, cityId: command.cityId);
  }

  DomainCityProductionResult startWonder({
    required DomainState state,
    required StartWonderCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final result = CityProductionCommandResolver.startWonder(
      cities: state.cities,
      research: state.research,
      wonderRegistry: state.wonderRegistry,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      wonderRuleset: wonderRuleset,
      paceBalance: paceBalance,
    );
    return _fromTargetCommandResult(state, result, cityId: command.cityId);
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

  DomainCityProductionResult rushProduction({
    required DomainState state,
    required RushProductionCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    StabilityRuleset stabilityRuleset = StabilityRuleset.standard,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final result = RushProductionCommandResolver.resolve(
      cities: state.cities,
      units: state.units,
      artifacts: state.artifacts,
      fieldImprovements: state.fieldImprovements,
      playerGold: state.playerGold,
      playerStabilityNet: state.playerStabilityNet,
      research: state.research,
      wonderRegistry: state.wonderRegistry,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityRuleset: stabilityRuleset,
      wonderRuleset: wonderRuleset,
      paceBalance: paceBalance,
    );
    return _fromRushResult(state, result);
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

  DomainCityProductionResult _fromTargetCommandResult(
    DomainState state,
    CityProductionCommandResult result, {
    required String cityId,
    StrategicResourceAccounts? strategicResources,
    StrategicResourceBundle allocation = StrategicResourceBundle.empty,
  }) {
    if (!result.accepted) return _fromCommandResult(state, result);
    if (identical(result.cities, state.cities)) {
      return DomainCityProductionResult(accepted: true, state: state);
    }
    final stockpilesEnabled =
        state.matchRules.strategicResourceEconomy ==
        StrategicResourceEconomyProfile.stockpileV1;
    var accounts =
        strategicResources ??
        (stockpilesEnabled
            ? _accountsAfterRefund(state, cityId)
            : state.strategicResources);
    final sourceCity = state.cities
        .where((candidate) => candidate.id == cityId)
        .firstOrNull;
    if (stockpilesEnabled && sourceCity != null && !allocation.isEmpty) {
      accounts = accounts.debit(sourceCity.ownerPlayerId, allocation);
    }
    final cities = [
      for (final city in result.cities)
        if (city.id == cityId && city.productionQueue != null)
          city.copyWith(
            productionQueue: CityProductionQueue.target(
              target: city.productionQueue!.target,
              investedProduction: city.productionQueue!.investedProduction,
              resourceAllocation: allocation,
            ),
          )
        else
          city,
    ];
    return DomainCityProductionResult(
      accepted: true,
      state: state.withStrategicProductionState(
        cities: List.unmodifiable(cities),
        strategicResources: accounts,
      ),
    );
  }

  DomainCityProductionResult _fromRushResult(
    DomainState state,
    RushProductionCommandResult result,
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
      state: state.copyWith(
        cities: identical(result.cities, state.cities) ? null : result.cities,
        units: identical(result.units, state.units) ? null : result.units,
        playerGold: identical(result.playerGold, state.playerGold)
            ? null
            : result.playerGold,
        research: identical(result.research, state.research)
            ? null
            : result.research,
        wonderRegistry: identical(result.wonderRegistry, state.wonderRegistry)
            ? null
            : result.wonderRegistry,
      ),
      events: result.events,
    );
  }
}

StrategicResourceAccounts _accountsAfterRefund(
  DomainState state,
  String cityId,
) {
  final city = state.cities
      .where((candidate) => candidate.id == cityId)
      .firstOrNull;
  final allocation = city?.productionQueue?.resourceAllocation;
  if (city == null || allocation == null || allocation.isEmpty) {
    return state.strategicResources;
  }
  return state.strategicResources.credit(city.ownerPlayerId, allocation);
}
