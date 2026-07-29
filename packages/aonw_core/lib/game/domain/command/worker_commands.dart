part of 'game_command.dart';

/// Player begins worker action selection for [unitId].
final class StartWorkerActionSelectionCommand extends GameIntent {
  const StartWorkerActionSelectionCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is StartWorkerActionSelectionCommand && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(StartWorkerActionSelectionCommand, unitId);
}

/// Player chooses the intended worker improvement type.
final class SelectWorkerImprovementCommand extends DomainCommand {
  const SelectWorkerImprovementCommand(this.unitId, this.improvementType);

  final String unitId;
  final FieldImprovementType improvementType;

  @override
  bool operator ==(Object other) =>
      other is SelectWorkerImprovementCommand &&
      other.unitId == unitId &&
      other.improvementType == improvementType;

  @override
  int get hashCode =>
      Object.hash(SelectWorkerImprovementCommand, unitId, improvementType);
}

/// Player confirms the selected worker improvement on the current tile.
final class ConfirmWorkerImprovementCommand extends DomainCommand {
  const ConfirmWorkerImprovementCommand(this.unitId, {this.improvementType});

  final String unitId;
  final FieldImprovementType? improvementType;

  @override
  bool operator ==(Object other) =>
      other is ConfirmWorkerImprovementCommand &&
      other.unitId == unitId &&
      other.improvementType == improvementType;

  @override
  int get hashCode =>
      Object.hash(ConfirmWorkerImprovementCommand, unitId, improvementType);
}

/// Player cancels worker action selection for [unitId].
final class CancelWorkerActionSelectionCommand extends GameIntent {
  const CancelWorkerActionSelectionCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is CancelWorkerActionSelectionCommand && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(CancelWorkerActionSelectionCommand, unitId);
}

/// Player cancels the worker's active improvement job.
final class CancelWorkerJobCommand extends DomainCommand {
  const CancelWorkerJobCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is CancelWorkerJobCommand && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(CancelWorkerJobCommand, unitId);
}

/// Player assigns the worker to the current improved city tile for bonus yield.
final class AssignWorkerToHexCommand extends DomainCommand {
  const AssignWorkerToHexCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is AssignWorkerToHexCommand && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(AssignWorkerToHexCommand, unitId);
}

/// Player detaches the worker from its active tile assignment.
final class CancelWorkerAssignmentCommand extends DomainCommand {
  const CancelWorkerAssignmentCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is CancelWorkerAssignmentCommand && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(CancelWorkerAssignmentCommand, unitId);
}
