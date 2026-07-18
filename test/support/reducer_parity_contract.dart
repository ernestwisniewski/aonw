import 'package:aonw_core/domain.dart';

const reducerParityRequiredFamilies = <String>{
  'auto-explore',
  'artifacts',
  'movement',
  'merchant-routing',
  'combat',
  'city-expansion',
  'city-production',
  'city-worked-hex',
  'detachment',
  'research',
  'resource-trade',
  'unit-actions',
  'worker',
  'turn-finalization',
};

const reducerParityRequiredRejectionReasons = <String, Set<String>>{
  'auto-explore': {'unit_not_controlled', 'auto_explore_no_target'},
  'artifacts': {
    'unit_not_controlled',
    'artifact_not_found',
    'city_artifact_slot_full',
    'invalid_artifact_trade_actor',
    'artifact_trade_requires_acceptance',
  },
  'movement': {'unit_not_controlled', 'move_target_out_of_bounds'},
  'merchant-routing': {
    'unit_not_controlled',
    'merchant_route_not_found',
    'merchant_city_path_not_found',
  },
  'combat': {'attacker_not_controlled', 'attack_target_not_found'},
  'city-expansion': {'city_not_controlled', 'city_expansion_hex_unavailable'},
  'city-production': {
    'city_not_controlled',
    'building_not_available',
    'unit_supply_limit_reached',
  },
  'city-worked-hex': {'city_not_controlled', 'worked_hex_limit_reached'},
  'detachment': {
    'unit_not_controlled',
    'detachment_destination_unavailable',
    'detachment_source_out_of_bounds',
  },
  'research': {'technology_player_not_controlled', 'technology_not_available'},
  'resource-trade': {
    'resource_trade_player_not_controlled',
    'resource_trade_export_unavailable',
  },
  'unit-actions': {'unit_not_controlled', 'unit_busy'},
  'worker': {'worker_not_controlled', 'worker_improvement_unavailable'},
  'turn-finalization': {'turn_player_not_controlled', 'turn_player_not_active'},
};

typedef _ReducerParityCommandMatcher = bool Function(GameCommand command);

final _reducerParityCommandMatchers = <String, _ReducerParityCommandMatcher>{
  'auto-explore': _matchesAutoExploreCommand,
  'artifacts': _matchesArtifactCommand,
  'movement': _matchesMovementCommand,
  'merchant-routing': _matchesMerchantRoutingCommand,
  'combat': _matchesCombatCommand,
  'city-expansion': _matchesCityExpansionCommand,
  'city-production': _matchesCityProductionCommand,
  'city-worked-hex': _matchesCityWorkedHexCommand,
  'detachment': _matchesDetachmentCommand,
  'research': _matchesResearchCommand,
  'resource-trade': _matchesResourceTradeCommand,
  'unit-actions': _matchesUnitActionCommand,
  'worker': _matchesWorkerCommand,
  'turn-finalization': _matchesTurnFinalizationCommand,
};

bool reducerParityCommandMatchesFamily(String family, GameCommand command) {
  return _reducerParityCommandMatchers[family]?.call(command) ?? false;
}

bool _matchesAutoExploreCommand(GameCommand command) {
  return command is AutoExploreUnitCommand;
}

bool _matchesArtifactCommand(GameCommand command) {
  return command is StartArtifactExcavationCommand ||
      command is StoreArtifactInCityCommand ||
      command is TradeArtifactCommand;
}

bool _matchesMovementCommand(GameCommand command) {
  return command is MoveUnitCommand;
}

bool _matchesMerchantRoutingCommand(GameCommand command) {
  return command is AssignMerchantTradeRouteCommand ||
      command is MoveMerchantToCityCommand;
}

bool _matchesCombatCommand(GameCommand command) {
  return command is AttackHexCommand;
}

bool _matchesCityExpansionCommand(GameCommand command) {
  return command is SelectCityExpansionHexCommand;
}

bool _matchesCityProductionCommand(GameCommand command) {
  return command is StartBuildingCommand ||
      command is StartUnitProductionCommand ||
      command is StartWonderCommand ||
      command is RushProductionCommand;
}

bool _matchesCityWorkedHexCommand(GameCommand command) {
  return command is ToggleWorkedHexCommand;
}

bool _matchesDetachmentCommand(GameCommand command) {
  return command is DetachTroopCommand;
}

bool _matchesResearchCommand(GameCommand command) {
  return command is SelectTechnologyCommand;
}

bool _matchesResourceTradeCommand(GameCommand command) {
  return command is OpenResourceTradeCommand ||
      command is OpenResourceExchangeCommand;
}

bool _matchesUnitActionCommand(GameCommand command) {
  return command is CancelUnitActionCommand ||
      command is SkipUnitTurnCommand ||
      command is FortifyUnitCommand;
}

bool _matchesWorkerCommand(GameCommand command) {
  return command is SelectWorkerImprovementCommand ||
      command is ConfirmWorkerImprovementCommand ||
      command is CancelWorkerJobCommand ||
      command is AssignWorkerToHexCommand ||
      command is CancelWorkerAssignmentCommand;
}

bool _matchesTurnFinalizationCommand(GameCommand command) {
  return command is SubmitTurnCommand;
}
