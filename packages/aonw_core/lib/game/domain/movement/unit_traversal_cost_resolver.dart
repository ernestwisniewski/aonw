import 'package:aonw_core/game/domain/movement/movement_cost.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_cost_rules.dart';
import 'package:aonw_core/game/domain/transport/transport_network_index.dart';
import 'package:aonw_core/game/domain/transport/transport_network_state.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/unit_movement_domain.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

abstract interface class UnitTraversalCostResolver {
  MovementCost costToEnter({
    required GameUnit unit,
    required MapTileView tile,
  });
}
final class TerrainTraversalCostResolver implements UnitTraversalCostResolver {
  const TerrainTraversalCostResolver();

  @override
  MovementCost costToEnter({
    required GameUnit unit,
    required MapTileView tile,
  }) => UnitMovementCostRules.costToEnterTile(tile, unitType: unit.type);
}

/// Applies world infrastructure after the base terrain passability rule.
///
/// A road may reduce a passable land tile's entry cost, but never turns a
/// blocked tile into a passable one and never affects naval or air units.
final class InfrastructureAwareTraversalCostResolver
    implements UnitTraversalCostResolver {
  InfrastructureAwareTraversalCostResolver(
    TransportNetworkState network, {
    this.terrain = const TerrainTraversalCostResolver(),
  }) : _network = TransportNetworkIndex(network);

  final UnitTraversalCostResolver terrain;
  final TransportNetworkIndex _network;

  @override
  MovementCost costToEnter({
    required GameUnit unit,
    required MapTileView tile,
  }) {
    final base = terrain.costToEnter(unit: unit, tile: tile);
    if (base.blocked || unit.type.movementDomain != UnitMovementDomain.land) {
      return base;
    }
    return _network.hasOperationalRoadAt(tile.col, tile.row)
        ? const MovementCost.passable(1)
        : base;
  }
}
