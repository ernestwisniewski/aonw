import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/city/city_production_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract final class CityWorkedHexReducer {
  static GameStateTransition toggleWorkedHex(
    GameState state,
    ToggleWorkedHexCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
    GameRuleset ruleset = GameRuleset.defaults,
  }) {
    final cityIndex = state.cities.indexWhere((c) => c.id == command.cityId);
    if (cityIndex == -1) return GameStateTransition(state: state);

    final city = state.cities[cityIndex];
    if (!context.canControlCity(state, city)) {
      return GameStateTransition(state: state);
    }

    final target = CityHex(col: command.col, row: command.row);
    if (target == city.center || !city.controlledHexes.contains(target)) {
      return GameStateTransition(state: state);
    }

    final manualHexes = CityProductionReducer.normalizedWorkedHexes(
      city,
      ruleset.city,
    );
    late final List<CityHex> updatedWorkedHexes;
    if (manualHexes.contains(target)) {
      updatedWorkedHexes = [
        for (final hex in manualHexes)
          if (hex != target) hex,
      ];
    } else {
      final limit = ruleset.city.progression.workedHexLimitForPopulation(
        city.population,
      );
      if (manualHexes.length >= limit) {
        return GameStateTransition(state: state);
      }
      updatedWorkedHexes = [...manualHexes, target];
    }

    final updatedCity = city.copyWith(workedHexes: updatedWorkedHexes);
    return CityProductionReducer.finishQueuedProductionUpdate(
      state,
      updatedCity: updatedCity,
      cityIndex: cityIndex,
      cityId: city.id,
      mapTiles: mapTiles,
      ruleset: ruleset,
      paceBalance: context.paceBalance,
    );
  }
}
