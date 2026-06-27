import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/technology.dart';

abstract final class CityExpansionReducer {
  static GameStateTransition selectExpansionHex(
    GameState state,
    SelectCityExpansionHexCommand command,
    MapData mapData, {
    GameCommandContext context = const GameCommandContext(),
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
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
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    )) {
      return GameStateTransition(state: state);
    }

    final updatedCity = city.copyWith(preferredExpansionHex: target);
    final updatedCities = [...state.cities]..[cityIndex] = updatedCity;
    var next = state.copyWith(cities: updatedCities);
    if (next.selection?.type == GameSelectionType.city &&
        next.selection?.city?.id == updatedCity.id) {
      final cityYield = CityYieldCalculator.totalFor(
        updatedCity,
        mapData,
        fieldImprovements: next.fieldImprovements,
        units: next.units,
        artifacts: next.artifacts,
        ruleset: cityRuleset,
      );
      final technologyEffects = TechnologyEffectSummary.forPlayer(
        playerId: updatedCity.ownerPlayerId,
        research: next.research,
        ruleset: technologyRuleset,
      );
      next = next.copyWithInteraction(
        selection: GameSelection.city(
          updatedCity,
          cityYield: cityYield,
          cityEconomy: CityEconomyBreakdown.from(
            city: updatedCity,
            tileYield: cityYield,
            mapData: mapData,
            ruleset: cityRuleset,
            technologyEffects: technologyEffects,
          ),
          playerColor: next.colorForPlayer(updatedCity.ownerPlayerId) ?? 0,
        ),
      );
    }

    return GameStateTransition(state: next);
  }

  static bool _isCandidate({
    required GameCity city,
    required CityHex target,
    required GameState state,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: city.ownerPlayerId,
      research: state.research,
      ruleset: technologyRuleset,
    );
    final candidates = CityExpansionSelector.candidatesFor(
      city: city,
      mapData: mapData,
      cities: state.cities,
      allowCoast: true,
      allowOcean: true,
      ruleset: cityRuleset,
      technologyEffects: technologyEffects,
    );
    for (final candidate in candidates) {
      if (candidate.hex == target) return true;
    }
    return false;
  }
}
