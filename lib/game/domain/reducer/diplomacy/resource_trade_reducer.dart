import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
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
    final result = ResourceTradeCommandResolver.openGoldForResourceTrade(
      playerGold: state.playerGold,
      cities: state.cities,
      research: state.research,
      diplomacy: state.diplomacy,
      resourceTradeAgreements: state.resourceTradeAgreements,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    );
    if (!result.accepted) return GameStateTransition(state: state);
    return GameStateTransition(
      state: state.copyWith(
        resourceTradeAgreements: result.resourceTradeAgreements,
      ),
    );
  }

  static GameStateTransition openExchange(
    GameState state,
    OpenResourceExchangeCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final actorPlayerId = context.actorPlayerId ?? state.activePlayerId;
    final result = ResourceTradeCommandResolver.openResourceForResourceTrade(
      cities: state.cities,
      research: state.research,
      diplomacy: state.diplomacy,
      resourceTradeAgreements: state.resourceTradeAgreements,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    );
    if (!result.accepted) return GameStateTransition(state: state);
    return GameStateTransition(
      state: state.copyWith(
        resourceTradeAgreements: result.resourceTradeAgreements,
      ),
    );
  }
}
