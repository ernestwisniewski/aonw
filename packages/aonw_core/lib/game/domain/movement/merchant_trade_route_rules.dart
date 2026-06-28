import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_cost_rules.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

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
    required MapData mapData,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
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
    if (plan == null) return null;

    return MerchantTradeRoute(
      originCityId: originCity.id,
      destinationCityId: destinationCity.id,
      steps: plan.steps,
    );
  }

  static UnitMovementPlan? planMoveToCity({
    required GameUnit merchant,
    required GameCity destinationCity,
    required MapData mapData,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
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

    return UnitMovementPathfinder(
      mapData: mapData,
      units: units,
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
  }

  static MerchantTradeRouteAdvanceResult advanceUnit({
    required GameUnit unit,
    required List<GameUnit> units,
    required List<GameCity> cities,
    required MapData mapData,
  }) {
    final route = unit.merchantTradeRoute;
    if (route == null) {
      return MerchantTradeRouteAdvanceResult(unit: unit);
    }
    if (unit.type != GameUnitType.merchant ||
        unit.isWorking ||
        unit.isFortified ||
        route.steps.length < 2 ||
        cities.byId(route.originCityId) == null ||
        cities.byId(route.destinationCityId) == null) {
      return MerchantTradeRouteAdvanceResult(
        unit: unit.copyWithMerchantTradeRoute(null),
        routeInvalidated: true,
      );
    }

    final startIndex = route.steps.indexWhere(
      (step) => step.col == unit.col && step.row == unit.row,
    );
    if (startIndex < 0) {
      return MerchantTradeRouteAdvanceResult(
        unit: unit.copyWithMerchantTradeRoute(null),
        routeInvalidated: true,
      );
    }

    var index = startIndex;
    var remainingMovement = unit.movementPoints;
    final movedSteps = <UnitMovementStep>[];

    while (index < route.steps.length - 1) {
      final next = route.steps[index + 1];
      final tile = mapData.tileAt(next.col, next.row);
      if (tile == null) {
        return MerchantTradeRouteAdvanceResult(
          unit: unit.copyWithMerchantTradeRoute(null),
          routeInvalidated: true,
        );
      }
      final cost = UnitMovementCostRules.costToEnterTile(
        tile,
        unitType: unit.type,
      );
      if (cost.blocked) {
        return MerchantTradeRouteAdvanceResult(
          unit: unit.copyWithMerchantTradeRoute(null),
          routeInvalidated: true,
        );
      }

      final blocker = _blockingUnitAt(units, unit.id, next.col, next.row);
      if (blocker != null &&
          !canShareOccupiedCityTile(
            movingUnit: unit,
            col: next.col,
            row: next.row,
            cities: cities,
          )) {
        break;
      }

      final enterCost = next.enterCost > 0 ? next.enterCost : cost.value;
      if (enterCost > remainingMovement) break;

      remainingMovement -= enterCost;
      index++;
      movedSteps.add(next);
    }

    if (movedSteps.isEmpty) {
      return MerchantTradeRouteAdvanceResult(unit: unit);
    }

    final destination = route.steps[index];
    var updated = unit.copyWith(
      col: destination.col,
      row: destination.row,
      movementPoints: remainingMovement,
    );

    if (index == route.steps.length - 1) {
      updated = updated.copyWithMerchantTradeRoute(
        _reversedRoute(route, mapData: mapData, unitType: unit.type),
      );
    }

    return MerchantTradeRouteAdvanceResult(
      unit: updated,
      movedSteps: List.unmodifiable(movedSteps),
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
    required MapData mapData,
    required GameUnitType unitType,
  }) {
    final reversed = route.steps.reversed.toList(growable: false);
    final rebuilt = <UnitMovementStep>[];
    var cumulativeCost = 0;
    for (var i = 0; i < reversed.length; i++) {
      final step = reversed[i];
      var enterCost = 0;
      if (i > 0) {
        final tile = mapData.tileAt(step.col, step.row);
        if (tile == null) return null;
        final cost = UnitMovementCostRules.costToEnterTile(
          tile,
          unitType: unitType,
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
