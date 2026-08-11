import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_cost_rules.dart';
import 'package:aonw_core/game/domain/transport/transport_network_state.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

enum RoadConstructionBlocker {
  notWorker,
  workerBusy,
  noMovementPoints,
  queuedPathActive,
  missingTile,
  cityCenter,
  enemyTerritory,
  impassableTerrain,
  existingRoad,
}

final class RoadConstructionLegality {
  const RoadConstructionLegality.allowed() : blocker = null;
  const RoadConstructionLegality.blocked(this.blocker);

  final RoadConstructionBlocker? blocker;
  bool get allowed => blocker == null;
}

abstract final class RoadConstructionRules {
  static const int baseBuildTurns = 1;

  static int buildTurns(PaceBalance paceBalance) =>
      paceBalance.improvementTurns(baseBuildTurns).clamp(1, 1 << 30).toInt();

  static RoadConstructionLegality evaluate({
    required GameUnit unit,
    required Iterable<GameCity> cities,
    required TransportNetworkState network,
    required MapTileLookup mapTiles,
    bool requireReadyWorker = true,
  }) {
    if (!unit.isWorker) {
      return const RoadConstructionLegality.blocked(
        RoadConstructionBlocker.notWorker,
      );
    }
    if (requireReadyWorker && unit.isWorking) {
      return const RoadConstructionLegality.blocked(
        RoadConstructionBlocker.workerBusy,
      );
    }
    if (requireReadyWorker && unit.movementPoints <= 0) {
      return const RoadConstructionLegality.blocked(
        RoadConstructionBlocker.noMovementPoints,
      );
    }
    if (requireReadyWorker && unit.queuedPath != null) {
      return const RoadConstructionLegality.blocked(
        RoadConstructionBlocker.queuedPathActive,
      );
    }
    final tile = mapTiles.tileAt(unit.col, unit.row);
    if (tile == null) {
      return const RoadConstructionLegality.blocked(
        RoadConstructionBlocker.missingTile,
      );
    }
    final hex = HexCoord(col: unit.col, row: unit.row);
    if (network.byHex.containsKey(hex)) {
      return const RoadConstructionLegality.blocked(
        RoadConstructionBlocker.existingRoad,
      );
    }
    for (final city in cities) {
      if (city.center.col == unit.col && city.center.row == unit.row) {
        return const RoadConstructionLegality.blocked(
          RoadConstructionBlocker.cityCenter,
        );
      }
      if (city.ownerPlayerId != unit.ownerPlayerId &&
          city.controlsHex(CityHex(col: hex.col, row: hex.row))) {
        return const RoadConstructionLegality.blocked(
          RoadConstructionBlocker.enemyTerritory,
        );
      }
    }
    if (UnitMovementCostRules.costToEnterTile(tile, unitType: unit.type).blocked) {
      return const RoadConstructionLegality.blocked(
        RoadConstructionBlocker.impassableTerrain,
      );
    }
    return const RoadConstructionLegality.allowed();
  }
}
