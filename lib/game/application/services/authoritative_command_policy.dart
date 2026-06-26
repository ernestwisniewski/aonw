import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/runtime.dart';

abstract final class AuthoritativeCommandPolicy {
  static bool shouldSendToServer(GameCommand command) {
    return !isClientOnly(command);
  }

  static bool shouldLogForReplay(GameCommand command) {
    return shouldSendToServer(command);
  }

  static bool isClientOnly(GameCommand command) {
    return switch (command) {
      SetActivePlayerCommand() ||
      TileTappedCommand() ||
      CityTappedCommand() ||
      ToggleMoveTargetingCommand() ||
      StartCityFoundingCommand() ||
      CancelCityFoundingCommand() ||
      StartCityWorkedHexSelectionCommand() ||
      CancelCityWorkedHexSelectionCommand() ||
      StartCityExpansionSelectionCommand() ||
      CancelCityExpansionSelectionCommand() ||
      StartWorkerActionSelectionCommand() ||
      CancelWorkerActionSelectionCommand() ||
      StartMerchantTradeRouteSelectionCommand() ||
      CancelMerchantTradeRouteSelectionCommand() ||
      StartMerchantMoveToCitySelectionCommand() ||
      CancelMerchantMoveToCitySelectionCommand() ||
      CancelResearchSelectionCommand() ||
      StartAttackTargetingCommand() ||
      CancelAttackTargetingCommand() ||
      StartCommanderMergeSelectionCommand() ||
      CancelCommanderMergeSelectionCommand() ||
      SelectTileCommand() ||
      SelectUnitCommand() ||
      SelectCityCommand() ||
      FocusNextPendingActionCommand() ||
      FocusTurnStartActionCommand() => true,
      _ => false,
    };
  }

  static GameCommand? authoritativeCommandForClientIntent(
    GameState state,
    GameCommand command,
    GameCommandContext context,
  ) {
    if (command is TileTappedCommand) {
      return _authoritativeCommandForTileTap(state, command, context);
    }
    if (command is CityTappedCommand) {
      return _authoritativeCommandForCityTap(state, command, context);
    }
    return null;
  }

  static GameCommand? _authoritativeCommandForCityTap(
    GameState state,
    CityTappedCommand command,
    GameCommandContext context,
  ) {
    final pendingAction = state.pendingAction;
    if (pendingAction == null ||
        (pendingAction is! PendingMerchantTradeRouteSelection &&
            pendingAction is! PendingMerchantMoveToCitySelection)) {
      return null;
    }
    final selected = state.selectedUnit;
    if (selected == null ||
        !pendingAction.ownsUnit(selected.id) ||
        !context.canControlUnit(state, selected)) {
      return null;
    }
    if (pendingAction is PendingMerchantMoveToCitySelection) {
      return MoveMerchantToCityCommand(selected.id, command.cityId);
    }
    return AssignMerchantTradeRouteCommand(selected.id, command.cityId);
  }

  static GameCommand? _authoritativeCommandForTileTap(
    GameState state,
    TileTappedCommand command,
    GameCommandContext context,
  ) {
    final pendingAction = state.pendingAction;
    if (pendingAction is PendingCityWorkedHexSelection) {
      return ToggleWorkedHexCommand(
        pendingAction.cityId,
        command.col,
        command.row,
      );
    }
    if (pendingAction is PendingCityExpansionSelection) {
      return SelectCityExpansionHexCommand(
        pendingAction.cityId,
        command.col,
        command.row,
      );
    }
    if (!state.moveCommandActive) return null;

    final selected = state.selectedUnit;
    if (selected == null || !context.canControlUnit(state, selected)) {
      return null;
    }

    final preview = state.movePreview;
    if (preview == null || preview.unitId != selected.id) return null;
    final sameTarget =
        preview.targetCol == command.col && preview.targetRow == command.row;
    final confirmsReachableStep = preview.isStepUnreachableThisTurn(
      command.col,
      command.row,
    );
    if (!sameTarget && !confirmsReachableStep) return null;

    return MoveUnitCommand(selected.id, preview.targetCol, preview.targetRow);
  }
}
