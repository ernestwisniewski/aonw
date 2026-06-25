part of 'game_command.dart';

/// Player chooses [technologyId] as the active research target.
final class SelectTechnologyCommand extends GameCommand {
  const SelectTechnologyCommand(this.playerId, this.technologyId);

  final String playerId;
  final TechnologyId technologyId;

  @override
  bool operator ==(Object other) =>
      other is SelectTechnologyCommand &&
      other.playerId == playerId &&
      other.technologyId == technologyId;

  @override
  int get hashCode =>
      Object.hash(SelectTechnologyCommand, playerId, technologyId);
}

/// Player dismisses research selection without choosing a technology.
final class CancelResearchSelectionCommand extends GameCommand {
  const CancelResearchSelectionCommand(this.playerId);

  final String playerId;

  @override
  bool operator ==(Object other) =>
      other is CancelResearchSelectionCommand && other.playerId == playerId;

  @override
  int get hashCode => Object.hash(CancelResearchSelectionCommand, playerId);
}
