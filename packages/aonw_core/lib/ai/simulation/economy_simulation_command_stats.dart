import 'package:aonw_core/game/domain/command.dart';

const _workerJobCommandTypes = <Type>{
  SelectWorkerImprovementCommand,
  AssignWorkerToHexCommand,
  BuildRoadCommand,
};

final class EconomySimulationCommandStats {
  var meaningful = 0;
  var foundCity = 0;
  var startUnit = 0;
  var startBuilding = 0;
  var startProject = 0;
  var startWonder = 0;
  var workerJob = 0;
  var move = 0;
  var attack = 0;
  var rejected = 0;

  void addApplied(DomainCommand command) {
    meaningful += 1;
    if (_workerJobCommandTypes.contains(command.runtimeType)) {
      workerJob += 1;
      return;
    }
    switch (command) {
      case FoundCityCommand():
        foundCity += 1;
      case StartUnitProductionCommand():
        startUnit += 1;
      case StartBuildingCommand():
        startBuilding += 1;
      case StartCityProjectCommand():
        startProject += 1;
      case StartWonderCommand():
        startWonder += 1;
      case SetCitySpecializationCommand():
        break;
      case MoveUnitCommand():
        move += 1;
      case MoveMerchantToCityCommand():
        move += 1;
      case AttackHexCommand():
        attack += 1;
      case _:
        break;
    }
  }
}
