part of 'game_command.dart';

/// Player begins commander-merge selection for [commanderUnitId].
final class StartCommanderMergeSelectionCommand extends GameCommand {
  const StartCommanderMergeSelectionCommand(this.commanderUnitId);

  final String commanderUnitId;

  @override
  bool operator ==(Object other) =>
      other is StartCommanderMergeSelectionCommand &&
      other.commanderUnitId == commanderUnitId;

  @override
  int get hashCode =>
      Object.hash(StartCommanderMergeSelectionCommand, commanderUnitId);
}

/// Player cancels commander-merge selection for [commanderUnitId].
final class CancelCommanderMergeSelectionCommand extends GameCommand {
  const CancelCommanderMergeSelectionCommand(this.commanderUnitId);

  final String commanderUnitId;

  @override
  bool operator ==(Object other) =>
      other is CancelCommanderMergeSelectionCommand &&
      other.commanderUnitId == commanderUnitId;

  @override
  int get hashCode =>
      Object.hash(CancelCommanderMergeSelectionCommand, commanderUnitId);
}
