import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/state.dart';

class CulturalVictoryProgressPhase extends TurnPhase {
  const CulturalVictoryProgressPhase();

  @override
  TurnContext apply(TurnContext context) {
    final victoryRules =
        context.save?.matchRules.victory ?? VictoryRules.standard;
    if (!victoryRules.culturalEnabled) return context;
    final state = context.state;
    final holdTurns = CulturalVictoryProgressCalculator.advanceHoldTurns(
      playerIds: [context.playerId],
      state: PersistentGameState(
        units: state.units,
        cities: state.cities,
        artifacts: state.artifacts,
        playerWarWeariness: state.playerWarWeariness,
        playerStabilityNet: state.playerStabilityNet,
        runtimeState: state.runtimeState,
      ),
      previousHoldTurnsByPlayerId: state.culturalVictoryHoldTurnsByPlayerId,
      requiredArtifactCount: victoryRules.culturalRequiredArtifacts,
    );
    if (holdTurns == state.culturalVictoryHoldTurnsByPlayerId) {
      return context;
    }
    return context.copyWith(
      state: state.copyWith(culturalVictoryHoldTurnsByPlayerId: holdTurns),
    );
  }
}
