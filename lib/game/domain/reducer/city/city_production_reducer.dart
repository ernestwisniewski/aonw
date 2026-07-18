import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/city_selection_projector.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

part 'city_production_reducer_rush.dart';
part 'city_production_reducer_building.dart';
part 'city_production_reducer_project.dart';
part 'city_production_reducer_specialization.dart';
part 'city_production_reducer_unit.dart';
part 'city_production_reducer_wonder.dart';

abstract final class CityProductionReducer {
  static GameStateTransition startBuilding(
    GameState state,
    StartBuildingCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
    GameRuleset ruleset = GameRuleset.defaults,
  }) => _startBuildingProduction(
    state,
    command,
    mapTiles,
    context: context,
    ruleset: ruleset,
  );

  static GameStateTransition startUnitProduction(
    GameState state,
    StartUnitProductionCommand command,
    MapReadView mapView, {
    GameCommandContext context = const GameCommandContext(),
    GameRuleset ruleset = GameRuleset.defaults,
  }) => _startUnitProduction(
    state,
    command,
    mapView,
    context: context,
    ruleset: ruleset,
  );

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
  }) => _setCitySpecialization(
    state,
    command,
    mapTiles,
    context: context,
    ruleset: ruleset,
  );

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
