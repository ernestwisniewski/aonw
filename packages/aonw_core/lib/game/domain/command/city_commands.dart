part of 'game_command.dart';

/// A player-authored command targeting one city.
sealed class CityTargetDomainCommand extends DomainCommand {
  const CityTargetDomainCommand();

  String get cityId;
}

/// Player founds a city using the settler unit [founderId].
final class FoundCityCommand extends UnitDomainCommand {
  FoundCityCommand(this.founderId, {required List<CityHex> controlledHexes})
    : controlledHexes = List<CityHex>.unmodifiable(controlledHexes);

  final String founderId;
  @override
  String get unitId => founderId;
  final List<CityHex> controlledHexes;

  @override
  bool operator ==(Object other) =>
      other is FoundCityCommand &&
      other.founderId == founderId &&
      listEquals(other.controlledHexes, controlledHexes);

  @override
  int get hashCode =>
      Object.hash(FoundCityCommand, founderId, Object.hashAll(controlledHexes));
}

/// Player starts building [buildingType] in city [cityId].
final class StartBuildingCommand extends CityTargetDomainCommand {
  const StartBuildingCommand(this.cityId, this.buildingType);

  @override
  final String cityId;
  final CityBuildingType buildingType;

  @override
  bool operator ==(Object other) =>
      other is StartBuildingCommand &&
      other.cityId == cityId &&
      other.buildingType == buildingType;

  @override
  int get hashCode => Object.hash(StartBuildingCommand, cityId, buildingType);
}

/// Player starts producing [unitType] in city [cityId].
final class StartUnitProductionCommand extends CityTargetDomainCommand {
  const StartUnitProductionCommand(this.cityId, this.unitType);

  @override
  final String cityId;
  final GameUnitType unitType;

  @override
  bool operator ==(Object other) =>
      other is StartUnitProductionCommand &&
      other.cityId == cityId &&
      other.unitType == unitType;

  @override
  int get hashCode => Object.hash(StartUnitProductionCommand, cityId, unitType);
}

/// Player starts a continuous [projectType] in city [cityId].
final class StartCityProjectCommand extends CityTargetDomainCommand {
  const StartCityProjectCommand(this.cityId, this.projectType);

  @override
  final String cityId;
  final CityProjectType projectType;

  @override
  bool operator ==(Object other) =>
      other is StartCityProjectCommand &&
      other.cityId == cityId &&
      other.projectType == projectType;

  @override
  int get hashCode => Object.hash(StartCityProjectCommand, cityId, projectType);
}

/// Player starts building [wonderType] in city [cityId].
final class StartWonderCommand extends CityTargetDomainCommand {
  const StartWonderCommand(this.cityId, this.wonderType);

  @override
  final String cityId;
  final WonderType wonderType;

  @override
  bool operator ==(Object other) =>
      other is StartWonderCommand &&
      other.cityId == cityId &&
      other.wonderType == wonderType;

  @override
  int get hashCode => Object.hash(StartWonderCommand, cityId, wonderType);
}

/// Player sets the long-term specialization for city [cityId].
final class SetCitySpecializationCommand extends CityTargetDomainCommand {
  const SetCitySpecializationCommand(this.cityId, this.specialization);

  @override
  final String cityId;
  final CitySpecializationType specialization;

  @override
  bool operator ==(Object other) =>
      other is SetCitySpecializationCommand &&
      other.cityId == cityId &&
      other.specialization == specialization;

  @override
  int get hashCode =>
      Object.hash(SetCitySpecializationCommand, cityId, specialization);
}

/// Player spends gold to add one turn of production to [cityId]'s queue.
final class RushProductionCommand extends CityTargetDomainCommand {
  const RushProductionCommand(this.cityId);

  @override
  final String cityId;

  @override
  bool operator ==(Object other) =>
      other is RushProductionCommand && other.cityId == cityId;

  @override
  int get hashCode => Object.hash(RushProductionCommand, cityId);
}

/// Player begins the city-founding flow.
final class StartCityFoundingCommand extends GameIntent {
  const StartCityFoundingCommand();

  @override
  bool operator ==(Object other) => other is StartCityFoundingCommand;

  @override
  int get hashCode => (StartCityFoundingCommand).hashCode;
}

/// Player cancels the city-founding flow.
final class CancelCityFoundingCommand extends GameIntent {
  const CancelCityFoundingCommand();

  @override
  bool operator ==(Object other) => other is CancelCityFoundingCommand;

  @override
  int get hashCode => (CancelCityFoundingCommand).hashCode;
}

/// Player begins choosing manually worked hexes for a city on the map.
final class StartCityWorkedHexSelectionCommand extends GameIntent {
  const StartCityWorkedHexSelectionCommand(this.cityId);

  final String cityId;

  @override
  bool operator ==(Object other) =>
      other is StartCityWorkedHexSelectionCommand && other.cityId == cityId;

  @override
  int get hashCode => Object.hash(StartCityWorkedHexSelectionCommand, cityId);
}

/// Player cancels manual worked-hex selection for a city.
final class CancelCityWorkedHexSelectionCommand extends GameIntent {
  const CancelCityWorkedHexSelectionCommand(this.cityId);

  final String cityId;

  @override
  bool operator ==(Object other) =>
      other is CancelCityWorkedHexSelectionCommand && other.cityId == cityId;

  @override
  int get hashCode => Object.hash(CancelCityWorkedHexSelectionCommand, cityId);
}

/// Player toggles whether a city manually works the hex at ([col], [row]).
final class ToggleWorkedHexCommand extends CityTargetDomainCommand {
  const ToggleWorkedHexCommand(this.cityId, this.col, this.row);

  @override
  final String cityId;
  final int col;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is ToggleWorkedHexCommand &&
      other.cityId == cityId &&
      other.col == col &&
      other.row == row;

  @override
  int get hashCode => Object.hash(ToggleWorkedHexCommand, cityId, col, row);
}

/// Player begins choosing the next expansion hex for a city on the map.
final class StartCityExpansionSelectionCommand extends GameIntent {
  const StartCityExpansionSelectionCommand(this.cityId);

  final String cityId;

  @override
  bool operator ==(Object other) =>
      other is StartCityExpansionSelectionCommand && other.cityId == cityId;

  @override
  int get hashCode => Object.hash(StartCityExpansionSelectionCommand, cityId);
}

/// Player cancels next-expansion selection for a city.
final class CancelCityExpansionSelectionCommand extends GameIntent {
  const CancelCityExpansionSelectionCommand(this.cityId);

  final String cityId;

  @override
  bool operator ==(Object other) =>
      other is CancelCityExpansionSelectionCommand && other.cityId == cityId;

  @override
  int get hashCode => Object.hash(CancelCityExpansionSelectionCommand, cityId);
}

/// Player chooses which hex a city should claim on its next territory growth.
final class SelectCityExpansionHexCommand extends CityTargetDomainCommand {
  const SelectCityExpansionHexCommand(this.cityId, this.col, this.row);

  @override
  final String cityId;
  final int col;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is SelectCityExpansionHexCommand &&
      other.cityId == cityId &&
      other.col == col &&
      other.row == row;

  @override
  int get hashCode =>
      Object.hash(SelectCityExpansionHexCommand, cityId, col, row);
}
