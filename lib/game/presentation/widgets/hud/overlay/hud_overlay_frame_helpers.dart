part of 'hud_overlay_frame.dart';

Player? _activePlayer(GameSave gameSave, String activePlayerId) =>
    gameSave.playerById(activePlayerId);

bool _canUseUnitTurnAction(GameUnit unit) =>
    unit.movementPoints > 0 && !unit.isWorking && !unit.isFortified;
