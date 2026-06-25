part of 'game_command.dart';

/// Player issued a move order for [unitId] toward ([targetCol], [targetRow]).
final class MoveUnitCommand extends GameCommand {
  const MoveUnitCommand(this.unitId, this.targetCol, this.targetRow);

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
final class CancelUnitActionCommand extends GameCommand {
  const CancelUnitActionCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is CancelUnitActionCommand && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(CancelUnitActionCommand, unitId);
}

/// Puts [unitId] aside for the rest of the current turn.
final class SkipUnitTurnCommand extends GameCommand {
  const SkipUnitTurnCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is SkipUnitTurnCommand && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(SkipUnitTurnCommand, unitId);
}

/// Puts [unitId] into healing posture and spends its movement until recovered.
final class FortifyUnitCommand extends GameCommand {
  const FortifyUnitCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is FortifyUnitCommand && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(FortifyUnitCommand, unitId);
}

/// Starts automatic exploration for [unitId] until it is cancelled.
final class AutoExploreUnitCommand extends GameCommand {
  const AutoExploreUnitCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is AutoExploreUnitCommand && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(AutoExploreUnitCommand, unitId);
}

/// Opens the city picker for assigning a merchant trade route.
final class StartMerchantTradeRouteSelectionCommand extends GameCommand {
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
final class CancelMerchantTradeRouteSelectionCommand extends GameCommand {
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
final class AssignMerchantTradeRouteCommand extends GameCommand {
  const AssignMerchantTradeRouteCommand(this.unitId, this.destinationCityId);

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
final class StartMerchantMoveToCitySelectionCommand extends GameCommand {
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
final class CancelMerchantMoveToCitySelectionCommand extends GameCommand {
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
final class MoveMerchantToCityCommand extends GameCommand {
  const MoveMerchantToCityCommand(this.unitId, this.destinationCityId);

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

/// Resets unit movement for a new turn and advances queued paths.
final class ResetUnitMovementCommand extends GameCommand {
  const ResetUnitMovementCommand({this.playerId});

  final String? playerId;

  @override
  bool operator ==(Object other) =>
      other is ResetUnitMovementCommand && other.playerId == playerId;

  @override
  int get hashCode => Object.hash(ResetUnitMovementCommand, playerId);
}

/// Toggles whether the move-targeting mode is active.
final class ToggleMoveTargetingCommand extends GameCommand {
  const ToggleMoveTargetingCommand();

  @override
  bool operator ==(Object other) => other is ToggleMoveTargetingCommand;

  @override
  int get hashCode => (ToggleMoveTargetingCommand).hashCode;
}

/// Player detaches a troop of [troopType] from unit [unitId].
final class DetachTroopCommand extends GameCommand {
  const DetachTroopCommand(this.unitId, this.troopType);

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
