import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_control_frame.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/runtime.dart';

final class GamepadCommandMapper {
  const GamepadCommandMapper();

  List<GameIntent> commandsForFrame({
    required GamepadControlFrame frame,
    required GameClientState state,
    WorldTile? currentTile,
  }) {
    final commands = <GameIntent>[];
    final cancelCommand = frame.cancelPressed ? commandForCancel(state) : null;
    if (cancelCommand != null) commands.add(cancelCommand);
    if (frame.moveModePressed && canToggleMoveMode(state)) {
      commands.add(const ToggleMoveTargetingCommand());
    }

    final activePlayerId = state.activePlayerId;
    if (activePlayerId.isNotEmpty) {
      if (frame.focusPreviousPressed) {
        commands.add(
          FocusNextPendingActionCommand(activePlayerId, actionStep: -1),
        );
      }
      if (frame.focusNextPressed) {
        commands.add(FocusNextPendingActionCommand(activePlayerId));
      }
    }

    if (frame.confirmPressed && currentTile != null) {
      commands.add(TileTappedCommand(currentTile.col, currentTile.row));
    }
    return commands;
  }

  GameIntent? commandForCancel(GameClientState state) {
    if (state.cityFoundingDraft != null) {
      return const CancelCityFoundingCommand();
    }
    final pendingCancel = switch (state.pendingAction) {
      PendingResearchSelection(:final ownerPlayerId) =>
        CancelResearchSelectionCommand(ownerPlayerId),
      PendingCityWorkedHexSelection(:final cityId) =>
        CancelCityWorkedHexSelectionCommand(cityId),
      PendingCityExpansionSelection(:final cityId) =>
        CancelCityExpansionSelectionCommand(cityId),
      PendingWorkerActionSelection(:final unitId) =>
        CancelWorkerActionSelectionCommand(unitId),
      PendingMerchantTradeRouteSelection(:final unitId) =>
        CancelMerchantTradeRouteSelectionCommand(unitId),
      PendingMerchantMoveToCitySelection(:final unitId) =>
        CancelMerchantMoveToCitySelectionCommand(unitId),
      PendingAttackTargeting(:final attackerUnitId) =>
        CancelAttackTargetingCommand(attackerUnitId),
      PendingCommanderMergeSelection(:final commanderUnitId) =>
        CancelCommanderMergeSelectionCommand(commanderUnitId),
      _ => null,
    };
    if (pendingCancel != null) return pendingCancel;
    if (state.moveCommandActive) return const ToggleMoveTargetingCommand();
    return null;
  }

  bool canToggleMoveMode(GameClientState state) {
    return switch (state.interactionMode) {
      GameInteractionMode.standard || GameInteractionMode.moveTargeting => true,
      _ => false,
    };
  }
}
