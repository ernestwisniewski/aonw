import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/objective.dart';

class GameObjectivePresentation {
  final String title;
  final String hint;
  final String rewardLabel;
  final String microTooltip;
  final String phaseLabel;

  const GameObjectivePresentation({
    required this.title,
    required this.hint,
    required this.rewardLabel,
    required this.microTooltip,
    required this.phaseLabel,
  });
}

abstract final class GameObjectiveLabels {
  static GameObjectivePresentation presentation(
    AppLocalizations l10n,
    GameObjectiveDefinition definition,
  ) {
    return GameObjectivePresentation(
      title: title(l10n, definition.id),
      hint: hint(l10n, definition.id),
      rewardLabel: rewardLabel(l10n, definition.id),
      microTooltip: microTooltip(l10n, definition.id),
      phaseLabel: phaseLabel(l10n, definition.phase),
    );
  }

  static String title(AppLocalizations l10n, GameObjectiveId id) {
    return switch (id) {
      GameObjectiveId.chooseResearch => l10n.objectiveChooseResearchTitle,
      GameObjectiveId.foundCapital => l10n.objectiveFoundCapitalTitle,
      GameObjectiveId.exploreNearby => l10n.objectiveExploreNearbyTitle,
      GameObjectiveId.queueWorker => l10n.objectiveQueueWorkerTitle,
      GameObjectiveId.improveFirstHex => l10n.objectiveImproveFirstHexTitle,
      GameObjectiveId.foundSecondCity => l10n.objectiveFoundSecondCityTitle,
      GameObjectiveId.buildFirstBuilding =>
        l10n.objectiveBuildFirstBuildingTitle,
      GameObjectiveId.improveThreeHexes => l10n.objectiveImproveThreeHexesTitle,
      GameObjectiveId.foundThirdCity => l10n.objectiveFoundThirdCityTitle,
      GameObjectiveId.exploreRegion => l10n.objectiveExploreRegionTitle,
      GameObjectiveId.buildCombatForce => l10n.objectiveBuildCombatForceTitle,
      GameObjectiveId.raiseStability => l10n.objectiveRaiseStabilityTitle,
      GameObjectiveId.holdDomination => l10n.objectiveHoldDominationTitle,
      GameObjectiveId.breakDominationHold =>
        l10n.objectiveBreakDominationHoldTitle,
      GameObjectiveId.holdScoreLead => l10n.objectiveHoldScoreLeadTitle,
      GameObjectiveId.overtakeScoreLeader =>
        l10n.objectiveOvertakeScoreLeaderTitle,
      GameObjectiveId.secureMapObjective =>
        l10n.objectiveSecureMapObjectiveTitle,
      GameObjectiveId.breakMapObjectiveHold =>
        l10n.objectiveBreakMapObjectiveHoldTitle,
    };
  }

  static String hint(AppLocalizations l10n, GameObjectiveId id) {
    return switch (id) {
      GameObjectiveId.chooseResearch => l10n.objectiveChooseResearchHint,
      GameObjectiveId.foundCapital => l10n.objectiveFoundCapitalHint,
      GameObjectiveId.exploreNearby => l10n.objectiveExploreNearbyHint,
      GameObjectiveId.queueWorker => l10n.objectiveQueueWorkerHint,
      GameObjectiveId.improveFirstHex => l10n.objectiveImproveFirstHexHint,
      GameObjectiveId.foundSecondCity => l10n.objectiveFoundSecondCityHint,
      GameObjectiveId.buildFirstBuilding =>
        l10n.objectiveBuildFirstBuildingHint,
      GameObjectiveId.improveThreeHexes => l10n.objectiveImproveThreeHexesHint,
      GameObjectiveId.foundThirdCity => l10n.objectiveFoundThirdCityHint,
      GameObjectiveId.exploreRegion => l10n.objectiveExploreRegionHint,
      GameObjectiveId.buildCombatForce => l10n.objectiveBuildCombatForceHint,
      GameObjectiveId.raiseStability => l10n.objectiveRaiseStabilityHint,
      GameObjectiveId.holdDomination => l10n.objectiveHoldDominationHint,
      GameObjectiveId.breakDominationHold =>
        l10n.objectiveBreakDominationHoldHint,
      GameObjectiveId.holdScoreLead => l10n.objectiveHoldScoreLeadHint,
      GameObjectiveId.overtakeScoreLeader =>
        l10n.objectiveOvertakeScoreLeaderHint,
      GameObjectiveId.secureMapObjective =>
        l10n.objectiveSecureMapObjectiveHint,
      GameObjectiveId.breakMapObjectiveHold =>
        l10n.objectiveBreakMapObjectiveHoldHint,
    };
  }

  static String rewardLabel(AppLocalizations l10n, GameObjectiveId id) {
    return switch (id) {
      GameObjectiveId.chooseResearch => l10n.objectiveChooseResearchReward,
      GameObjectiveId.foundCapital => l10n.objectiveFoundCapitalReward,
      GameObjectiveId.exploreNearby => l10n.objectiveExploreNearbyReward,
      GameObjectiveId.queueWorker => l10n.objectiveQueueWorkerReward,
      GameObjectiveId.improveFirstHex => l10n.objectiveImproveFirstHexReward,
      GameObjectiveId.foundSecondCity => l10n.objectiveFoundSecondCityReward,
      GameObjectiveId.buildFirstBuilding =>
        l10n.objectiveBuildFirstBuildingReward,
      GameObjectiveId.improveThreeHexes =>
        l10n.objectiveImproveThreeHexesReward,
      GameObjectiveId.foundThirdCity => l10n.objectiveFoundThirdCityReward,
      GameObjectiveId.exploreRegion => l10n.objectiveExploreRegionReward,
      GameObjectiveId.buildCombatForce => l10n.objectiveBuildCombatForceReward,
      GameObjectiveId.raiseStability => l10n.objectiveRaiseStabilityReward,
      GameObjectiveId.holdDomination => l10n.objectiveHoldDominationReward,
      GameObjectiveId.breakDominationHold =>
        l10n.objectiveBreakDominationHoldReward,
      GameObjectiveId.holdScoreLead => l10n.objectiveHoldScoreLeadReward,
      GameObjectiveId.overtakeScoreLeader =>
        l10n.objectiveOvertakeScoreLeaderReward,
      GameObjectiveId.secureMapObjective =>
        l10n.objectiveSecureMapObjectiveReward,
      GameObjectiveId.breakMapObjectiveHold =>
        l10n.objectiveBreakMapObjectiveHoldReward,
    };
  }

  static String microTooltip(AppLocalizations l10n, GameObjectiveId id) {
    return switch (id) {
      GameObjectiveId.chooseResearch => l10n.objectiveChooseResearchTooltip,
      GameObjectiveId.foundCapital => l10n.objectiveFoundCapitalTooltip,
      GameObjectiveId.exploreNearby => l10n.objectiveExploreNearbyTooltip,
      GameObjectiveId.queueWorker => l10n.objectiveQueueWorkerTooltip,
      GameObjectiveId.improveFirstHex => l10n.objectiveImproveFirstHexTooltip,
      GameObjectiveId.foundSecondCity => l10n.objectiveFoundSecondCityTooltip,
      GameObjectiveId.buildFirstBuilding =>
        l10n.objectiveBuildFirstBuildingTooltip,
      GameObjectiveId.improveThreeHexes =>
        l10n.objectiveImproveThreeHexesTooltip,
      GameObjectiveId.foundThirdCity => l10n.objectiveFoundThirdCityTooltip,
      GameObjectiveId.exploreRegion => l10n.objectiveExploreRegionTooltip,
      GameObjectiveId.buildCombatForce => l10n.objectiveBuildCombatForceTooltip,
      GameObjectiveId.raiseStability => l10n.objectiveRaiseStabilityTooltip,
      GameObjectiveId.holdDomination => l10n.objectiveHoldDominationTooltip,
      GameObjectiveId.breakDominationHold =>
        l10n.objectiveBreakDominationHoldTooltip,
      GameObjectiveId.holdScoreLead => l10n.objectiveHoldScoreLeadTooltip,
      GameObjectiveId.overtakeScoreLeader =>
        l10n.objectiveOvertakeScoreLeaderTooltip,
      GameObjectiveId.secureMapObjective =>
        l10n.objectiveSecureMapObjectiveTooltip,
      GameObjectiveId.breakMapObjectiveHold =>
        l10n.objectiveBreakMapObjectiveHoldTooltip,
    };
  }

  static String? advice(AppLocalizations l10n, GameObjectiveAdvice? advice) {
    return switch (advice) {
      null => null,
      GameObjectiveAdvice.foundCity => l10n.objectiveAdviceFoundCity,
      GameObjectiveAdvice.growPopulation => l10n.objectiveAdviceGrowPopulation,
      GameObjectiveAdvice.claimTerritory => l10n.objectiveAdviceClaimTerritory,
      GameObjectiveAdvice.constructBuilding =>
        l10n.objectiveAdviceConstructBuilding,
      GameObjectiveAdvice.trainUnit => l10n.objectiveAdviceTrainUnit,
      GameObjectiveAdvice.unlockTechnology =>
        l10n.objectiveAdviceUnlockTechnology,
      GameObjectiveAdvice.improveField => l10n.objectiveAdviceImproveField,
      GameObjectiveAdvice.collectGold => l10n.objectiveAdviceCollectGold,
      GameObjectiveAdvice.protectLead => l10n.objectiveAdviceProtectLead,
    };
  }

  static String scoreCategory(
    AppLocalizations l10n,
    GameObjectiveAdvice advice,
  ) {
    return switch (advice) {
      GameObjectiveAdvice.foundCity => l10n.objectiveScoreCategoryCity,
      GameObjectiveAdvice.growPopulation =>
        l10n.objectiveScoreCategoryPopulation,
      GameObjectiveAdvice.claimTerritory =>
        l10n.objectiveScoreCategoryTerritory,
      GameObjectiveAdvice.constructBuilding =>
        l10n.objectiveScoreCategoryBuilding,
      GameObjectiveAdvice.trainUnit => l10n.objectiveScoreCategoryUnit,
      GameObjectiveAdvice.unlockTechnology =>
        l10n.objectiveScoreCategoryTechnology,
      GameObjectiveAdvice.improveField =>
        l10n.objectiveScoreCategoryImprovement,
      GameObjectiveAdvice.collectGold => l10n.objectiveScoreCategoryGold,
      GameObjectiveAdvice.protectLead => l10n.objectiveAdviceProtectLead,
    };
  }

  static String phaseLabel(AppLocalizations l10n, GameObjectivePhase phase) {
    return switch (phase) {
      GameObjectivePhase.foundation => l10n.objectivePhaseFoundation,
      GameObjectivePhase.expansion => l10n.objectivePhaseExpansion,
      GameObjectivePhase.pressure => l10n.objectivePhasePressure,
      GameObjectivePhase.endgame => l10n.objectivePhaseEndgame,
    };
  }
}
