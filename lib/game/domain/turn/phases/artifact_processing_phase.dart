import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';
import 'package:aonw_core/game/domain/artifact.dart';

class ArtifactProcessingPhase extends TurnPhase {
  const ArtifactProcessingPhase();

  @override
  TurnContext apply(TurnContext context) {
    final state = context.state;
    final result = PersistentArtifactTurnProcessor.advanceForPlayers(
      state: state.toPersistentState(),
      playerIds: [context.playerId],
    );
    if (!result.changed) return context;
    return context.copyWith(
      state: state.copyWith(
        units: result.state.units,
        artifacts: result.state.artifacts,
        playerWarWeariness: result.state.playerWarWeariness,
        playerStabilityNet: result.state.playerStabilityNet,
      ),
    );
  }
}
