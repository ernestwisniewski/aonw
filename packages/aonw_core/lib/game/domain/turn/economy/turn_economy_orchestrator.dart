import 'package:aonw_core/game/domain/turn/economy/turn_economy_context.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_fog_economy_advancer.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_map_objective_economy_advancer.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_player_economy_advancer.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_resource_trade_economy_advancer.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_stability_economy_advancer.dart';

/// Runs the complete persistence-neutral economy phase in canonical order.
abstract final class TurnEconomyOrchestrator {
  static TurnEconomyResult advanceForPlayers({
    required TurnEconomyState state,
    required TurnEconomyContext context,
  }) {
    final players = TurnPlayerEconomyBatchAdvancer.advance(
      state: state,
      context: context,
    );
    final objectives = TurnMapObjectiveEconomyAdvancer.advance(
      state: players.state,
      context: context,
    );
    final traded = TurnResourceTradeEconomyAdvancer.advance(
      state: objectives.state,
      playerIds: context.playerIds,
    );
    final economyEvents = [...players.events, ...objectives.events];
    final stability = TurnStabilityEconomyAdvancer.advance(
      state: traded,
      context: context,
      economyEvents: economyEvents,
    );
    final finalState = TurnFogEconomyAdvancer.advance(
      state: stability.state,
      context: context,
    );
    return TurnEconomyResult(
      state: finalState,
      events: [...economyEvents, ...stability.events],
      scienceGained: players.scienceGained,
    );
  }
}
