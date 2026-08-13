import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/fog/fog_visibility_query.dart';
import 'package:aonw_core/game/domain/hex/hex_coordinate.dart';
import 'package:aonw_core/game/domain/movement/movement_cost.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_cost_rules.dart';
import 'package:aonw_core/game/domain/transport/transport_network_index.dart';
import 'package:aonw_core/game/domain/transport/transport_network_state.dart';
import 'package:aonw_core/game/domain/transport/transport_network_visibility_rules.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/unit_movement_domain.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

abstract interface class UnitTraversalCostResolver {
  MovementCost costForStep({
    required GameUnit unit,
    required MapTileView from,
    required MapTileView to,
  });
}

final class TerrainTraversalCostResolver implements UnitTraversalCostResolver {
  const TerrainTraversalCostResolver();

  @override
  MovementCost costForStep({
    required GameUnit unit,
    required MapTileView from,
    required MapTileView to,
  }) => UnitMovementCostRules.costToEnterTile(to, unitType: unit.type);
}

/// Applies world infrastructure after the base terrain passability rule.
///
/// A road may reduce a passable land tile's entry cost, but never turns a
/// blocked tile into a passable one and never affects naval or air units.
final class InfrastructureAwareTraversalCostResolver
    implements UnitTraversalCostResolver {
  factory InfrastructureAwareTraversalCostResolver.forKnownState({
    required TransportNetworkState network,
    required Iterable<GameCity> cities,
    required String actorPlayerId,
    required FogVisibilityQuery visibility,
    UnitTraversalCostResolver terrain = const TerrainTraversalCostResolver(),
  }) {
    final cityList = cities.toList(growable: false);
    final ownCityIds = [
      for (final city in cityList)
        if (city.ownerPlayerId == actorPlayerId) city.id,
    ];
    return InfrastructureAwareTraversalCostResolver(
      TransportNetworkVisibilityRules.knownFor(
        network: network,
        playerId: actorPlayerId,
        ownCityIds: ownCityIds,
        visibility: visibility,
      ),
      cityCenters: [
        for (final city in cityList)
          if (city.ownerPlayerId == actorPlayerId ||
              visibility.canRememberStaticAt(city.center.col, city.center.row))
            city.center.toCoordinate(),
      ],
      terrain: terrain,
    );
  }

  InfrastructureAwareTraversalCostResolver(
    TransportNetworkState network, {
    Iterable<HexCoordinate> cityCenters = const [],
    this.terrain = const TerrainTraversalCostResolver(),
  }) : _network = TransportNetworkIndex(network),
       _cityCenters = Set.unmodifiable(cityCenters);

  final UnitTraversalCostResolver terrain;
  final TransportNetworkIndex _network;
  final Set<HexCoordinate> _cityCenters;

  @override
  MovementCost costForStep({
    required GameUnit unit,
    required MapTileView from,
    required MapTileView to,
  }) {
    final base = terrain.costForStep(unit: unit, from: from, to: to);
    if (base.blocked || unit.type.movementDomain != UnitMovementDomain.land) {
      return base;
    }
    return _isOperationalRoadEdge(from, to)
        ? const MovementCost.passable(1)
        : base;
  }

  bool _isOperationalRoadEdge(MapTileView from, MapTileView to) {
    if (!HexGridTopology.areNeighbors(
      col: from.col,
      row: from.row,
      targetCol: to.col,
      targetRow: to.row,
    )) {
      return false;
    }
    final fromRoad = _network.hasOperationalRoadAt(from.col, from.row);
    final toRoad = _network.hasOperationalRoadAt(to.col, to.row);
    if (fromRoad && toRoad) return true;
    final fromCity = _cityCenters.contains(HexCoordinate.fromTile(from));
    final toCity = _cityCenters.contains(HexCoordinate.fromTile(to));
    return (fromCity && toRoad) || (fromRoad && toCity);
  }
}
