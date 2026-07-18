import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract final class CityFoundingReducer {
  static GameState startCityFounding(
    GameState state,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
    CityRuleset cityRuleset = CityRulesets.standard,
  }) {
    final unit = state.selectedUnit;
    if (unit == null || !context.canControlUnit(state, unit)) return state;
    if (unit.isWorking) return state;

    final centerTile = mapTiles.tileAt(unit.col, unit.row);
    if (!CityFoundingRules.canStart(
      unit: unit,
      centerTile: centerTile,
      cities: state.cities,
    )) {
      return state;
    }

    final center = CityHex(col: unit.col, row: unit.row);
    final candidates = CityInitialTerritorySelector.select(
      center: center,
      mapTiles: mapTiles,
      cities: state.cities,
      ruleset: cityRuleset,
    );
    if (candidates.length != CityFoundingDraft.requiredControlledHexes) {
      return state;
    }

    final draft = CityFoundingDraft(
      unitId: unit.id,
      ownerPlayerId: unit.ownerPlayerId,
      center: center,
    );

    return state.copyWithInteraction(
      moveCommandActive: false,
      movePreview: null,
      cityFoundingDraft: draft,
      pendingAction: null,
    );
  }

  static GameState cancelCityFounding(GameState state) {
    return state.copyWithInteraction(cityFoundingDraft: null);
  }

  static GameState toggleControlledHex(
    GameState state,
    TileTappedCommand command,
    MapTileLookup mapTiles,
  ) {
    final draft = state.cityFoundingDraft;
    if (draft == null) return state;

    final tile = mapTiles.tileAt(command.col, command.row);
    if (tile == null) return state;

    final target = CityHex(col: command.col, row: command.row);
    if (draft.controlledHexes.contains(target)) {
      return state.copyWithInteraction(
        cityFoundingDraft: draft.copyWith(
          controlledHexes: [
            for (final hex in draft.controlledHexes)
              if (hex != target) hex,
          ],
        ),
      );
    }

    if (draft.controlledHexes.length >=
        CityFoundingDraft.requiredControlledHexes) {
      return state;
    }

    if (!CityFoundingRules.isControlledHexCandidate(
      draft: draft,
      tile: tile,
      mapTiles: mapTiles,
      cities: state.cities,
    )) {
      return state;
    }

    return state.copyWithInteraction(
      cityFoundingDraft: draft.copyWith(
        controlledHexes: [...draft.controlledHexes, target],
      ),
    );
  }

  static GameStateTransition confirmCityFounding(
    GameState state,
    FoundCityCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    if (!context.canAct || (!context.hasActor && !state.activePlayerCanAct)) {
      return GameStateTransition(state: state);
    }

    final result = CityFoundingCommandResolver.foundCity(
      units: state.units,
      cities: state.cities,
      cityFoundingDraft: state.cityFoundingDraft,
      command: command,
      actorPlayerId: _actorPlayerId(state, command, context),
      mapTiles: mapTiles,
    );
    if (!result.accepted) return GameStateTransition(state: state);

    var next = state.copyWith(units: result.units);
    if (!identical(result.cityFoundingDraft, state.cityFoundingDraft)) {
      next = next.copyWithInteraction(
        cityFoundingDraft: result.cityFoundingDraft,
      );
    }
    if (state.selectedUnitId == command.founderId) {
      final updatedFounder = next.unitById(command.founderId)!;
      final founderTile = mapTiles.tileAt(
        updatedFounder.col,
        updatedFounder.row,
      );
      next = next.copyWithInteraction(
        selection: GameSelection.unit(updatedFounder, tile: founderTile),
      );
    }

    return GameStateTransition(state: next);
  }

  static String _actorPlayerId(
    GameState state,
    FoundCityCommand command,
    GameCommandContext context,
  ) {
    if (context.hasActor) return context.actorPlayerId!;
    if (state.activePlayerId.isNotEmpty) return state.activePlayerId;
    return state.unitById(command.founderId)?.ownerPlayerId ?? '';
  }
}
