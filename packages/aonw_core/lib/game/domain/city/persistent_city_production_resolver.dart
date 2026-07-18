import 'package:aonw_core/game/domain/city/city_production_command_resolver.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/rush_production_command_resolver.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/wonder/wonder_ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

class PersistentCityProductionResult {
  const PersistentCityProductionResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final List<GameEvent> events;
  final String? reason;
}

class PersistentCityProductionResolver {
  const PersistentCityProductionResolver();

  PersistentCityProductionResult startBuilding({
    required PersistentGameState state,
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

  PersistentCityProductionResult startUnitProduction({
    required PersistentGameState state,
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
      resourceTradeAgreements: state.runtimeState.resourceTradeAgreements,
      mapView: mapView,
      command: command,
      actorPlayerId: actorPlayerId,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
    return _fromCommandResult(state, result);
  }

  PersistentCityProductionResult startCityProject({
    required PersistentGameState state,
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

  PersistentCityProductionResult startWonder({
    required PersistentGameState state,
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
    return _fromCommandResult(state, result);
  }

  PersistentCityProductionResult setCitySpecialization({
    required PersistentGameState state,
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

  PersistentCityProductionResult rushProduction({
    required PersistentGameState state,
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

  PersistentCityProductionResult _reject(
    PersistentGameState state,
    String reason,
  ) {
    return PersistentCityProductionResult(
      accepted: false,
      state: state,
      reason: reason,
    );
  }

  PersistentCityProductionResult _fromCommandResult(
    PersistentGameState state,
    CityProductionCommandResult result,
  ) {
    if (!result.accepted) return _reject(state, result.reason!);
    return PersistentCityProductionResult(
      accepted: true,
      state: identical(result.cities, state.cities)
          ? state
          : state.copyWith(cities: result.cities),
    );
  }

  PersistentCityProductionResult _fromRushResult(
    PersistentGameState state,
    RushProductionCommandResult result,
  ) {
    if (!result.accepted) return _reject(state, result.reason!);
    return PersistentCityProductionResult(
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
