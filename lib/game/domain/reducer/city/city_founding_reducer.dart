import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract final class CityFoundingReducer {
  static GameClientState startCityFounding(
    GameClientState state,
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

  static GameClientState cancelCityFounding(GameClientState state) {
    return state.copyWithInteraction(cityFoundingDraft: null);
  }

  static GameClientState toggleControlledHex(
    GameClientState state,
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
}
