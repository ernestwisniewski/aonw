import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/movement/merchant_trade_route_rules.dart';
import 'package:aonw_core/game/domain/movement/queued_move_path.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Persistence-neutral result of assigning or queueing merchant travel.
///
/// Inputs are immutable state-boundary snapshots. Rejections and accepted
/// semantic no-ops preserve [units] identity. A changed collection is owned by
/// the result and cannot be mutated.
final class MerchantRoutingCommandResult {
  const MerchantRoutingCommandResult._accepted({required this.units})
    : accepted = true,
      reason = null;

  const MerchantRoutingCommandResult._rejected({
    required this.units,
    required this.reason,
  }) : accepted = false;

  final bool accepted;
  final String? reason;
  final List<GameUnit> units;
}

/// Applies authoritative merchant-routing rules without a state container.
abstract final class MerchantRoutingCommandResolver {
  static MerchantRoutingCommandResult assignRoute({
    required List<GameUnit> units,
    required List<GameCity> cities,
    required AssignMerchantTradeRouteCommand command,
    required String actorPlayerId,
    required MapTraversalView mapData,
  }) {
    final controlled = _controlledMerchant(
      units,
      command.unitId,
      actorPlayerId,
    );
    if (controlled.reason case final reason?) return _reject(units, reason);
    final merchant = controlled.unit!;
    final unavailable = _assignRouteUnavailableReason(merchant);
    if (unavailable != null) return _reject(units, unavailable);

    final origin = MerchantTradeRouteRules.originCityFor(
      merchant: merchant,
      cities: cities,
    );
    if (origin == null) return _reject(units, 'merchant_not_in_city');

    final destination = cities.byId(command.destinationCityId);
    if (destination == null) {
      return _reject(units, 'destination_city_not_found');
    }
    if (destination.ownerPlayerId != merchant.ownerPlayerId) {
      return _reject(units, 'destination_city_not_controlled');
    }
    if (destination.id == origin.id) {
      return _reject(units, 'destination_city_is_origin');
    }

    final route = MerchantTradeRouteRules.planRoute(
      merchant: merchant,
      originCity: origin,
      destinationCity: destination,
      mapData: mapData,
      units: units,
      cities: cities,
    );
    if (route == null) return _reject(units, 'merchant_route_not_found');

    return _accept(
      units,
      merchant
          .copyWith(posture: UnitPosture.active)
          .copyWithQueuedPath(null)
          .copyWithMerchantTradeRoute(route),
    );
  }

  static MerchantRoutingCommandResult moveToCity({
    required List<GameUnit> units,
    required List<GameCity> cities,
    required MoveMerchantToCityCommand command,
    required String actorPlayerId,
    required MapTraversalView mapData,
  }) {
    final controlled = _controlledMerchant(
      units,
      command.unitId,
      actorPlayerId,
    );
    if (controlled.reason case final reason?) return _reject(units, reason);
    final merchant = controlled.unit!;
    final unavailable = _moveToCityUnavailableReason(merchant);
    if (unavailable != null) return _reject(units, unavailable);

    final destination = cities.byId(command.destinationCityId);
    if (destination == null) {
      return _reject(units, 'destination_city_not_found');
    }
    if (destination.ownerPlayerId != merchant.ownerPlayerId) {
      return _reject(units, 'destination_city_not_controlled');
    }
    if (destination.occupiesCenter(merchant.col, merchant.row)) {
      return _reject(units, 'destination_city_is_current');
    }

    final plan = MerchantTradeRouteRules.planMoveToCity(
      merchant: merchant,
      destinationCity: destination,
      mapData: mapData,
      units: units,
      cities: cities,
    );
    if (plan == null) return _reject(units, 'merchant_city_path_not_found');

    return _accept(
      units,
      merchant
          .copyWith(posture: UnitPosture.active)
          .copyWithQueuedPath(_queuedPathFor(plan))
          .copyWithMerchantTradeRoute(null),
    );
  }

  static ({GameUnit? unit, String? reason}) _controlledMerchant(
    List<GameUnit> units,
    String unitId,
    String actorPlayerId,
  ) {
    final unit = units.byId(unitId);
    if (unit == null) return (unit: null, reason: 'unit_not_found');
    if (unit.ownerPlayerId != actorPlayerId) {
      return (unit: null, reason: 'unit_not_controlled');
    }
    if (unit.type != GameUnitType.merchant) {
      return (unit: null, reason: 'unit_not_merchant');
    }
    return (unit: unit, reason: null);
  }

  static String? _assignRouteUnavailableReason(GameUnit merchant) {
    return merchant.isWorking || merchant.isFortified
        ? 'unit_unavailable'
        : null;
  }

  static String? _moveToCityUnavailableReason(GameUnit merchant) {
    return merchant.isWorking ||
            merchant.isFortified ||
            merchant.merchantTradeRoute != null
        ? 'unit_unavailable'
        : null;
  }

  static QueuedMovePath _queuedPathFor(UnitMovementPlan plan) {
    return QueuedMovePath(
      targetCol: plan.targetCol,
      targetRow: plan.targetRow,
      steps: plan.steps,
    );
  }

  static MerchantRoutingCommandResult _accept(
    List<GameUnit> units,
    GameUnit updated,
  ) {
    final current = units.byId(updated.id);
    if (current == updated) {
      return MerchantRoutingCommandResult._accepted(units: units);
    }
    return MerchantRoutingCommandResult._accepted(
      units: List<GameUnit>.unmodifiable([
        for (final unit in units)
          if (unit.id == updated.id) updated else unit,
      ]),
    );
  }

  static MerchantRoutingCommandResult _reject(
    List<GameUnit> units,
    String reason,
  ) {
    return MerchantRoutingCommandResult._rejected(units: units, reason: reason);
  }
}
