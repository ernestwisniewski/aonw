import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/city_selection_projector.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract final class CityExpansionReducer {
  static GameStateTransition selectExpansionHexWithEnvironment(
    GameState state,
    SelectCityExpansionHexCommand command,
    ReducerEnvironment environment,
  ) => selectExpansionHex(
    state,
    command,
    environment.mapData,
    context: environment.context,
    ruleset: environment.ruleset,
  );

  static GameStateTransition selectExpansionHex(
    GameState state,
    SelectCityExpansionHexCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
    GameRuleset ruleset = GameRuleset.defaults,
  }) {
    final cities = state.cities;
    final cityIndex = cities.indexWhere((city) => city.id == command.cityId);
    if (cityIndex == -1) return GameStateTransition(state: state);

    final city = cities[cityIndex];
    if (!context.canControlCity(state, city)) {
      return GameStateTransition(state: state);
    }
    final result = CityExpansionCommandResolver.selectExpansionHex(
      cities: cities,
      research: state.research,
      command: command,
      actorPlayerId: city.ownerPlayerId,
      mapTiles: mapTiles,
      cityRuleset: ruleset.city,
      technologyRuleset: ruleset.technology,
    );
    if (!result.accepted) return GameStateTransition(state: state);
    if (identical(result.cities, cities)) {
      return GameStateTransition(state: state);
    }

    final updatedCity = result.cities[cityIndex];
    var next = state.copyWith(cities: result.cities);
    if (next.selection?.type == GameSelectionType.city &&
        next.selection?.city?.id == updatedCity.id) {
      next = next.copyWithInteraction(
        selection: CitySelectionProjector.project(
          state: next,
          city: updatedCity,
          mapTiles: mapTiles,
          ruleset: ruleset,
          paceBalance: context.paceBalance,
        ),
      );
    }

    return GameStateTransition(state: next);
  }
}
