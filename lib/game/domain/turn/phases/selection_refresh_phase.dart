import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/technology.dart';

class SelectionRefreshPhase extends TurnPhase {
  const SelectionRefreshPhase();

  @override
  TurnContext apply(TurnContext context) {
    final state = context.state;
    final selection = state.selection;
    if (selection == null) return context;

    final refreshedState = switch (selection.type) {
      GameSelectionType.unit => _refreshUnitSelection(context),
      GameSelectionType.city => _refreshCitySelection(context),
      GameSelectionType.fieldImprovement => _refreshFieldImprovementSelection(
        context,
      ),
      GameSelectionType.tile => state,
    };

    return context.copyWith(state: refreshedState);
  }

  GameState _refreshUnitSelection(TurnContext context) {
    final state = context.state;
    final selectedId = state.selection?.unit?.id;
    if (selectedId == null) return state;

    final updatedUnit = state.unitById(selectedId);
    if (updatedUnit == null) {
      final previousUnit = state.selection?.unit;
      final foundedCity = previousUnit == null
          ? null
          : state.cities
                .where(
                  (city) =>
                      city.ownerPlayerId == previousUnit.ownerPlayerId &&
                      city.occupiesCenter(previousUnit.col, previousUnit.row),
                )
                .firstOrNull;
      if (foundedCity != null) {
        return state.copyWithInteraction(
          selection: _citySelection(
            state,
            foundedCity,
            context.mapData,
            cityRuleset: context.ruleset.city,
            technologyRuleset: context.ruleset.technology,
            paceBalance: context.ruleset.paceBalance,
          ),
        );
      }
      return state.copyWithInteraction(selection: null);
    }

    return state.copyWithInteraction(
      selection: GameSelection.unit(
        updatedUnit,
        tile: context.mapData.tileAt(updatedUnit.col, updatedUnit.row),
      ),
    );
  }

  GameState _refreshFieldImprovementSelection(TurnContext context) {
    final state = context.state;
    final selected = state.selection?.fieldImprovement;
    if (selected == null) return state.copyWithInteraction(selection: null);

    final updatedImprovement = state.fieldImprovements
        .where(
          (improvement) =>
              improvement.hex == selected.hex &&
              improvement.type == selected.type,
        )
        .firstOrNull;
    if (updatedImprovement == null) {
      return state.copyWithInteraction(selection: null);
    }

    return state.copyWithInteraction(
      selection: GameSelection.fieldImprovement(
        updatedImprovement,
        tile: context.mapData.tileAt(
          updatedImprovement.hex.col,
          updatedImprovement.hex.row,
        ),
      ),
    );
  }

  GameState _refreshCitySelection(TurnContext context) {
    final state = context.state;
    final selectedId = state.selection?.city?.id;
    if (selectedId == null) return state;

    final updatedCity = state.cityById(selectedId);
    if (updatedCity == null) return state;

    return state.copyWithInteraction(
      selection: _citySelection(
        state,
        updatedCity,
        context.mapData,
        cityRuleset: context.ruleset.city,
        technologyRuleset: context.ruleset.technology,
        paceBalance: context.ruleset.paceBalance,
      ),
    );
  }

  GameSelection _citySelection(
    GameState state,
    GameCity city,
    MapData mapData, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final cityYield = CityYieldCalculator.totalFor(
      city,
      mapData,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      artifacts: state.artifacts,
      ruleset: cityRuleset,
    );
    final cityEconomy = CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapData: mapData,
      ruleset: cityRuleset,
      paceBalance: paceBalance,
      technologyEffects: TechnologyEffectSummary.forPlayer(
        playerId: city.ownerPlayerId,
        research: state.research,
        ruleset: technologyRuleset,
      ),
    );
    return GameSelection.city(
      city,
      cityYield: cityYield,
      cityEconomy: cityEconomy,
      playerColor:
          state.colorForPlayer(city.ownerPlayerId) ?? Player.palette.first,
    );
  }
}
