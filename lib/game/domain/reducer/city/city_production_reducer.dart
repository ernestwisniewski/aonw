import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/city_selection_projector.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder/wonder_availability_policy.dart';
import 'package:aonw_core/game/domain/wonder/wonder_completion_resolver.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

part 'city_production_reducer_rush.dart';
part 'city_production_reducer_project.dart';
part 'city_production_reducer_supply.dart';
part 'city_production_reducer_wonder.dart';

typedef _RushProductionApplication = ({
  GameCity city,
  List<GameUnit> units,
  List<GameEvent> events,
});

abstract final class CityProductionReducer {
  static GameStateTransition startBuilding(
    GameState state,
    StartBuildingCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
    GameRuleset ruleset = GameRuleset.defaults,
  }) {
    final target = _controlledCityTarget(state, command.cityId, context);
    if (target == null) {
      return GameStateTransition(state: state);
    }
    final city = target.city;

    final technologyUnlocked = TechnologyUnlockQuery.hasBuildingUnlocked(
      playerId: city.ownerPlayerId,
      buildingType: command.buildingType,
      research: state.research,
      ruleset: ruleset.technology,
    );
    final requirementsMet = CityBuildingRequirementRules.meetsRequirements(
      city: city,
      buildingType: command.buildingType,
      mapTiles: mapTiles,
      ruleset: ruleset.city,
      research: state.research,
    );
    if (!CityProductionRules.canBuild(
      city.buildings,
      command.buildingType,
      ruleset: ruleset.city,
      technologyUnlocked: technologyUnlocked,
      requirementsMet: requirementsMet,
    )) {
      return GameStateTransition(state: state);
    }

    final updatedCity = _queueProduction(
      city,
      BuildingProductionTarget(command.buildingType),
      ruleset,
      context.paceBalance,
    );

    return _finishQueuedProductionUpdate(
      state,
      updatedCity: updatedCity,
      cityIndex: target.index,
      cityId: command.cityId,
      mapTiles: mapTiles,
      ruleset: ruleset,
      paceBalance: context.paceBalance,
    );
  }

  static GameStateTransition startUnitProduction(
    GameState state,
    StartUnitProductionCommand command,
    MapReadView mapView, {
    GameCommandContext context = const GameCommandContext(),
    GameRuleset ruleset = GameRuleset.defaults,
  }) {
    final target = _controlledCityTarget(state, command.cityId, context);
    if (target == null) {
      return GameStateTransition(state: state);
    }
    final city = target.city;

    final technologyUnlocked = TechnologyUnlockQuery.hasUnitUnlocked(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      research: state.research,
      ruleset: ruleset.technology,
    );
    final requirementsMet = UnitProductionRequirementRules.meetsRequirements(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      cities: state.cities,
      mapTiles: mapView,
      ruleset: ruleset.city,
      research: state.research,
      resourceTradeAgreements: state.resourceTradeAgreements,
    );
    if (!CityProductionRules.canProduceUnit(
      command.unitType,
      ruleset: ruleset.city,
      technologyUnlocked: technologyUnlocked,
      requirementsMet: requirementsMet,
    )) {
      return GameStateTransition(state: state);
    }
    if (!CityUnitProductionRules.canProduceInCity(
      city: city,
      unitType: command.unitType,
      mapTiles: mapView,
    )) {
      return GameStateTransition(state: state);
    }
    final hasSupply = _canQueueCityUnit(
      state: state,
      city: city,
      unitType: command.unitType,
      mapView: mapView,
      ruleset: ruleset,
    );
    if (!hasSupply) {
      return GameStateTransition(state: state);
    }

    final updatedCity = _queueProduction(
      city,
      UnitProductionTarget(command.unitType),
      ruleset,
      context.paceBalance,
    );

    return _finishQueuedProductionUpdate(
      state,
      updatedCity: updatedCity,
      cityIndex: target.index,
      cityId: command.cityId,
      mapTiles: mapView,
      ruleset: ruleset,
      paceBalance: context.paceBalance,
    );
  }

  static GameStateTransition startCityProject(
    GameState state,
    StartCityProjectCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
    GameRuleset ruleset = GameRuleset.defaults,
  }) => _startCityProject(
    state,
    command,
    mapTiles,
    context: context,
    ruleset: ruleset,
  );

  static GameStateTransition startWonder(
    GameState state,
    StartWonderCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
    GameRuleset ruleset = GameRuleset.defaults,
  }) => _startWonderProduction(
    state,
    command,
    mapTiles,
    context: context,
    ruleset: ruleset,
  );

  static GameStateTransition setCitySpecialization(
    GameState state,
    SetCitySpecializationCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
    GameRuleset ruleset = GameRuleset.defaults,
  }) {
    final target = _controlledCityTarget(state, command.cityId, context);
    if (target == null) {
      return GameStateTransition(state: state);
    }
    final city = target.city;

    if (!state.research
        .forPlayer(city.ownerPlayerId)
        .hasUnlocked(TechnologyId.specialization)) {
      return GameStateTransition(state: state);
    }
    if (city.specialization == command.specialization) {
      return GameStateTransition(state: state);
    }
    if (!CitySpecializationRules.hasRequiredBuilding(
      city.buildings,
      command.specialization,
    )) {
      return GameStateTransition(state: state);
    }

    final updatedCity = city.copyWith(specialization: command.specialization);

    return _finishQueuedProductionUpdate(
      state,
      updatedCity: updatedCity,
      cityIndex: target.index,
      cityId: command.cityId,
      mapTiles: mapTiles,
      ruleset: ruleset,
      paceBalance: context.paceBalance,
    );
  }

  static GameStateTransition rushProduction(
    GameState state,
    RushProductionCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
    GameRuleset ruleset = GameRuleset.defaults,
  }) => _rushCityProduction(
    state,
    command,
    mapTiles,
    context: context,
    ruleset: ruleset,
  );

  static GameStateTransition finishQueuedProductionUpdate(
    GameState state, {
    required GameCity updatedCity,
    required int cityIndex,
    required String cityId,
    required MapTileLookup mapTiles,
    GameRuleset ruleset = GameRuleset.defaults,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) => _finishQueuedProductionUpdate(
    state,
    updatedCity: updatedCity,
    cityIndex: cityIndex,
    cityId: cityId,
    mapTiles: mapTiles,
    ruleset: ruleset,
    paceBalance: paceBalance,
  );

  static GameSelection citySelection(
    GameState state,
    GameCity city,
    MapTileLookup mapTiles, {
    GameRuleset ruleset = GameRuleset.defaults,
    PaceBalance? paceBalance,
  }) => CitySelectionProjector.project(
    state: state,
    city: city,
    mapTiles: mapTiles,
    ruleset: ruleset,
    paceBalance: paceBalance,
  );

  static GameCity _queueProduction(
    GameCity city,
    CityProductionTarget target,
    GameRuleset ruleset,
    PaceBalance paceBalance,
  ) {
    final activeInvestment = city.productionQueue?.investedProduction;
    final rolloverInvestment = activeInvestment == null
        ? CityProductionRules.rolloverInvestment(
            storedOverflow: city.productionOverflow,
            productionCost: CityProductionRules.targetCost(
              target,
              ruleset: ruleset.city,
              wonderRuleset: ruleset.wonders,
              paceBalance: paceBalance,
            ),
          )
        : 0;
    return city.copyWith(
      productionQueue: CityProductionQueue.target(
        target: target,
        investedProduction: activeInvestment ?? rolloverInvestment,
      ),
      productionOverflow: activeInvestment == null
          ? 0
          : city.productionOverflow,
    );
  }

  static ({int index, GameCity city})? _controlledCityTarget(
    GameState state,
    String cityId,
    GameCommandContext context,
  ) {
    final cityIndex = state.cities.indexWhere((city) => city.id == cityId);
    if (cityIndex == -1) return null;

    final city = state.cities[cityIndex];
    if (!context.canControlCity(state, city)) return null;
    return (index: cityIndex, city: city);
  }

  static List<GameCity> _replaceCityAt(
    List<GameCity> cities, {
    required int index,
    required GameCity city,
  }) => [...cities]..[index] = city;

  static GameStateTransition _finishQueuedProductionUpdate(
    GameState state, {
    required GameCity updatedCity,
    required int cityIndex,
    required String cityId,
    required MapTileLookup mapTiles,
    required GameRuleset ruleset,
    required PaceBalance paceBalance,
  }) {
    final updatedCities = _replaceCityAt(
      state.cities,
      index: cityIndex,
      city: updatedCity,
    );
    var next = state.copyWith(cities: updatedCities);

    next = _refreshCitySelectionIfSelected(
      next,
      cityId: cityId,
      city: updatedCity,
      mapTiles: mapTiles,
      ruleset: ruleset,
      paceBalance: paceBalance,
    );

    return GameStateTransition(state: next);
  }

  static GameState _refreshCitySelectionIfSelected(
    GameState state, {
    required String cityId,
    required GameCity city,
    required MapTileLookup mapTiles,
    required GameRuleset ruleset,
    required PaceBalance paceBalance,
  }) {
    final selection = state.selection;
    if (selection?.type != GameSelectionType.city ||
        selection?.city?.id != cityId) {
      return state;
    }

    return state.copyWithInteraction(
      selection: CitySelectionProjector.project(
        state: state,
        city: city,
        mapTiles: mapTiles,
        ruleset: ruleset,
        paceBalance: paceBalance,
      ),
    );
  }
}
