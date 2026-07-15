import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_cost_rules.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';

class PersistentUnitDetachmentResult {
  const PersistentUnitDetachmentResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final String? reason;
}

class PersistentUnitDetachmentResolver {
  const PersistentUnitDetachmentResolver({
    this.fogOfWarService = const FogOfWarService(),
  });

  final FogOfWarService fogOfWarService;

  PersistentUnitDetachmentResult detachTroop({
    required PersistentGameState state,
    required DetachTroopCommand command,
    required String actorPlayerId,
    required WorldMap worldMap,
  }) {
    final sourceIndex = _unitIndexById(state.units, command.unitId);
    if (sourceIndex == null) return _reject(state, 'unit_not_found');

    final source = state.units[sourceIndex];
    if (source.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'unit_not_controlled');
    }
    if (!source.canDetachTroop(command.troopType)) {
      return _reject(state, 'troop_not_available');
    }

    final mapTiles = WorldMapReadView(worldMap);
    if (mapTiles.tileAt(source.col, source.row) == null) {
      return _reject(state, 'detachment_source_out_of_bounds');
    }

    final destination = _detachmentDestinationFor(
      source,
      state,
      mapTiles,
      visibility: FogVisibilityQuery(
        playerId: actorPlayerId,
        state: state.fogOfWar,
      ),
    );
    if (destination == null) {
      return _reject(state, 'detachment_destination_unavailable');
    }

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
    if (detachment == null) return _reject(state, 'troop_not_available');

    return PersistentUnitDetachmentResult(
      accepted: true,
      state: _stateAfterDetachment(
        state: state,
        source: source,
        detachment: detachment,
        mapTiles: mapTiles,
      ),
    );
  }

  PersistentGameState _stateAfterDetachment({
    required PersistentGameState state,
    required GameUnit source,
    required UnitDetachmentResult detachment,
    required MapTileLookup mapTiles,
  }) {
    final updatedUnits = [
      for (final unit in state.units)
        if (unit.id == source.id) detachment.updatedSource else unit,
      detachment.detachedUnit,
    ];
    final updatedFog = fogOfWarService.recomputePlayer(
      current: state.fogOfWar,
      mapData: mapTiles,
      playerId: source.ownerPlayerId,
      units: updatedUnits,
      cities: state.cities,
    );
    final updatedDiplomacy = DiplomaticContact.mergeDiscoveredContacts(
      diplomacy: state.runtimeState.diplomacy,
      fogOfWar: updatedFog,
      units: updatedUnits,
      cities: state.cities,
      playerIds: state.knownPlayerIds,
    );
    return state.copyWith(
      units: updatedUnits,
      fogOfWar: updatedFog,
      runtimeState: state.runtimeState.copyWith(diplomacy: updatedDiplomacy),
    );
  }

  PersistentUnitDetachmentResult _reject(
    PersistentGameState state,
    String reason,
  ) {
    return PersistentUnitDetachmentResult(
      accepted: false,
      state: state,
      reason: reason,
    );
  }

  static ({int col, int row})? _detachmentDestinationFor(
    GameUnit source,
    PersistentGameState state,
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
      if (state.units.unitAt(neighbor.col, neighbor.row) != null) continue;
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

  static int? _unitIndexById(List<GameUnit> units, String unitId) {
    for (var i = 0; i < units.length; i++) {
      if (units[i].id == unitId) return i;
    }
    return null;
  }
}
