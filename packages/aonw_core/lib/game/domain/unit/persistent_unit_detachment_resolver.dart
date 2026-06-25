import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_cost_rules.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/map_data.dart';

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
    required MapDefinition mapDefinition,
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

    final mapData = _mapDataFromDefinition(mapDefinition);
    if (mapData.tileAt(source.col, source.row) == null) {
      return _reject(state, 'detachment_source_out_of_bounds');
    }

    final destination = _detachmentDestinationFor(
      source,
      state,
      mapData,
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

    final updatedUnits = [
      for (final unit in state.units)
        if (unit.id == source.id) detachment.updatedSource else unit,
      detachment.detachedUnit,
    ];
    final updatedFog = fogOfWarService.recompute(
      current: state.fogOfWar,
      mapData: mapData,
      playerIds: _knownPlayerIds(state),
      units: updatedUnits,
      cities: state.cities,
    );

    return PersistentUnitDetachmentResult(
      accepted: true,
      state: state.copyWith(units: updatedUnits, fogOfWar: updatedFog),
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
    MapData mapData, {
    required FogVisibilityQuery visibility,
  }) {
    for (final neighbor in HexGridTopology.neighbors(
      col: source.col,
      row: source.row,
    )) {
      final tile = mapData.tileAt(neighbor.col, neighbor.row);
      if (tile == null) continue;
      if (!visibility.canInspectTile(tile)) continue;
      if (_unitAt(state.units, neighbor.col, neighbor.row) != null) continue;
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

  static MapData _mapDataFromDefinition(MapDefinition mapDefinition) {
    return MapData(
      cols: mapDefinition.cols,
      rows: mapDefinition.rows,
      mapName: mapDefinition.mapName,
      defaultZoom: mapDefinition.defaultZoom,
      tiles: [
        for (final tile in mapDefinition.tiles)
          TileData(
            col: tile.col,
            row: tile.row,
            terrains: tile.terrains,
            resources: tile.resources,
            height: tile.height,
          ),
      ],
    );
  }

  static int? _unitIndexById(List<GameUnit> units, String unitId) {
    for (var i = 0; i < units.length; i++) {
      if (units[i].id == unitId) return i;
    }
    return null;
  }

  static GameUnit? _unitAt(List<GameUnit> units, int col, int row) {
    for (final unit in units) {
      if (unit.col == col && unit.row == row) return unit;
    }
    return null;
  }

  static Set<String> _knownPlayerIds(PersistentGameState state) {
    return {
      ...state.playerColors.keys,
      ...state.playerGold.keys,
      ...state.fogOfWar.playerIds,
      for (final unit in state.units) unit.ownerPlayerId,
      for (final city in state.cities) city.ownerPlayerId,
    };
  }
}
