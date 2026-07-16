import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/city_selection_projector.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/technology.dart';
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
    final cityIndex = state.cities.indexWhere(
      (city) => city.id == command.cityId,
    );
    if (cityIndex == -1) return GameStateTransition(state: state);

    final city = state.cities[cityIndex];
    if (!context.canControlCity(state, city)) {
      return GameStateTransition(state: state);
    }

    final target = CityHex(col: command.col, row: command.row);
    if (!_isCandidate(
      city: city,
      target: target,
      state: state,
      mapTiles: mapTiles,
      ruleset: ruleset,
    )) {
      return GameStateTransition(state: state);
    }

    final updatedCity = city.copyWith(preferredExpansionHex: target);
    final updatedCities = [...state.cities]..[cityIndex] = updatedCity;
    var next = state.copyWith(cities: updatedCities);
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

  static bool _isCandidate({
    required GameCity city,
    required CityHex target,
    required GameState state,
    required MapTileLookup mapTiles,
    required GameRuleset ruleset,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: city.ownerPlayerId,
      research: state.research,
      ruleset: ruleset.technology,
    );
    final candidates = CityExpansionSelector.candidatesFor(
      city: city,
      mapTiles: mapTiles,
      cities: state.cities,
      allowCoast: true,
      allowOcean: true,
      ruleset: ruleset.city,
      technologyEffects: technologyEffects,
    );
    for (final candidate in candidates) {
      if (candidate.hex == target) return true;
    }
    return false;
  }
}
