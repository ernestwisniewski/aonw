import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/movement/merchant_trade_route_rules.dart';
import 'package:aonw_core/game/domain/movement/queued_move_path.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class PersistentMerchantTradeRouteResult {
  const PersistentMerchantTradeRouteResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final String? reason;
}

class PersistentMerchantTradeRouteResolver {
  const PersistentMerchantTradeRouteResolver();

  PersistentMerchantTradeRouteResult assignRoute({
    required PersistentGameState state,
    required AssignMerchantTradeRouteCommand command,
    required String actorPlayerId,
    required MapData mapData,
  }) {
    final unit = _unitById(state.units, command.unitId);
    if (unit == null) return _reject(state, 'unit_not_found');
    if (unit.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'unit_not_controlled');
    }
    if (unit.type != GameUnitType.merchant) {
      return _reject(state, 'unit_not_merchant');
    }
    if (unit.isWorking || unit.isFortified) {
      return _reject(state, 'unit_unavailable');
    }

    final origin = MerchantTradeRouteRules.originCityFor(
      merchant: unit,
      cities: state.cities,
    );
    if (origin == null) return _reject(state, 'merchant_not_in_city');

    final destination = _cityById(state.cities, command.destinationCityId);
    if (destination == null) {
      return _reject(state, 'destination_city_not_found');
    }
    if (destination.ownerPlayerId != unit.ownerPlayerId) {
      return _reject(state, 'destination_city_not_controlled');
    }
    if (destination.id == origin.id) {
      return _reject(state, 'destination_city_is_origin');
    }

    final route = MerchantTradeRouteRules.planRoute(
      merchant: unit,
      originCity: origin,
      destinationCity: destination,
      mapData: mapData,
      units: state.units,
      cities: state.cities,
    );
    if (route == null) return _reject(state, 'merchant_route_not_found');

    final updated = unit
        .copyWith(posture: UnitPosture.active)
        .copyWithQueuedPath(null)
        .copyWithMerchantTradeRoute(route);
    return PersistentMerchantTradeRouteResult(
      accepted: true,
      state: state.copyWith(units: _replaceUnit(state.units, updated)),
    );
  }

  PersistentMerchantTradeRouteResult moveToCity({
    required PersistentGameState state,
    required MoveMerchantToCityCommand command,
    required String actorPlayerId,
    required MapData mapData,
  }) {
    final unit = _unitById(state.units, command.unitId);
    if (unit == null) return _reject(state, 'unit_not_found');
    if (unit.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'unit_not_controlled');
    }
    if (unit.type != GameUnitType.merchant) {
      return _reject(state, 'unit_not_merchant');
    }
    if (unit.isWorking || unit.isFortified || unit.merchantTradeRoute != null) {
      return _reject(state, 'unit_unavailable');
    }

    final destination = _cityById(state.cities, command.destinationCityId);
    if (destination == null) {
      return _reject(state, 'destination_city_not_found');
    }
    if (destination.ownerPlayerId != unit.ownerPlayerId) {
      return _reject(state, 'destination_city_not_controlled');
    }
    if (destination.occupiesCenter(unit.col, unit.row)) {
      return _reject(state, 'destination_city_is_current');
    }

    final plan = MerchantTradeRouteRules.planMoveToCity(
      merchant: unit,
      destinationCity: destination,
      mapData: mapData,
      units: state.units,
      cities: state.cities,
    );
    if (plan == null) return _reject(state, 'merchant_city_path_not_found');

    final updated = unit
        .copyWith(posture: UnitPosture.active)
        .copyWithQueuedPath(_queuedPathFor(plan))
        .copyWithMerchantTradeRoute(null);
    return PersistentMerchantTradeRouteResult(
      accepted: true,
      state: state.copyWith(units: _replaceUnit(state.units, updated)),
    );
  }

  static QueuedMovePath _queuedPathFor(UnitMovementPlan plan) {
    return QueuedMovePath(
      targetCol: plan.targetCol,
      targetRow: plan.targetRow,
      steps: plan.steps,
    );
  }

  PersistentMerchantTradeRouteResult _reject(
    PersistentGameState state,
    String reason,
  ) {
    return PersistentMerchantTradeRouteResult(
      accepted: false,
      state: state,
      reason: reason,
    );
  }

  static GameUnit? _unitById(List<GameUnit> units, String unitId) {
    for (final unit in units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }

  static GameCity? _cityById(List<GameCity> cities, String cityId) {
    for (final city in cities) {
      if (city.id == cityId) return city;
    }
    return null;
  }

  static List<GameUnit> _replaceUnit(List<GameUnit> units, GameUnit updated) {
    return [
      for (final unit in units)
        if (unit.id == updated.id) updated else unit,
    ];
  }
}
