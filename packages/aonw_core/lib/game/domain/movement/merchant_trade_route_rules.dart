import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/movement/merchant_trade_route_planner.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_balance.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_feasibility.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/movement/unit_traversal_cost_resolver.dart';
import 'package:aonw_core/game/domain/transport/transport_network_state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

part 'merchant_trade_route_advance.dart';

class MerchantTradeRouteAdvanceResult {
  const MerchantTradeRouteAdvanceResult({
    required this.unit,
    this.movedSteps = const [],
    this.routeInvalidated = false,
  });

  final GameUnit unit;
  final List<UnitMovementStep> movedSteps;
  final bool routeInvalidated;

  bool get moved => movedSteps.isNotEmpty;
}

enum _MerchantRouteStepDisposition { ready, blocked, invalid }

typedef _MerchantRouteStepDecision = ({
  _MerchantRouteStepDisposition disposition,
  int enterCost,
});

typedef _MerchantRouteProgress = ({
  bool invalidated,
  int index,
  int remainingMovement,
  List<UnitMovementStep> movedSteps,
});

abstract final class MerchantTradeRouteRules {
  static GameCity? originCityFor({
    required GameUnit merchant,
    required Iterable<GameCity> cities,
  }) {
    if (merchant.type != GameUnitType.merchant) return null;
    for (final city in cities) {
      if (city.ownerPlayerId == merchant.ownerPlayerId &&
          city.occupiesCenter(merchant.col, merchant.row)) {
        return city;
      }
    }
    return null;
  }

  static Iterable<GameCity> destinationCandidatesFor({
    required GameUnit merchant,
    required Iterable<GameCity> cities,
  }) sync* {
    final origin = originCityFor(merchant: merchant, cities: cities);
    if (origin == null) return;
    for (final city in cities) {
      if (city.ownerPlayerId != merchant.ownerPlayerId) continue;
      if (city.id == origin.id) continue;
      yield city;
    }
  }

  static Iterable<GameCity> moveToCityCandidatesFor({
    required GameUnit merchant,
    required Iterable<GameCity> cities,
  }) sync* {
    if (merchant.type != GameUnitType.merchant) return;
    final currentCity = originCityFor(merchant: merchant, cities: cities);
    for (final city in cities) {
      if (city.ownerPlayerId != merchant.ownerPlayerId) continue;
      if (city.id == currentCity?.id) continue;
      yield city;
    }
  }

  static MerchantTradeRoute? planRoute({
    required GameUnit merchant,
    required GameCity originCity,
    required GameCity destinationCity,
    required MapTraversalView mapData,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
    TransportNetworkState transportNetwork = TransportNetworkState.empty,
  }) {
    if (merchant.type != GameUnitType.merchant) return null;
    if (originCity.ownerPlayerId != merchant.ownerPlayerId ||
        destinationCity.ownerPlayerId != merchant.ownerPlayerId ||
        originCity.id == destinationCity.id ||
        !originCity.occupiesCenter(merchant.col, merchant.row)) {
      return null;
    }

    final targetTile = mapData.tileAt(
      destinationCity.center.col,
      destinationCity.center.row,
    );
    if (targetTile == null) return null;

    final plan = UnitMovementPathfinder(
      mapData: mapData,
      units: units,
      costResolver: MerchantTradeRoutePlanner.traversalResolver(
        transportNetwork,
        cities,
      ),
      canEnterOccupiedTile:
          ({
            required movingUnit,
            required blockingUnit,
            required col,
            required row,
          }) => canShareOccupiedCityTile(
            movingUnit: movingUnit,
            col: col,
            row: row,
            cities: cities,
          ),
    ).plan(unit: merchant, targetTile: targetTile);
    if (plan == null ||
        !UnitMovementFeasibility.canEventuallyTraverse(
          unit: merchant,
          plan: plan,
        )) {
      return null;
    }

    return MerchantTradeRoute(
      originCityId: originCity.id,
      destinationCityId: destinationCity.id,
      steps: plan.steps,
      transportNetworkFingerprint: transportNetwork.routingFingerprint,
    );
  }

  static UnitMovementPlan? planMoveToCity({
    required GameUnit merchant,
    required GameCity destinationCity,
    required MapTraversalView mapData,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
    TransportNetworkState transportNetwork = TransportNetworkState.empty,
  }) {
    if (merchant.type != GameUnitType.merchant ||
        destinationCity.ownerPlayerId != merchant.ownerPlayerId ||
        destinationCity.occupiesCenter(merchant.col, merchant.row)) {
      return null;
    }

    final targetTile = mapData.tileAt(
      destinationCity.center.col,
      destinationCity.center.row,
    );
    if (targetTile == null) return null;

    final plan = UnitMovementPathfinder(
      mapData: mapData,
      units: units,
      costResolver: MerchantTradeRoutePlanner.traversalResolver(
        transportNetwork,
        cities,
      ),
      canEnterOccupiedTile:
          ({
            required movingUnit,
            required blockingUnit,
            required col,
            required row,
          }) => canShareOccupiedCityTile(
            movingUnit: movingUnit,
            col: col,
            row: row,
            cities: cities,
          ),
    ).plan(unit: merchant, targetTile: targetTile);
    if (plan == null ||
        !UnitMovementFeasibility.canEventuallyTraverse(
          unit: merchant,
          plan: plan,
        )) {
      return null;
    }
    return plan;
  }

  static MerchantTradeRouteAdvanceResult advanceUnit({
    required GameUnit unit,
    required List<GameUnit> units,
    required List<GameCity> cities,
    required MapTraversalView mapData,
    TransportNetworkState transportNetwork = TransportNetworkState.empty,
  }) {
    final savedRoute = unit.merchantTradeRoute;
    if (savedRoute == null) {
      return MerchantTradeRouteAdvanceResult(unit: unit);
    }
    if (!_canAdvanceRoute(unit: unit, route: savedRoute, cities: cities)) {
      return _invalidatedRoute(unit);
    }

    final routeStart = _routeStartFor(
      unit: unit,
      savedRoute: savedRoute,
      units: units,
      cities: cities,
      mapData: mapData,
      transportNetwork: transportNetwork,
    );
    if (routeStart == null) return _invalidatedRoute(unit);
    final route = routeStart.route;
    final traversalResolver = MerchantTradeRoutePlanner.traversalResolver(
      transportNetwork,
      cities,
    );

    final progress = _advanceRouteSteps(
      unit: unit,
      route: route,
      startIndex: routeStart.index,
      units: units,
      cities: cities,
      mapData: mapData,
      traversalResolver: traversalResolver,
    );
    if (progress.invalidated) return _invalidatedRoute(unit);
    if (progress.movedSteps.isEmpty) {
      return MerchantTradeRouteAdvanceResult(
        unit: route == savedRoute
            ? unit
            : unit.copyWithMerchantTradeRoute(route),
      );
    }
    return _completedRouteAdvance(
      unit: unit,
      route: route,
      progress: progress,
      cities: cities,
      mapData: mapData,
      traversalResolver: traversalResolver,
      transportNetwork: transportNetwork,
    );
  }

  static bool canShareOccupiedCityTile({
    required GameUnit movingUnit,
    required int col,
    required int row,
    required Iterable<GameCity> cities,
  }) {
    if (movingUnit.type != GameUnitType.merchant) return false;
    final city = cities.cityAt(col, row);
    return city != null && city.ownerPlayerId == movingUnit.ownerPlayerId;
  }

  static MerchantTradeRoute? _reversedRoute(
    MerchantTradeRoute route, {
    required MapTileLookup mapData,
    required GameUnit unit,
    required List<GameCity> cities,
    required UnitTraversalCostResolver traversalResolver,
    required TransportNetworkState transportNetwork,
  }) {
    final reversed = route.steps.reversed.toList(growable: false);
    final rebuilt = <UnitMovementStep>[];
    var cumulativeCost = 0;
    for (var i = 0; i < reversed.length; i++) {
      final step = reversed[i];
      var enterCost = 0;
      if (i > 0) {
        final previous = reversed[i - 1];
        final from = mapData.tileAt(previous.col, previous.row);
        final to = mapData.tileAt(step.col, step.row);
        if (from == null || to == null) return null;
        final cost = traversalResolver.costForStep(
          unit: unit,
          from: from,
          to: to,
        );
        if (cost.blocked) return null;
        enterCost = cost.value;
        cumulativeCost += enterCost;
      }
      rebuilt.add(
        UnitMovementStep(
          col: step.col,
          row: step.row,
          enterCost: enterCost,
          cumulativeCost: cumulativeCost,
        ),
      );
    }
    return MerchantTradeRoute(
      originCityId: route.destinationCityId,
      destinationCityId: route.originCityId,
      steps: rebuilt,
      transportNetworkFingerprint: transportNetwork.routingFingerprint,
    );
  }

  static GameUnit? _blockingUnitAt(
    Iterable<GameUnit> units,
    String movingUnitId,
    int col,
    int row,
  ) {
    for (final unit in units) {
      if (unit.id == movingUnitId) continue;
      if (unit.occupies(col, row)) return unit;
    }
    return null;
  }
}

bool _canAdvanceRoute({
  required GameUnit unit,
  required MerchantTradeRoute route,
  required List<GameCity> cities,
}) {
  return unit.type == GameUnitType.merchant &&
      !unit.isWorking &&
      !unit.isFortified &&
      route.steps.length >= 2 &&
      cities.byId(route.originCityId) != null &&
      cities.byId(route.destinationCityId) != null;
}

_MerchantRouteProgress _advanceRouteSteps({
  required GameUnit unit,
  required MerchantTradeRoute route,
  required int startIndex,
  required List<GameUnit> units,
  required List<GameCity> cities,
  required MapTileLookup mapData,
  required UnitTraversalCostResolver traversalResolver,
}) {
  var index = startIndex;
  var remainingMovement = unit.movementUnits;
  final movedSteps = <UnitMovementStep>[];

  while (index < route.steps.length - 1) {
    final next = route.steps[index + 1];
    final decision = _routeStepDecision(
      unit: unit,
      current: route.steps[index],
      next: next,
      units: units,
      cities: cities,
      mapData: mapData,
      traversalResolver: traversalResolver,
    );
    if (decision.disposition == _MerchantRouteStepDisposition.invalid) {
      return (
        invalidated: true,
        index: startIndex,
        remainingMovement: unit.movementUnits,
        movedSteps: const [],
      );
    }
    if (decision.disposition == _MerchantRouteStepDisposition.blocked ||
        remainingMovement <= 0) {
      break;
    }

    remainingMovement = _spendMovement(remainingMovement, decision.enterCost);
    index++;
    movedSteps.add(next);
    if (remainingMovement == 0) break;
  }

  return (
    invalidated: false,
    index: index,
    remainingMovement: remainingMovement,
    movedSteps: movedSteps,
  );
}

_MerchantRouteStepDecision _routeStepDecision({
  required GameUnit unit,
  required UnitMovementStep current,
  required UnitMovementStep next,
  required List<GameUnit> units,
  required List<GameCity> cities,
  required MapTileLookup mapData,
  required UnitTraversalCostResolver traversalResolver,
}) {
  final from = mapData.tileAt(current.col, current.row);
  final to = mapData.tileAt(next.col, next.row);
  if (from == null || to == null) {
    return (disposition: _MerchantRouteStepDisposition.invalid, enterCost: 0);
  }
  final cost = traversalResolver.costForStep(unit: unit, from: from, to: to);
  if (cost.blocked) {
    return (disposition: _MerchantRouteStepDisposition.invalid, enterCost: 0);
  }
  final blocker = MerchantTradeRouteRules._blockingUnitAt(
    units,
    unit.id,
    next.col,
    next.row,
  );
  if (blocker != null &&
      !MerchantTradeRouteRules.canShareOccupiedCityTile(
        movingUnit: unit,
        col: next.col,
        row: next.row,
        cities: cities,
      )) {
    return (disposition: _MerchantRouteStepDisposition.blocked, enterCost: 0);
  }
  final enterCost = cost.value;
  final maxMovement = UnitMovementBalance.maxMovementUnitsFor(
    type: unit.type,
    carriedArtifactId: unit.carriedArtifactId,
  );
  final disposition = enterCost > maxMovement && !unit.isCarryingArtifact
      ? _MerchantRouteStepDisposition.invalid
      : _MerchantRouteStepDisposition.ready;
  return (disposition: disposition, enterCost: enterCost);
}

int _spendMovement(int remainingMovement, int enterCost) {
  return enterCost >= remainingMovement ? 0 : remainingMovement - enterCost;
}

MerchantTradeRouteAdvanceResult _completedRouteAdvance({
  required GameUnit unit,
  required MerchantTradeRoute route,
  required _MerchantRouteProgress progress,
  required List<GameCity> cities,
  required MapTileLookup mapData,
  required UnitTraversalCostResolver traversalResolver,
  required TransportNetworkState transportNetwork,
}) {
  final destination = route.steps[progress.index];
  var updated = unit.copyWith(
    col: destination.col,
    row: destination.row,
    movementUnits: progress.remainingMovement,
  );

  if (progress.index == route.steps.length - 1) {
    updated = updated.copyWithMerchantTradeRoute(
      MerchantTradeRouteRules._reversedRoute(
        route,
        mapData: mapData,
        unit: unit,
        cities: cities,
        traversalResolver: traversalResolver,
        transportNetwork: transportNetwork,
      ),
    );
  } else {
    updated = updated.copyWithMerchantTradeRoute(route);
  }

  return MerchantTradeRouteAdvanceResult(
    unit: updated,
    movedSteps: List.unmodifiable(progress.movedSteps),
  );
}

MerchantTradeRouteAdvanceResult _invalidatedRoute(GameUnit unit) {
  return MerchantTradeRouteAdvanceResult(
    unit: unit.copyWithMerchantTradeRoute(null),
    routeInvalidated: true,
  );
}
