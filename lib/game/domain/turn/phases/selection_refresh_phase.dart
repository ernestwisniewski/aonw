import 'package:aonw/game/domain/city_selection_projector.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';

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
          selection: CitySelectionProjector.project(
            state: state,
            city: foundedCity,
            mapTiles: context.mapTiles,
            cityRuleset: context.ruleset.city,
            technologyRuleset: context.ruleset.technology,
            stabilityRuleset: context.ruleset.stability,
            wonderRuleset: context.ruleset.wonders,
            paceBalance: context.ruleset.paceBalance,
          ),
        );
      }
      return state.copyWithInteraction(selection: null);
    }

    return state.copyWithInteraction(
      selection: GameSelection.unit(
        updatedUnit,
        tile: context.mapTiles.tileAt(updatedUnit.col, updatedUnit.row),
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
        tile: context.mapTiles.tileAt(
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
      selection: CitySelectionProjector.project(
        state: state,
        city: updatedCity,
        mapTiles: context.mapTiles,
        cityRuleset: context.ruleset.city,
        technologyRuleset: context.ruleset.technology,
        stabilityRuleset: context.ruleset.stability,
        wonderRuleset: context.ruleset.wonders,
        paceBalance: context.ruleset.paceBalance,
      ),
    );
  }
}
