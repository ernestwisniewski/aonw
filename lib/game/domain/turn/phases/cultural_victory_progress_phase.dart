import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/match_rules.dart';

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
      state: state.toPersistentState(),
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
