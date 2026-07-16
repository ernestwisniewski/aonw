import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_player_ids.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract final class UnitAttachmentReducer {
  static GameStateTransition detachTroop(
    GameState state,
    DetachTroopCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
    FogOfWarService fogOfWarService = const FogOfWarService(),
  }) {
    final unitIndex = state.units.indexWhere((u) => u.id == command.unitId);
    if (unitIndex == -1) return GameStateTransition(state: state);

    final source = state.units[unitIndex];
    if (!context.canControlUnit(state, source)) {
      return GameStateTransition(state: state);
    }

    final destination = _detachmentDestinationFor(
      source,
      state,
      mapTiles,
      visibility: context.visibilityFor(state),
    );
    if (destination == null) return GameStateTransition(state: state);

    final detachedUnitId = _nextDetachedUnitId(
      source,
      command.troopType,
      state.units,
    );

    final detachment = UnitDetachmentRules.detachTroop(
      source: source,
      troopType: command.troopType,
      detachedUnitId: detachedUnitId,
      destinationCol: destination.col,
      destinationRow: destination.row,
    );
    if (detachment == null) return GameStateTransition(state: state);

    final updatedUnits = [
      for (final unit in state.units)
        if (unit.id == source.id) detachment.updatedSource else unit,
      detachment.detachedUnit,
    ];

    final newFog = fogOfWarService.recomputePlayer(
      current: state.fogOfWar,
      mapData: mapTiles,
      playerId: source.ownerPlayerId,
      units: updatedUnits,
      cities: state.cities,
    );

    final sourceTile = mapTiles.tileAt(
      detachment.updatedSource.col,
      detachment.updatedSource.row,
    );
    var next = withDiscoveredDiplomaticContacts(
      state.copyWith(units: updatedUnits, fogOfWar: newFog),
    );
    next = next.copyWithInteraction(
      moveCommandActive: false,
      movePreview: null,
      cityFoundingDraft: null,
      selection: GameSelection.unit(detachment.updatedSource, tile: sourceTile),
    );

    return GameStateTransition(state: next);
  }

  static ({int col, int row})? _detachmentDestinationFor(
    GameUnit source,
    GameState state,
    MapTileLookup mapTiles, {
    required FogVisibilityQuery visibility,
  }) {
    for (final neighbor in HexGridTopology.neighbors(
      col: source.col,
      row: source.row,
    )) {
      final tile = mapTiles.tileAt(neighbor.col, neighbor.row);
      if (tile == null) continue;
      if (!visibility.canInspectTile(tile)) continue;
      if (state.unitAt(neighbor.col, neighbor.row) != null) continue;
      if (UnitMovementCostRules.costToEnterTile(tile).blocked) continue;
      return neighbor;
    }
    return null;
  }

  static String _nextDetachedUnitId(
    GameUnit source,
    TroopType troopType,
    List<GameUnit> units,
  ) {
    final prefix = '${source.id}_${troopType.name}';
    var index = 1;
    while (units.any((unit) => unit.id == '${prefix}_$index')) {
      index++;
    }
    return '${prefix}_$index';
  }
}
