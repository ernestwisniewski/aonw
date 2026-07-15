import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/city_selection_projector.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder/wonder_availability_policy.dart';
import 'package:aonw_core/game/domain/wonder/wonder_completion_resolver.dart';
import 'package:aonw_core/game/domain/wonder/wonder_ruleset.dart';

part 'city_production_reducer_rush.dart';
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
    MapData mapData, {
    GameCommandContext context = const GameCommandContext(),
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
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
      ruleset: technologyRuleset,
    );
    final requirementsMet = CityBuildingRequirementRules.meetsRequirements(
      city: city,
      buildingType: command.buildingType,
      mapTiles: mapData,
      ruleset: cityRuleset,
      research: state.research,
    );
    if (!CityProductionRules.canBuild(
      city.buildings,
      command.buildingType,
      ruleset: cityRuleset,
      technologyUnlocked: technologyUnlocked,
      requirementsMet: requirementsMet,
    )) {
      return GameStateTransition(state: state);
    }

    final updatedCity = _queueProduction(
      city,
      BuildingProductionTarget(command.buildingType),
      cityRuleset,
      context.paceBalance,
    );

    return _finishQueuedProductionUpdate(
      state,
      updatedCity: updatedCity,
      cityIndex: target.index,
      cityId: command.cityId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      wonderRuleset: wonderRuleset,
      paceBalance: context.paceBalance,
    );
  }

  static GameStateTransition startUnitProduction(
    GameState state,
    StartUnitProductionCommand command,
    MapData mapData, {
    GameCommandContext context = const GameCommandContext(),
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
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
      ruleset: technologyRuleset,
    );
    final requirementsMet = UnitProductionRequirementRules.meetsRequirements(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      cities: state.cities,
      mapTiles: mapData,
      ruleset: cityRuleset,
      research: state.research,
      resourceTradeAgreements: state.resourceTradeAgreements,
    );
    if (!CityProductionRules.canProduceUnit(
      command.unitType,
      ruleset: cityRuleset,
      technologyUnlocked: technologyUnlocked,
      requirementsMet: requirementsMet,
    )) {
      return GameStateTransition(state: state);
    }
    if (!CityUnitProductionRules.canProduceInCity(
      city: city,
      unitType: command.unitType,
      mapTiles: mapData,
    )) {
      return GameStateTransition(state: state);
    }
    final hasSupply = CityUnitSupplyRules.canQueueUnit(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      cities: state.cities,
      units: state.units,
      fieldImprovements: state.fieldImprovements,
      mapView: mapData,
      cityRuleset: cityRuleset,
      research: state.research,
      technologyRuleset: technologyRuleset,
      replacingCityId: city.id,
    );
    if (!hasSupply) {
      return GameStateTransition(state: state);
    }

    final updatedCity = _queueProduction(
      city,
      UnitProductionTarget(command.unitType),
      cityRuleset,
      context.paceBalance,
    );

    return _finishQueuedProductionUpdate(
      state,
      updatedCity: updatedCity,
      cityIndex: target.index,
      cityId: command.cityId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      wonderRuleset: wonderRuleset,
      paceBalance: context.paceBalance,
    );
  }

  static GameStateTransition startCityProject(
    GameState state,
    StartCityProjectCommand command,
    MapData mapData, {
    GameCommandContext context = const GameCommandContext(),
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
  }) {
    final target = _controlledCityTarget(state, command.cityId, context);
    if (target == null) {
      return GameStateTransition(state: state);
    }
    final city = target.city;

    final updatedCity = _queueProduction(
      city,
      ProjectProductionTarget(command.projectType),
      cityRuleset,
      context.paceBalance,
    );

    return _finishQueuedProductionUpdate(
      state,
      updatedCity: updatedCity,
      cityIndex: target.index,
      cityId: command.cityId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      wonderRuleset: wonderRuleset,
      paceBalance: context.paceBalance,
    );
  }

  static GameStateTransition startWonder(
    GameState state,
    StartWonderCommand command,
    MapData mapData, {
    GameCommandContext context = const GameCommandContext(),
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
  }) => _startWonderProduction(
    state,
    command,
    mapData,
    context: context,
    cityRuleset: cityRuleset,
    technologyRuleset: technologyRuleset,
    wonderRuleset: wonderRuleset,
  );

  static GameStateTransition setCitySpecialization(
    GameState state,
    SetCitySpecializationCommand command,
    MapData mapData, {
    GameCommandContext context = const GameCommandContext(),
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
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
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      wonderRuleset: wonderRuleset,
      paceBalance: context.paceBalance,
    );
  }

  static GameStateTransition rushProduction(
    GameState state,
    RushProductionCommand command,
    MapData mapData, {
    GameCommandContext context = const GameCommandContext(),
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
  }) => _rushCityProduction(
    state,
    command,
    mapData,
    context: context,
    cityRuleset: cityRuleset,
    technologyRuleset: technologyRuleset,
    wonderRuleset: wonderRuleset,
  );

  static GameStateTransition finishQueuedProductionUpdate(
    GameState state, {
    required GameCity updatedCity,
    required int cityIndex,
    required String cityId,
    required MapData mapData,
    required CityRuleset cityRuleset,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) => _finishQueuedProductionUpdate(
    state,
    updatedCity: updatedCity,
    cityIndex: cityIndex,
    cityId: cityId,
    mapData: mapData,
    cityRuleset: cityRuleset,
    technologyRuleset: technologyRuleset,
    wonderRuleset: wonderRuleset,
    paceBalance: paceBalance,
  );

  static List<CityHex> normalizedWorkedHexes(
    GameCity city,
    CityRuleset cityRuleset,
  ) => _normalizedWorkedHexes(city, cityRuleset);

  static GameSelection citySelection(
    GameState state,
    GameCity city,
    MapData mapData, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) => CitySelectionProjector.project(
    state: state,
    city: city,
    mapTiles: mapData,
    cityRuleset: cityRuleset,
    technologyRuleset: technologyRuleset,
    wonderRuleset: wonderRuleset,
    paceBalance: paceBalance,
  );

  static GameCity _queueProduction(
    GameCity city,
    CityProductionTarget target,
    CityRuleset cityRuleset,
    PaceBalance paceBalance, {
    WonderRuleset wonderRuleset = WonderRuleset.standard,
  }) {
    final activeInvestment = city.productionQueue?.investedProduction;
    final rolloverInvestment = activeInvestment == null
        ? CityProductionRules.rolloverInvestment(
            storedOverflow: city.productionOverflow,
            productionCost: CityProductionRules.targetCost(
              target,
              ruleset: cityRuleset,
              wonderRuleset: wonderRuleset,
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

  static List<CityHex> _normalizedWorkedHexes(
    GameCity city,
    CityRuleset cityRuleset,
  ) {
    final limit = cityRuleset.progression.workedHexLimitForPopulation(
      city.population,
    );
    if (limit <= 0) return const [];

    final normalized = <CityHex>[];
    final seen = <CityHex>{};
    for (final hex in city.workedHexes) {
      if (normalized.length >= limit) break;
      if (hex == city.center) continue;
      if (!city.controlledHexes.contains(hex)) continue;
      if (!seen.add(hex)) continue;
      normalized.add(hex);
    }
    return normalized;
  }

  static GameStateTransition _finishQueuedProductionUpdate(
    GameState state, {
    required GameCity updatedCity,
    required int cityIndex,
    required String cityId,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required WonderRuleset wonderRuleset,
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
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      wonderRuleset: wonderRuleset,
      paceBalance: paceBalance,
    );

    return GameStateTransition(state: next);
  }

  static GameState _refreshCitySelectionIfSelected(
    GameState state, {
    required String cityId,
    required GameCity city,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required WonderRuleset wonderRuleset,
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
        mapTiles: mapData,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        wonderRuleset: wonderRuleset,
        paceBalance: paceBalance,
      ),
    );
  }
}
