part of 'game_command.dart';

/// Player tapped a tile at [col], [row].
final class TileTappedCommand extends GameIntent {
  const TileTappedCommand(this.col, this.row);

  final int col;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is TileTappedCommand && other.col == col && other.row == row;

  @override
  int get hashCode => Object.hash(TileTappedCommand, col, row);
}

/// Player tapped a city marker.
final class CityTappedCommand extends GameIntent {
  const CityTappedCommand(this.cityId);

  final String cityId;

  @override
  bool operator ==(Object other) =>
      other is CityTappedCommand && other.cityId == cityId;

  @override
  int get hashCode => Object.hash(CityTappedCommand, cityId);
}

/// Selects the tile at ([col], [row]).
final class SelectTileCommand extends GameIntent {
  const SelectTileCommand(this.col, this.row);

  final int col;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is SelectTileCommand && other.col == col && other.row == row;

  @override
  int get hashCode => Object.hash(SelectTileCommand, col, row);
}

/// Selects the unit with [unitId].
final class SelectUnitCommand extends GameIntent {
  const SelectUnitCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is SelectUnitCommand && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(SelectUnitCommand, unitId);
}

/// Selects the city with [cityId].
final class SelectCityCommand extends GameIntent {
  const SelectCityCommand(this.cityId);

  final String cityId;

  @override
  bool operator ==(Object other) =>
      other is SelectCityCommand && other.cityId == cityId;

  @override
  int get hashCode => Object.hash(SelectCityCommand, cityId);
}

/// Selects the field improvement occupying ([col], [row]).
final class SelectFieldImprovementCommand extends GameIntent {
  const SelectFieldImprovementCommand(this.col, this.row);

  final int col;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is SelectFieldImprovementCommand &&
      other.col == col &&
      other.row == row;

  @override
  int get hashCode => Object.hash(SelectFieldImprovementCommand, col, row);
}

/// Focuses the next pending action for [playerId].
final class FocusNextPendingActionCommand extends GameIntent {
  const FocusNextPendingActionCommand(
    this.playerId, {
    this.preferredObjectiveAdvice,
    this.actionIndex,
    this.actionStep = 1,
  });

  final String playerId;
  final GameObjectiveAdvice? preferredObjectiveAdvice;
  final int? actionIndex;
  final int actionStep;

  @override
  bool operator ==(Object other) =>
      other is FocusNextPendingActionCommand &&
      other.playerId == playerId &&
      other.preferredObjectiveAdvice == preferredObjectiveAdvice &&
      other.actionIndex == actionIndex &&
      other.actionStep == actionStep;

  @override
  int get hashCode => Object.hash(
    FocusNextPendingActionCommand,
    playerId,
    preferredObjectiveAdvice,
    actionIndex,
    actionStep,
  );
}

/// Focuses the first actionable turn-start target for [playerId].
final class FocusTurnStartActionCommand extends GameIntent {
  const FocusTurnStartActionCommand(this.playerId);

  final String playerId;

  @override
  bool operator ==(Object other) =>
      other is FocusTurnStartActionCommand && other.playerId == playerId;

  @override
  int get hashCode => Object.hash(FocusTurnStartActionCommand, playerId);
}
