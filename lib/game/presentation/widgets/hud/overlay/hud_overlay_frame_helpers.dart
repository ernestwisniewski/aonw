part of 'hud_overlay_frame.dart';

Player? _activePlayer(GameSave gameSave, String activePlayerId) =>
    gameSave.playerById(activePlayerId);

bool _canUseUnitTurnAction(GameUnit unit) =>
    unit.movementPoints > 0 && !unit.isWorking && !unit.isFortified;

bool _hasOwnedCity(GameClientState? gameState, String activePlayerId) =>
    gameState?.cities.any((city) => city.ownerPlayerId == activePlayerId) ??
    false;

bool _canStartMoveTargeting(GameUnit? unit) =>
    unit != null && UnitManualMovementRules.canStartTargeting(unit);

String? _moveTargetingBlockedReason(GameUnit? unit, AppLocalizations l10n) {
  if (unit == null) return null;
  if (unit.queuedPath != null) {
    return l10n.selectionActionCancelCurrentMoveFirst;
  }
  if (unit.isWorking) return l10n.selectionActionUnitWorking;
  if (UnitManualMovementRules.availableMovementPoints(unit) <= 0) {
    return l10n.selectionActionNoMovement;
  }
  return null;
}
