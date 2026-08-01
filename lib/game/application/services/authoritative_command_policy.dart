import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/runtime.dart';

abstract final class AuthoritativeCommandPolicy {
  static DomainCommand? authoritativeCommandForClientIntent(
    GameState state,
    GameIntent intent,
    GameCommandContext context,
  ) {
    if (intent is TileTappedCommand) {
      return _authoritativeCommandForTileTap(state, intent, context);
    }
    if (intent is CityTappedCommand) {
      return _authoritativeCommandForCityTap(state, intent, context);
    }
    if (intent case ConfirmWorkerImprovementIntent(:final unitId)) {
      final pending = state.pendingAction;
      if (pending is PendingWorkerActionSelection &&
          pending.unitId == unitId &&
          pending.improvementType != null) {
        return ConfirmWorkerImprovementCommand(
          unitId,
          improvementType: pending.improvementType,
        );
      }
    }
    return null;
  }

  static DomainCommand? _authoritativeCommandForCityTap(
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

  static DomainCommand? _authoritativeCommandForTileTap(
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
    if (!sameTarget) return null;

    return MoveUnitCommand(selected.id, preview.targetCol, preview.targetRow);
  }
}
