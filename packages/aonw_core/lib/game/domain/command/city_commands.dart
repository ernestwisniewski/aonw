part of 'game_command.dart';

/// Player founds a city using the settler unit [founderId].
final class FoundCityCommand extends GameCommand {
  const FoundCityCommand(this.founderId, {this.controlledHexes = const []});

  final String founderId;
  final List<CityHex> controlledHexes;

  @override
  bool operator ==(Object other) =>
      other is FoundCityCommand &&
      other.founderId == founderId &&
      _sameControlledHexes(other.controlledHexes, controlledHexes);

  @override
  int get hashCode =>
      Object.hash(FoundCityCommand, founderId, Object.hashAll(controlledHexes));

  static bool _sameControlledHexes(List<CityHex> left, List<CityHex> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }
}

/// Player starts building [buildingType] in city [cityId].
final class StartBuildingCommand extends GameCommand {
  const StartBuildingCommand(this.cityId, this.buildingType);

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
final class StartUnitProductionCommand extends GameCommand {
  const StartUnitProductionCommand(this.cityId, this.unitType);

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
final class StartCityProjectCommand extends GameCommand {
  const StartCityProjectCommand(this.cityId, this.projectType);

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

/// Player sets the long-term specialization for city [cityId].
final class SetCitySpecializationCommand extends GameCommand {
  const SetCitySpecializationCommand(this.cityId, this.specialization);

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
final class RushProductionCommand extends GameCommand {
  const RushProductionCommand(this.cityId);

  final String cityId;

  @override
  bool operator ==(Object other) =>
      other is RushProductionCommand && other.cityId == cityId;

  @override
  int get hashCode => Object.hash(RushProductionCommand, cityId);
}

/// Player begins the city-founding flow.
final class StartCityFoundingCommand extends GameCommand {
  const StartCityFoundingCommand();

  @override
  bool operator ==(Object other) => other is StartCityFoundingCommand;

  @override
  int get hashCode => (StartCityFoundingCommand).hashCode;
}

/// Player cancels the city-founding flow.
final class CancelCityFoundingCommand extends GameCommand {
  const CancelCityFoundingCommand();

  @override
  bool operator ==(Object other) => other is CancelCityFoundingCommand;

  @override
  int get hashCode => (CancelCityFoundingCommand).hashCode;
}

/// Player begins choosing manually worked hexes for a city on the map.
final class StartCityWorkedHexSelectionCommand extends GameCommand {
  const StartCityWorkedHexSelectionCommand(this.cityId);

  final String cityId;

  @override
  bool operator ==(Object other) =>
      other is StartCityWorkedHexSelectionCommand && other.cityId == cityId;

  @override
  int get hashCode => Object.hash(StartCityWorkedHexSelectionCommand, cityId);
}

/// Player cancels manual worked-hex selection for a city.
final class CancelCityWorkedHexSelectionCommand extends GameCommand {
  const CancelCityWorkedHexSelectionCommand(this.cityId);

  final String cityId;

  @override
  bool operator ==(Object other) =>
      other is CancelCityWorkedHexSelectionCommand && other.cityId == cityId;

  @override
  int get hashCode => Object.hash(CancelCityWorkedHexSelectionCommand, cityId);
}

/// Player toggles whether a city manually works the hex at ([col], [row]).
final class ToggleWorkedHexCommand extends GameCommand {
  const ToggleWorkedHexCommand(this.cityId, this.col, this.row);

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
final class StartCityExpansionSelectionCommand extends GameCommand {
  const StartCityExpansionSelectionCommand(this.cityId);

  final String cityId;

  @override
  bool operator ==(Object other) =>
      other is StartCityExpansionSelectionCommand && other.cityId == cityId;

  @override
  int get hashCode => Object.hash(StartCityExpansionSelectionCommand, cityId);
}

/// Player cancels next-expansion selection for a city.
final class CancelCityExpansionSelectionCommand extends GameCommand {
  const CancelCityExpansionSelectionCommand(this.cityId);

  final String cityId;

  @override
  bool operator ==(Object other) =>
      other is CancelCityExpansionSelectionCommand && other.cityId == cityId;

  @override
  int get hashCode => Object.hash(CancelCityExpansionSelectionCommand, cityId);
}

/// Player chooses which hex a city should claim on its next territory growth.
final class SelectCityExpansionHexCommand extends GameCommand {
  const SelectCityExpansionHexCommand(this.cityId, this.col, this.row);

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
