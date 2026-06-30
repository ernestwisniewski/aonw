import 'package:aonw_core/game/domain/command.dart';

final class EconomySimulationCommandStats {
  var meaningful = 0;
  var foundCity = 0;
  var startUnit = 0;
  var startBuilding = 0;
  var startProject = 0;
  var workerJob = 0;
  var move = 0;
  var attack = 0;
  var rejected = 0;

  void addApplied(GameCommand command) {
    meaningful += 1;
    switch (command) {
      case FoundCityCommand():
        foundCity += 1;
      case StartUnitProductionCommand():
        startUnit += 1;
      case StartBuildingCommand():
        startBuilding += 1;
      case StartCityProjectCommand():
        startProject += 1;
      case SetCitySpecializationCommand():
        break;
      case SelectWorkerImprovementCommand() || AssignWorkerToHexCommand():
        workerJob += 1;
      case MoveUnitCommand():
        move += 1;
      case MoveMerchantToCityCommand():
        move += 1;
      case AttackHexCommand():
        attack += 1;
      case TileTappedCommand() ||
          CityTappedCommand() ||
          CancelUnitActionCommand() ||
          SkipUnitTurnCommand() ||
          FortifyUnitCommand() ||
          AutoExploreUnitCommand() ||
          RushProductionCommand() ||
          SelectTechnologyCommand() ||
          CancelResearchSelectionCommand() ||
          DetachTroopCommand() ||
          StartMerchantTradeRouteSelectionCommand() ||
          CancelMerchantTradeRouteSelectionCommand() ||
          AssignMerchantTradeRouteCommand() ||
          StartMerchantMoveToCitySelectionCommand() ||
          CancelMerchantMoveToCitySelectionCommand() ||
          SendDiplomaticProposalCommand() ||
          RespondDiplomaticProposalCommand() ||
          SendDiplomaticMessageCommand() ||
          RespondDiplomaticMessageCommand() ||
          DeclareWarCommand() ||
          SendGoldGiftCommand() ||
          EndTurnCommand() ||
          SubmitTurnCommand() ||
          StartArtifactExcavationCommand() ||
          StoreArtifactInCityCommand() ||
          TradeArtifactCommand() ||
          OpenResourceTradeCommand() ||
          OpenResourceExchangeCommand() ||
          ResetUnitMovementCommand() ||
          SetActivePlayerCommand() ||
          ToggleMoveTargetingCommand() ||
          StartCityFoundingCommand() ||
          CancelCityFoundingCommand() ||
          StartCityWorkedHexSelectionCommand() ||
          CancelCityWorkedHexSelectionCommand() ||
          ToggleWorkedHexCommand() ||
          StartCityExpansionSelectionCommand() ||
          CancelCityExpansionSelectionCommand() ||
          SelectCityExpansionHexCommand() ||
          StartWorkerActionSelectionCommand() ||
          ConfirmWorkerImprovementCommand() ||
          CancelWorkerActionSelectionCommand() ||
          CancelWorkerJobCommand() ||
          CancelWorkerAssignmentCommand() ||
          StartAttackTargetingCommand() ||
          CancelAttackTargetingCommand() ||
          StartCommanderMergeSelectionCommand() ||
          CancelCommanderMergeSelectionCommand() ||
          SelectTileCommand() ||
          SelectUnitCommand() ||
          SelectCityCommand() ||
          FocusNextPendingActionCommand() ||
          FocusTurnStartActionCommand():
        break;
    }
  }
}
