part of 'merchant_trade_route_rules.dart';

typedef _MerchantRouteStart = ({MerchantTradeRoute route, int index});

_MerchantRouteStart? _routeStartFor({
  required GameUnit unit,
  required MerchantTradeRoute savedRoute,
  required List<GameUnit> units,
  required List<GameCity> cities,
  required MapTraversalView mapData,
  required TransportNetworkState transportNetwork,
}) {
  var route = savedRoute;
  var index = _routeIndexAtUnit(route, unit);
  if (index < 0 ||
      route.transportNetworkFingerprint !=
          transportNetwork.routingFingerprint) {
    route =
        _replanRoute(
          unit: unit,
          route: route,
          units: units,
          cities: cities,
          mapData: mapData,
          transportNetwork: transportNetwork,
        ) ??
        savedRoute;
    index = _routeIndexAtUnit(route, unit);
  }
  return index < 0 ? null : (route: route, index: index);
}

int _routeIndexAtUnit(MerchantTradeRoute route, GameUnit unit) => route.steps
    .indexWhere((step) => step.col == unit.col && step.row == unit.row);

MerchantTradeRoute? _replanRoute({
  required GameUnit unit,
  required MerchantTradeRoute route,
  required List<GameUnit> units,
  required List<GameCity> cities,
  required MapTraversalView mapData,
  required TransportNetworkState transportNetwork,
}) => MerchantTradeRoutePlanner.replan(
  unit: unit,
  route: route,
  units: units,
  cities: cities,
  mapData: mapData,
  transportNetwork: transportNetwork,
  canEnterOccupiedTile:
      ({
        required movingUnit,
        required blockingUnit,
        required col,
        required row,
      }) => MerchantTradeRouteRules.canShareOccupiedCityTile(
        movingUnit: movingUnit,
        col: col,
        row: row,
        cities: cities,
      ),
);
