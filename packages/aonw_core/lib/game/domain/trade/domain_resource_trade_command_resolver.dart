import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_command_resolver.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainResourceTradeCommandResult {
  const DomainResourceTradeCommandResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final String? reason;
}

/// Canonical-state adapter for the persistence-neutral resource-trade resolver.
final class DomainResourceTradeCommandResolver {
  const DomainResourceTradeCommandResolver();

  DomainResourceTradeCommandResult openGoldForResourceTrade({
    required DomainState state,
    required OpenResourceTradeCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    return _apply(
      state,
      ResourceTradeCommandResolver.openGoldForResourceTrade(
        playerGold: state.playerGold,
        cities: state.cities,
        research: state.research,
        diplomacy: state.diplomacy,
        resourceTradeAgreements: state.resourceTradeAgreements,
        command: command,
        actorPlayerId: actorPlayerId,
        mapTiles: mapTiles,
      ),
    );
  }

  DomainResourceTradeCommandResult openResourceForResourceTrade({
    required DomainState state,
    required OpenResourceExchangeCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    return _apply(
      state,
      ResourceTradeCommandResolver.openResourceForResourceTrade(
        cities: state.cities,
        research: state.research,
        diplomacy: state.diplomacy,
        resourceTradeAgreements: state.resourceTradeAgreements,
        command: command,
        actorPlayerId: actorPlayerId,
        mapTiles: mapTiles,
      ),
    );
  }

  static DomainResourceTradeCommandResult _apply(
    DomainState state,
    ResourceTradeCommandResult result,
  ) {
    if (!result.accepted) {
      return DomainResourceTradeCommandResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    return DomainResourceTradeCommandResult(
      accepted: true,
      state:
          identical(
            result.resourceTradeAgreements,
            state.resourceTradeAgreements,
          )
          ? state
          : state.copyWith(
              resourceTradeAgreements: result.resourceTradeAgreements,
            ),
    );
  }
}
