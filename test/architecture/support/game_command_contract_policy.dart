part of '../game_command_contract_test.dart';

const _rolePolicy = <String, _CommandRole>{
  'AssignMerchantTradeRouteCommand': _CommandRole.domain,
  'AssignWorkerToHexCommand': _CommandRole.domain,
  'AttackHexCommand': _CommandRole.domain,
  'AutoExploreUnitCommand': _CommandRole.domain,
  'CancelAttackTargetingCommand': _CommandRole.intent,
  'CancelCityExpansionSelectionCommand': _CommandRole.intent,
  'CancelCityFoundingCommand': _CommandRole.intent,
  'CancelCityWorkedHexSelectionCommand': _CommandRole.intent,
  'CancelCommanderMergeSelectionCommand': _CommandRole.intent,
  'CancelMerchantMoveToCitySelectionCommand': _CommandRole.intent,
  'CancelMerchantTradeRouteSelectionCommand': _CommandRole.intent,
  'CancelResearchSelectionCommand': _CommandRole.intent,
  'CancelUnitActionCommand': _CommandRole.domain,
  'CancelWorkerActionSelectionCommand': _CommandRole.intent,
  'CancelWorkerAssignmentCommand': _CommandRole.domain,
  'CancelWorkerJobCommand': _CommandRole.domain,
  'CityTappedCommand': _CommandRole.intent,
  'ChooseWorkerImprovementIntent': _CommandRole.intent,
  'ConfirmWorkerImprovementIntent': _CommandRole.intent,
  'ConfirmWorkerImprovementCommand': _CommandRole.domain,
  'DeclareWarCommand': _CommandRole.domain,
  'DetachTroopCommand': _CommandRole.domain,
  'EndTurnCommand': _CommandRole.domain,
  'FocusNextPendingActionCommand': _CommandRole.intent,
  'FocusTurnStartActionCommand': _CommandRole.intent,
  'FortifyUnitCommand': _CommandRole.domain,
  'FoundCityCommand': _CommandRole.domain,
  'MoveMerchantToCityCommand': _CommandRole.domain,
  'MoveUnitCommand': _CommandRole.domain,
  'OpenResourceExchangeCommand': _CommandRole.domain,
  'OpenResourceTradeCommand': _CommandRole.domain,
  'RespondDiplomaticMessageCommand': _CommandRole.domain,
  'RespondDiplomaticProposalCommand': _CommandRole.domain,
  'RushProductionCommand': _CommandRole.domain,
  'SelectCityCommand': _CommandRole.intent,
  'SelectCityExpansionHexCommand': _CommandRole.domain,
  'SelectTechnologyCommand': _CommandRole.domain,
  'SelectTileCommand': _CommandRole.intent,
  'SelectUnitCommand': _CommandRole.intent,
  'SelectWorkerImprovementCommand': _CommandRole.domain,
  'SendDiplomaticMessageCommand': _CommandRole.domain,
  'SendDiplomaticProposalCommand': _CommandRole.domain,
  'SendGoldGiftCommand': _CommandRole.domain,
  'SetCitySpecializationCommand': _CommandRole.domain,
  'SkipUnitTurnCommand': _CommandRole.domain,
  'StartArtifactExcavationCommand': _CommandRole.domain,
  'StartAttackTargetingCommand': _CommandRole.intent,
  'StartBuildingCommand': _CommandRole.domain,
  'StartCityExpansionSelectionCommand': _CommandRole.intent,
  'StartCityFoundingCommand': _CommandRole.intent,
  'StartCityProjectCommand': _CommandRole.domain,
  'StartCityWorkedHexSelectionCommand': _CommandRole.intent,
  'StartCommanderMergeSelectionCommand': _CommandRole.intent,
  'StartMerchantMoveToCitySelectionCommand': _CommandRole.intent,
  'StartMerchantTradeRouteSelectionCommand': _CommandRole.intent,
  'StartUnitProductionCommand': _CommandRole.domain,
  'StartWonderCommand': _CommandRole.domain,
  'StartWorkerActionSelectionCommand': _CommandRole.intent,
  'StoreArtifactInCityCommand': _CommandRole.domain,
  'SubmitTurnCommand': _CommandRole.domain,
  'TileTappedCommand': _CommandRole.intent,
  'ToggleMoveTargetingCommand': _CommandRole.intent,
  'ToggleWorkedHexCommand': _CommandRole.domain,
  'TradeArtifactCommand': _CommandRole.domain,
};

const _indirectCommandFixtureSources = <String, String>{
  _commandLibraryPath: '''
part 'intermediate_command.dart';

sealed class GameIntent {
  const GameIntent();
}

sealed class DomainCommand {
  const DomainCommand();
}
''',
  'packages/aonw_core/lib/game/domain/command/intermediate_command.dart': '''
part of 'game_command.dart';

abstract class IntermediateCommand extends DomainCommand {
  const IntermediateCommand();
}

final class IndirectCommand extends IntermediateCommand {
  const IndirectCommand();
}
''',
  _serializerPath: '',
};
