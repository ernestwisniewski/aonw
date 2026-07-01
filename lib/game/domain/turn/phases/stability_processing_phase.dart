import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/state.dart';

class StabilityProcessingPhase extends TurnPhase {
  const StabilityProcessingPhase();

  @override
  TurnContext apply(TurnContext context) {
    final state = context.state;
    final result = PersistentStabilityProcessor.advanceForPlayers(
      state: _persistentState(state),
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
    );
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
}
