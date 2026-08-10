import 'package:aonw_core/game/domain/objective/game_objective_model.dart';

abstract final class GameObjectiveCatalog {
  static const List<GameObjectiveDefinition> earlyGameObjectives = [
    GameObjectiveDefinition(
      id: GameObjectiveId.chooseResearch,
      phase: GameObjectivePhase.foundation,
      targetValue: 1,
      tone: GameObjectiveTone.research,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.foundCapital,
      phase: GameObjectivePhase.foundation,
      targetValue: 1,
      tone: GameObjectiveTone.expansion,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.exploreNearby,
      phase: GameObjectivePhase.foundation,
      targetValue: 28,
      tone: GameObjectiveTone.exploration,
      targetScaling: GameObjectiveTargetScaling.pace,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.queueWorker,
      phase: GameObjectivePhase.foundation,
      targetValue: 1,
      tone: GameObjectiveTone.economy,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.improveFirstHex,
      phase: GameObjectivePhase.foundation,
      targetValue: 1,
      tone: GameObjectiveTone.economy,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.foundSecondCity,
      phase: GameObjectivePhase.foundation,
      targetValue: 2,
      tone: GameObjectiveTone.expansion,
    ),
  ];

  static const List<GameObjectiveDefinition> expansionObjectives = [
    GameObjectiveDefinition(
      id: GameObjectiveId.buildFirstBuilding,
      phase: GameObjectivePhase.expansion,
      targetValue: 1,
      tone: GameObjectiveTone.economy,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.improveThreeHexes,
      phase: GameObjectivePhase.expansion,
      targetValue: 3,
      tone: GameObjectiveTone.economy,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.foundThirdCity,
      phase: GameObjectivePhase.expansion,
      targetValue: 3,
      tone: GameObjectiveTone.expansion,
    ),
  ];

  static const List<GameObjectiveDefinition> pressureObjectives = [
    GameObjectiveDefinition(
      id: GameObjectiveId.exploreRegion,
      phase: GameObjectivePhase.pressure,
      targetValue: 70,
      tone: GameObjectiveTone.exploration,
      targetScaling: GameObjectiveTargetScaling.pace,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.buildCombatForce,
      phase: GameObjectivePhase.pressure,
      targetValue: 3,
      tone: GameObjectiveTone.expansion,
      targetScaling: GameObjectiveTargetScaling.pace,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.raiseStability,
      phase: GameObjectivePhase.pressure,
      targetValue: 1,
      tone: GameObjectiveTone.economy,
    ),
  ];

  static const holdDominationObjective = GameObjectiveDefinition(
    id: GameObjectiveId.holdDomination,
    phase: GameObjectivePhase.endgame,
    track: GameObjectiveTrack.strategic,
    targetValue: 1,
    tone: GameObjectiveTone.victory,
  );

  static const breakDominationHoldObjective = GameObjectiveDefinition(
    id: GameObjectiveId.breakDominationHold,
    phase: GameObjectivePhase.endgame,
    track: GameObjectiveTrack.strategic,
    targetValue: 1,
    tone: GameObjectiveTone.warning,
  );

  static const holdScoreLeadObjective = GameObjectiveDefinition(
    id: GameObjectiveId.holdScoreLead,
    phase: GameObjectivePhase.endgame,
    track: GameObjectiveTrack.strategic,
    targetValue: 1,
    tone: GameObjectiveTone.victory,
  );

  static const overtakeScoreLeaderObjective = GameObjectiveDefinition(
    id: GameObjectiveId.overtakeScoreLeader,
    phase: GameObjectivePhase.endgame,
    track: GameObjectiveTrack.strategic,
    targetValue: 1,
    tone: GameObjectiveTone.warning,
  );

  static const secureMapObjective = GameObjectiveDefinition(
    id: GameObjectiveId.secureMapObjective,
    phase: GameObjectivePhase.pressure,
    track: GameObjectiveTrack.strategic,
    targetValue: 1,
    tone: GameObjectiveTone.victory,
  );

  static const breakMapObjectiveHoldObjective = GameObjectiveDefinition(
    id: GameObjectiveId.breakMapObjectiveHold,
    phase: GameObjectivePhase.pressure,
    track: GameObjectiveTrack.strategic,
    targetValue: 1,
    tone: GameObjectiveTone.warning,
  );

  static const List<GameObjectiveDefinition> guidanceObjectives = [
    ...earlyGameObjectives,
    ...expansionObjectives,
    ...pressureObjectives,
  ];

  static const List<GameObjectiveDefinition> strategicObjectives = [
    holdDominationObjective,
    breakDominationHoldObjective,
    holdScoreLeadObjective,
    overtakeScoreLeaderObjective,
    secureMapObjective,
    breakMapObjectiveHoldObjective,
  ];
}
