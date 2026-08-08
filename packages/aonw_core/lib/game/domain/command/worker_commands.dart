part of 'game_command.dart';

/// Shared presentation boundary for the worker improvement picker.
abstract interface class WorkerInteractionCommand {}

/// Player begins worker action selection for [unitId].
final class StartWorkerActionSelectionCommand extends GameIntent
    implements WorkerInteractionCommand {
  const StartWorkerActionSelectionCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is StartWorkerActionSelectionCommand && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(StartWorkerActionSelectionCommand, unitId);
}

/// Player chooses the intended worker improvement type.
final class ChooseWorkerImprovementIntent extends GameIntent
    implements WorkerInteractionCommand {
  const ChooseWorkerImprovementIntent(this.unitId, this.improvementType);

  final String unitId;
  final FieldImprovementType improvementType;

  @override
  bool operator ==(Object other) =>
      other is ChooseWorkerImprovementIntent &&
      other.unitId == unitId &&
      other.improvementType == improvementType;

  @override
  int get hashCode =>
      Object.hash(ChooseWorkerImprovementIntent, unitId, improvementType);
}

/// Client confirmation of the worker improvement selected in the UI.
final class ConfirmWorkerImprovementIntent extends GameIntent
    implements WorkerInteractionCommand {
  const ConfirmWorkerImprovementIntent(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is ConfirmWorkerImprovementIntent && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(ConfirmWorkerImprovementIntent, unitId);
}

/// Authoritative request to begin a specific worker improvement.
final class SelectWorkerImprovementCommand extends UnitDomainCommand {
  const SelectWorkerImprovementCommand(this.unitId, this.improvementType);

  @override
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
final class ConfirmWorkerImprovementCommand extends UnitDomainCommand {
  const ConfirmWorkerImprovementCommand(this.unitId, {this.improvementType});

  @override
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
final class CancelWorkerActionSelectionCommand extends GameIntent
    implements WorkerInteractionCommand {
  const CancelWorkerActionSelectionCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is CancelWorkerActionSelectionCommand && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(CancelWorkerActionSelectionCommand, unitId);
}

/// Player cancels the worker's active improvement job.
final class CancelWorkerJobCommand extends UnitDomainCommand {
  const CancelWorkerJobCommand(this.unitId);

  @override
  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is CancelWorkerJobCommand && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(CancelWorkerJobCommand, unitId);
}

/// Player assigns the worker to the current improved city tile for bonus yield.
final class AssignWorkerToHexCommand extends UnitDomainCommand {
  const AssignWorkerToHexCommand(this.unitId);

  @override
  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is AssignWorkerToHexCommand && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(AssignWorkerToHexCommand, unitId);
}

/// Player detaches the worker from its active tile assignment.
final class CancelWorkerAssignmentCommand extends UnitIdDomainCommand {
  const CancelWorkerAssignmentCommand(super.unitId);
}

/// Player delegates target selection, travel, and work to the worker.
final class AutomateWorkerCommand extends AutomatedUnitCommand {
  const AutomateWorkerCommand(super.unitId);
}
