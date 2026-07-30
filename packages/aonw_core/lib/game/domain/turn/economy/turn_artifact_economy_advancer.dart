import 'package:aonw_core/game/domain/artifact/artifact_turn_processor.dart';

import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';

abstract final class TurnArtifactEconomyAdvancer {
  static TurnEconomyResult advance({
    required TurnEconomyState state,
    required String playerId,
  }) {
    final result = ArtifactTurnProcessor.advanceForPlayers(
      units: state.units,
      artifacts: state.artifacts,
      playerIds: [playerId],
    );
    if (!result.changed) return TurnEconomyResult(state: state);
    return TurnEconomyResult(
      state: state.copyWith(units: result.units, artifacts: result.artifacts),
      events: result.events,
    );
  }
}
