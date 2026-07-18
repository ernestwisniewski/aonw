import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/movement/merchant_routing_command_resolver.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainMerchantRoutingCommandResult {
  const DomainMerchantRoutingCommandResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final String? reason;
}

/// Canonical-state adapter for the persistence-neutral merchant resolver.
final class DomainMerchantRoutingCommandResolver {
  const DomainMerchantRoutingCommandResolver();

  DomainMerchantRoutingCommandResult assignRoute({
    required DomainState state,
    required AssignMerchantTradeRouteCommand command,
    required String actorPlayerId,
    required MapTraversalView mapData,
  }) {
    return _apply(
      state,
      MerchantRoutingCommandResolver.assignRoute(
        units: state.units,
        cities: state.cities,
        command: command,
        actorPlayerId: actorPlayerId,
        mapData: mapData,
      ),
    );
  }

  DomainMerchantRoutingCommandResult moveToCity({
    required DomainState state,
    required MoveMerchantToCityCommand command,
    required String actorPlayerId,
    required MapTraversalView mapData,
  }) {
    return _apply(
      state,
      MerchantRoutingCommandResolver.moveToCity(
        units: state.units,
        cities: state.cities,
        command: command,
        actorPlayerId: actorPlayerId,
        mapData: mapData,
      ),
    );
  }

  static DomainMerchantRoutingCommandResult _apply(
    DomainState state,
    MerchantRoutingCommandResult result,
  ) {
    if (!result.accepted) {
      return DomainMerchantRoutingCommandResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    return DomainMerchantRoutingCommandResult(
      accepted: true,
      state: identical(result.units, state.units)
          ? state
          : state.copyWith(units: result.units),
    );
  }
}
