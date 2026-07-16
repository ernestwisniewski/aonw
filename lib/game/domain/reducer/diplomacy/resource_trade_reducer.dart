import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract final class ResourceTradeReducer {
  static GameStateTransition openTrade(
    GameState state,
    OpenResourceTradeCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final actorPlayerId = context.actorPlayerId ?? state.activePlayerId;
    if (command.playerId != actorPlayerId || command.playerId.isEmpty) {
      return GameStateTransition(state: state);
    }

    final result = const PersistentResourceTradeResolver()
        .openGoldForResourceTrade(
          state: state.toPersistentState(),
          importerPlayerId: command.playerId,
          exporterPlayerId: command.targetPlayerId,
          resource: command.resource,
          goldPerTurn: command.goldPerTurn,
          durationTurns: command.durationTurns,
          mapTiles: mapTiles,
          agreementId: command.agreementId,
        );
    if (!result.accepted) return GameStateTransition(state: state);
    return GameStateTransition(state: _fromPersistent(state, result.state));
  }

  static GameStateTransition openExchange(
    GameState state,
    OpenResourceExchangeCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final actorPlayerId = context.actorPlayerId ?? state.activePlayerId;
    if (command.playerId != actorPlayerId || command.playerId.isEmpty) {
      return GameStateTransition(state: state);
    }

    final result = const PersistentResourceTradeResolver()
        .openResourceForResourceTrade(
          state: state.toPersistentState(),
          playerId: command.playerId,
          targetPlayerId: command.targetPlayerId,
          offeredResource: command.offeredResource,
          requestedResource: command.requestedResource,
          durationTurns: command.durationTurns,
          mapTiles: mapTiles,
          agreementId: command.agreementId,
        );
    if (!result.accepted) return GameStateTransition(state: state);
    return GameStateTransition(state: _fromPersistent(state, result.state));
  }

  static GameState _fromPersistent(
    GameState state,
    PersistentGameState persistent,
  ) {
    return state.copyWith(
      playerGold: persistent.playerGold,
      playerWarWeariness: persistent.playerWarWeariness,
      playerStabilityNet: persistent.playerStabilityNet,
      resourceTradeAgreements: persistent.runtimeState.resourceTradeAgreements,
    );
  }
}
