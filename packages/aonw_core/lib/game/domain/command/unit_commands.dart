part of 'game_command.dart';

/// A player-authored unit command routed through the canonical game engine.
sealed class UnitDomainCommand extends DomainCommand {
  const UnitDomainCommand();

  String get unitId;
}

/// A unit command whose value is fully identified by its type and [unitId].
sealed class UnitIdDomainCommand extends UnitDomainCommand {
  const UnitIdDomainCommand(this.unitId);

  @override
  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is UnitIdDomainCommand &&
      other.runtimeType == runtimeType &&
      other.unitId == unitId;

  @override
  int get hashCode => Object.hash(runtimeType, unitId);
}

/// A persistent unit mode whose target is selected by canonical rules.
sealed class AutomatedUnitCommand extends UnitIdDomainCommand {
  const AutomatedUnitCommand(super.unitId);
}

/// Player issued a move order for [unitId] toward ([targetCol], [targetRow]).
final class MoveUnitCommand extends UnitDomainCommand {
  const MoveUnitCommand(this.unitId, this.targetCol, this.targetRow);

  @override
  final String unitId;
  final int targetCol;
  final int targetRow;

  @override
  bool operator ==(Object other) =>
      other is MoveUnitCommand &&
      other.unitId == unitId &&
      other.targetCol == targetCol &&
      other.targetRow == targetRow;

  @override
  int get hashCode =>
      Object.hash(MoveUnitCommand, unitId, targetCol, targetRow);
}

/// Cancels the current action state owned by [unitId].
final class CancelUnitActionCommand extends UnitIdDomainCommand {
  const CancelUnitActionCommand(super.unitId);
}

/// Puts [unitId] aside for the rest of the current turn.
final class SkipUnitTurnCommand extends UnitIdDomainCommand {
  const SkipUnitTurnCommand(super.unitId);
}

/// Puts [unitId] into healing posture and spends its movement until recovered.
final class FortifyUnitCommand extends UnitIdDomainCommand {
  const FortifyUnitCommand(super.unitId);
}

/// Starts automatic exploration for [unitId] until it is cancelled.
final class AutoExploreUnitCommand extends AutomatedUnitCommand {
  const AutoExploreUnitCommand(super.unitId);
}

/// Opens the city picker for assigning a merchant trade route.
final class StartMerchantTradeRouteSelectionCommand extends GameIntent {
  const StartMerchantTradeRouteSelectionCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is StartMerchantTradeRouteSelectionCommand &&
      other.unitId == unitId;

  @override
  int get hashCode =>
      Object.hash(StartMerchantTradeRouteSelectionCommand, unitId);
}

/// Closes the city picker for assigning a merchant trade route.
final class CancelMerchantTradeRouteSelectionCommand extends GameIntent {
  const CancelMerchantTradeRouteSelectionCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is CancelMerchantTradeRouteSelectionCommand &&
      other.unitId == unitId;

  @override
  int get hashCode =>
      Object.hash(CancelMerchantTradeRouteSelectionCommand, unitId);
}

/// Assigns [unitId] to automatically trade with [destinationCityId].
final class AssignMerchantTradeRouteCommand extends UnitDomainCommand {
  const AssignMerchantTradeRouteCommand(this.unitId, this.destinationCityId);

  @override
  final String unitId;
  final String destinationCityId;

  @override
  bool operator ==(Object other) =>
      other is AssignMerchantTradeRouteCommand &&
      other.unitId == unitId &&
      other.destinationCityId == destinationCityId;

  @override
  int get hashCode =>
      Object.hash(AssignMerchantTradeRouteCommand, unitId, destinationCityId);
}

/// Opens the city picker for moving a merchant into one of the player's cities.
final class StartMerchantMoveToCitySelectionCommand extends GameIntent {
  const StartMerchantMoveToCitySelectionCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is StartMerchantMoveToCitySelectionCommand &&
      other.unitId == unitId;

  @override
  int get hashCode =>
      Object.hash(StartMerchantMoveToCitySelectionCommand, unitId);
}

/// Closes the city picker for moving a merchant into one of the player's cities.
final class CancelMerchantMoveToCitySelectionCommand extends GameIntent {
  const CancelMerchantMoveToCitySelectionCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is CancelMerchantMoveToCitySelectionCommand &&
      other.unitId == unitId;

  @override
  int get hashCode =>
      Object.hash(CancelMerchantMoveToCitySelectionCommand, unitId);
}

/// Queues [unitId] to travel into [destinationCityId] without creating a trade route.
final class MoveMerchantToCityCommand extends UnitDomainCommand {
  const MoveMerchantToCityCommand(this.unitId, this.destinationCityId);

  @override
  final String unitId;
  final String destinationCityId;

  @override
  bool operator ==(Object other) =>
      other is MoveMerchantToCityCommand &&
      other.unitId == unitId &&
      other.destinationCityId == destinationCityId;

  @override
  int get hashCode =>
      Object.hash(MoveMerchantToCityCommand, unitId, destinationCityId);
}

/// Toggles whether the move-targeting mode is active.
final class ToggleMoveTargetingCommand extends GameIntent {
  const ToggleMoveTargetingCommand();

  @override
  bool operator ==(Object other) => other is ToggleMoveTargetingCommand;

  @override
  int get hashCode => (ToggleMoveTargetingCommand).hashCode;
}

/// Player detaches a troop of [troopType] from unit [unitId].
final class DetachTroopCommand extends UnitDomainCommand {
  const DetachTroopCommand(this.unitId, this.troopType);

  @override
  final String unitId;
  final TroopType troopType;

  @override
  bool operator ==(Object other) =>
      other is DetachTroopCommand &&
      other.unitId == unitId &&
      other.troopType == troopType;

  @override
  int get hashCode => Object.hash(DetachTroopCommand, unitId, troopType);
}
