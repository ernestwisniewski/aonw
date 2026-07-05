part of 'hud_overlay_frame.dart';

Player? _activePlayer(GameSave gameSave, String activePlayerId) {
  return gameSave.playerById(activePlayerId);
}

bool _canUseUnitTurnAction(GameUnit unit) {
  return unit.movementPoints > 0 && !unit.isWorking && !unit.isFortified;
}
