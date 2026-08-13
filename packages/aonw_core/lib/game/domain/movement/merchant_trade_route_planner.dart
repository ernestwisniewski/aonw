import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_feasibility.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
import 'package:aonw_core/game/domain/movement/unit_traversal_cost_resolver.dart';
import 'package:aonw_core/game/domain/transport/transport_network_state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

typedef MerchantOccupiedTilePolicy =
    bool Function({
      required GameUnit movingUnit,
      required GameUnit blockingUnit,
      required int col,
      required int row,
    });

/// Rebuilds the active merchant route against the current infrastructure.
abstract final class MerchantTradeRoutePlanner {
  static MerchantTradeRoute? replan({
    required GameUnit unit,
    required MerchantTradeRoute route,
    required List<GameUnit> units,
    required List<GameCity> cities,
    required MapTraversalView mapData,
    required TransportNetworkState transportNetwork,
    required MerchantOccupiedTilePolicy canEnterOccupiedTile,
  }) {
    final destination = cities.byId(route.destinationCityId);
    if (destination == null) return null;
    final target = mapData.tileAt(
      destination.center.col,
      destination.center.row,
    );
    if (target == null) return null;
    final plan = UnitMovementPathfinder(
      mapData: mapData,
      units: units,
      costResolver: traversalResolver(transportNetwork, cities),
      canEnterOccupiedTile: canEnterOccupiedTile,
    ).plan(unit: unit, targetTile: target);
    if (plan == null ||
        !UnitMovementFeasibility.canEventuallyTraverse(
          unit: unit,
          plan: plan,
        )) {
      return null;
    }
    return MerchantTradeRoute(
      originCityId: route.originCityId,
      destinationCityId: route.destinationCityId,
      steps: plan.steps,
    );
  }

  static InfrastructureAwareTraversalCostResolver traversalResolver(
    TransportNetworkState network,
    Iterable<GameCity> cities,
  ) => InfrastructureAwareTraversalCostResolver(
    network,
    cityCenters: [for (final city in cities) city.center.toCoordinate()],
  );
}
