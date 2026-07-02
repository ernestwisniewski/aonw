import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';
import 'package:aonw_core/game/domain/stability.dart';

class StabilityProcessingPhase extends TurnPhase {
  const StabilityProcessingPhase();

  @override
  TurnContext apply(TurnContext context) {
    final state = context.state;
    final result = PersistentStabilityProcessor.advanceForPlayers(
      state: state.toPersistentState(),
      playerIds: [context.playerId],
      mapData: context.mapData,
      ruleset: context.ruleset.stability,
      turnEvents: context.events,
    );

    return context.copyWith(
      state: state.copyWith(
        playerWarWeariness: result.state.playerWarWeariness,
        playerStabilityNet: result.state.playerStabilityNet,
      ),
      events: [...context.events, ...result.events],
    );
  }
}
