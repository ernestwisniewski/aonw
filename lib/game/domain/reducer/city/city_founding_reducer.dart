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
    final draft = CityFoundingDraft(
      unitId: unit.id,
      ownerPlayerId: unit.ownerPlayerId,
      center: center,
    );
    if (!CityFoundingRules.canCompleteDraft(
      draft: draft,
      mapTiles: mapTiles,
      cities: state.cities,
    )) {
      return state;
    }

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

    final target = CityHex(col: command.col, row: command.row);
    final updatedDraft = CityFoundingRules.toggleControlledHexSelection(
      draft: draft,
      target: target,
      mapTiles: mapTiles,
      cities: state.cities,
    );
    if (identical(updatedDraft, draft)) return state;

    return state.copyWithInteraction(cityFoundingDraft: updatedDraft);
  }
}
