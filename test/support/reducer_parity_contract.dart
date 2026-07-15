import 'package:aonw_core/domain.dart';

const reducerParityRequiredFamilies = <String>{
  'auto-explore',
  'movement',
  'combat',
  'city-production',
  'detachment',
  'research',
  'worker',
  'turn-finalization',
};

const reducerParityRequiredRejectionReasons = <String, Set<String>>{
  'auto-explore': {'unit_not_controlled', 'auto_explore_no_target'},
  'movement': {'unit_not_controlled', 'move_target_out_of_bounds'},
  'combat': {'attacker_not_controlled', 'attack_target_not_found'},
  'city-production': {
    'city_not_controlled',
    'building_not_available',
    'unit_supply_limit_reached',
  },
  'detachment': {'unit_not_controlled', 'detachment_destination_unavailable'},
  'research': {'technology_player_not_controlled', 'technology_not_available'},
  'worker': {'worker_not_controlled', 'worker_improvement_unavailable'},
  'turn-finalization': {'turn_player_not_controlled', 'turn_player_not_active'},
};

bool reducerParityCommandMatchesFamily(String family, GameCommand command) {
  return switch (family) {
    'auto-explore' => command is AutoExploreUnitCommand,
    'movement' => command is MoveUnitCommand,
    'combat' => command is AttackHexCommand,
    'city-production' =>
      command is StartBuildingCommand || command is StartUnitProductionCommand,
    'detachment' => command is DetachTroopCommand,
    'research' => command is SelectTechnologyCommand,
    'worker' => command is ConfirmWorkerImprovementCommand,
    'turn-finalization' => command is SubmitTurnCommand,
    _ => false,
  };
}
