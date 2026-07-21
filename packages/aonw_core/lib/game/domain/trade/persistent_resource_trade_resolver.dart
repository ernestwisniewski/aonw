import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_command_resolver.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

final class PersistentResourceTradeResult {
  const PersistentResourceTradeResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final String? reason;
}

/// Persistence adapter for the state-neutral resource-trade resolver.
final class PersistentResourceTradeResolver {
  const PersistentResourceTradeResolver();

  PersistentResourceTradeResult openGoldForResourceTrade({
    required PersistentGameState state,
    required String importerPlayerId,
    required String exporterPlayerId,
    required ResourceType resource,
    required int goldPerTurn,
    required int durationTurns,
    required MapTileLookup mapTiles,
    String? agreementId,
  }) {
    return _apply(
      state,
      ResourceTradeCommandResolver.openGoldForResourceTrade(
        playerGold: state.playerGold,
        cities: state.cities,
        research: state.research,
        diplomacy: state.runtimeState.diplomacy,
        resourceTradeAgreements: state.runtimeState.resourceTradeAgreements,
        command: OpenResourceTradeCommand(
          playerId: importerPlayerId,
          targetPlayerId: exporterPlayerId,
          resource: resource,
          goldPerTurn: goldPerTurn,
          durationTurns: durationTurns,
          agreementId: agreementId,
        ),
        actorPlayerId: importerPlayerId,
        mapTiles: mapTiles,
      ),
    );
  }

  PersistentResourceTradeResult openResourceForResourceTrade({
    required PersistentGameState state,
    required String playerId,
    required String targetPlayerId,
    required ResourceType offeredResource,
    required ResourceType requestedResource,
    required int durationTurns,
    required MapTileLookup mapTiles,
    String? agreementId,
  }) {
    return _apply(
      state,
      ResourceTradeCommandResolver.openResourceForResourceTrade(
        cities: state.cities,
        research: state.research,
        diplomacy: state.runtimeState.diplomacy,
        resourceTradeAgreements: state.runtimeState.resourceTradeAgreements,
        command: OpenResourceExchangeCommand(
          playerId: playerId,
          targetPlayerId: targetPlayerId,
          offeredResource: offeredResource,
          requestedResource: requestedResource,
          durationTurns: durationTurns,
          agreementId: agreementId,
        ),
        actorPlayerId: playerId,
        mapTiles: mapTiles,
      ),
    );
  }

  static PersistentResourceTradeResult _apply(
    PersistentGameState state,
    ResourceTradeCommandResult result,
  ) {
    if (!result.accepted) {
      return PersistentResourceTradeResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    final currentAgreements = state.runtimeState.resourceTradeAgreements;
    return PersistentResourceTradeResult(
      accepted: true,
      state: identical(result.resourceTradeAgreements, currentAgreements)
          ? state
          : state.copyWith(
              runtimeState: state.runtimeState.copyWith(
                resourceTradeAgreements: result.resourceTradeAgreements,
              ),
            ),
    );
  }
}
