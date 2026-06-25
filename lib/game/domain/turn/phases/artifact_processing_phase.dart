import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/state.dart';

class ArtifactProcessingPhase extends TurnPhase {
  const ArtifactProcessingPhase();

  @override
  TurnContext apply(TurnContext context) {
    final state = context.state;
    final result = PersistentArtifactTurnProcessor.advanceForPlayers(
      state: PersistentGameState(
        units: state.units,
        cities: state.cities,
        artifacts: state.artifacts,
        runtimeState: state.runtimeState,
      ),
      playerIds: [context.playerId],
    );
    if (!result.changed) return context;
    return context.copyWith(
      state: state.copyWith(
        units: result.state.units,
        artifacts: result.state.artifacts,
      ),
    );
  }
}
