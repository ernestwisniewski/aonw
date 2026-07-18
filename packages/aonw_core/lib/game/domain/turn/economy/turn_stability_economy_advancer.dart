import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/stability/stability_turn_processor.dart';

import 'package:aonw_core/game/domain/turn/economy/turn_economy_context.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_player_catalog.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';

abstract final class TurnStabilityEconomyAdvancer {
  static TurnEconomyResult advance({
    required TurnEconomyState state,
    required TurnEconomyContext context,
    required Iterable<GameEvent> economyEvents,
  }) {
    final knownPlayerIds = TurnEconomyPlayerCatalog.knownPlayerIds(
      state: state,
      basePlayerIds: context.baseKnownPlayerIds,
    );
    final result = StabilityTurnProcessor.advanceForPlayers(
      knownPlayerIds: knownPlayerIds,
      playerIds: context.playerIds,
      playerWarWearinessByPlayerId: state.playerWarWeariness,
      playerStabilityNetByPlayerId: state.playerStabilityNet,
      cities: state.cities,
      artifacts: state.artifacts,
      research: state.research,
      wonderRegistry: state.wonderRegistry,
      diplomacy: state.diplomacy,
      mapData: context.mapData,
      ruleset: context.ruleset.stability,
      turnEvents: [...context.priorEvents, ...economyEvents],
      turn: context.turn,
    );
    return TurnEconomyResult(
      state: state.copyWith(
        playerWarWeariness: result.warWearinessByPlayerId,
        playerStabilityNet: result.stabilityNetByPlayerId,
      ),
      events: result.events,
    );
  }
}
