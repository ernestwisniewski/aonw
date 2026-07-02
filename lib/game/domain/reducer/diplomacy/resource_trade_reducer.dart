import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/map/domain/map_data.dart';

abstract final class ResourceTradeReducer {
  static GameStateTransition openTrade(
    GameState state,
    OpenResourceTradeCommand command,
    MapData mapData, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final actorPlayerId = context.actorPlayerId ?? state.activePlayerId;
    if (command.playerId != actorPlayerId || command.playerId.isEmpty) {
      return GameStateTransition(state: state);
    }

    final result = const PersistentResourceTradeResolver()
        .openGoldForResourceTrade(
          state: _persistentState(state),
          importerPlayerId: command.playerId,
          exporterPlayerId: command.targetPlayerId,
          resource: command.resource,
          goldPerTurn: command.goldPerTurn,
          durationTurns: command.durationTurns,
          mapData: mapData,
          agreementId: command.agreementId,
        );
    if (!result.accepted) return GameStateTransition(state: state);
    return GameStateTransition(state: _fromPersistent(state, result.state));
  }

  static GameStateTransition openExchange(
    GameState state,
    OpenResourceExchangeCommand command,
    MapData mapData, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final actorPlayerId = context.actorPlayerId ?? state.activePlayerId;
    if (command.playerId != actorPlayerId || command.playerId.isEmpty) {
      return GameStateTransition(state: state);
    }

    final result = const PersistentResourceTradeResolver()
        .openResourceForResourceTrade(
          state: _persistentState(state),
          playerId: command.playerId,
          targetPlayerId: command.targetPlayerId,
          offeredResource: command.offeredResource,
          requestedResource: command.requestedResource,
          durationTurns: command.durationTurns,
          mapData: mapData,
          agreementId: command.agreementId,
        );
    if (!result.accepted) return GameStateTransition(state: state);
    return GameStateTransition(state: _fromPersistent(state, result.state));
  }

  static PersistentGameState _persistentState(GameState state) {
    return PersistentGameState(
      playerColors: state.playerColors,
      playerCountries: state.playerCountries,
      playerGold: state.playerGold,
      playerWarWeariness: state.playerWarWeariness,
      playerStabilityNet: state.playerStabilityNet,
      units: state.units,
      cities: state.cities,
      artifacts: state.artifacts,
      fieldImprovements: state.fieldImprovements,
      fogOfWar: state.fogOfWar,
      research: state.research,
      runtimeState: state.runtimeState,
    );
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
