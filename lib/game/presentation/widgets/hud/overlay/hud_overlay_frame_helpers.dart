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

bool _cityExpansionHexSelected(GameClientState? gameState) {
  final pendingAction = gameState?.pendingAction;
  if (pendingAction is! PendingCityExpansionSelection) return false;
  return gameState?.cities.any(
        (city) =>
            city.id == pendingAction.cityId &&
            city.preferredExpansionHex != null,
      ) ??
      false;
}

FirstTurnCoachmarkSelectionKind _coachmarkSelectionKind(
  GameSelection? selection,
  String activePlayerId,
) {
  final city = selection?.city;
  if (city != null && city.ownerPlayerId == activePlayerId) {
    return FirstTurnCoachmarkSelectionKind.city;
  }
  final unit = selection?.unit;
  if (unit == null || unit.ownerPlayerId != activePlayerId) {
    return FirstTurnCoachmarkSelectionKind.none;
  }
  return switch (unit.type) {
    GameUnitType.settler => FirstTurnCoachmarkSelectionKind.settler,
    GameUnitType.worker => FirstTurnCoachmarkSelectionKind.worker,
    _ => FirstTurnCoachmarkSelectionKind.unit,
  };
}

bool _hasCityNeedingProduction(
  GameClientState? gameState,
  String activePlayerId,
) {
  return gameState?.cities.any(
        (city) =>
            city.ownerPlayerId == activePlayerId &&
            city.productionQueue == null,
      ) ??
      false;
}

bool _canPromptWorkerAction(
  GameUnit? unit,
  SelectionViewModel? selectedInfoModel,
) {
  if (unit == null) return false;
  if (unit.type != GameUnitType.worker) return false;
  if (!_canUseUnitTurnAction(unit) || unit.queuedPath != null) return false;
  return selectedInfoModel?.workerAction?.canStartSelection == true;
}

String? _workerActionBlockedReason({
  required GameUnit? unit,
  required GameClientState? gameState,
  required WorldMap mapData,
  required SelectionViewModel? selectedInfoModel,
  required AppLocalizations l10n,
}) {
  if (unit == null || unit.type != GameUnitType.worker) return null;
  if (unit.isWorking) return null;
  final workerAction = selectedInfoModel?.workerAction;
  if (workerAction == null || workerAction.canStartSelection) return null;
  return _workerTileBlockedReason(
        unit: unit,
        gameState: gameState,
        mapData: mapData,
        l10n: l10n,
      ) ??
      workerAction.buildBlockedReason;
}

String? _workerTileBlockedReason({
  required GameUnit unit,
  required GameClientState? gameState,
  required WorldMap mapData,
  required AppLocalizations l10n,
}) {
  final hex = CityHex(col: unit.col, row: unit.row);
  if (mapData.tileAt(unit.col, unit.row) == null) {
    return l10n.selectionActionNoWorkerTile;
  }
  if (gameState?.cities.any((city) => city.center == hex) == true) {
    return l10n.selectionActionCannotImproveCityCenter;
  }
  if (gameState?.fieldImprovements.any(
        (improvement) => improvement.occupies(unit.col, unit.row),
      ) ==
      true) {
    return l10n.selectionActionTileAlreadyImproved;
  }
  final controlledByOwnCity =
      gameState?.cities.any(
        (city) =>
            city.ownerPlayerId == unit.ownerPlayerId &&
            city.controlsHex(hex) &&
            city.center != hex,
      ) ??
      false;
  if (!controlledByOwnCity) {
    return l10n.selectionActionTileMustBelongToCity;
  }
  return null;
}

bool _canPromptScoutAutoExplore(GameUnit? unit) {
  return unit != null &&
      unit.type == GameUnitType.scout &&
      !unit.isAutoExploring &&
      _canUseUnitTurnAction(unit) &&
      unit.queuedPath == null;
}

String? _cityFoundingBlockedReason({
  required GameClientState? gameState,
  required MapTileLookup mapTiles,
  required AppLocalizations l10n,
}) {
  final unit = gameState?.selectedUnit;
  if (unit == null || unit.type != GameUnitType.settler || unit.isWorking) {
    return null;
  }
  final failure = CityFoundingRules.startFailure(
    unit: unit,
    centerTile: mapTiles.tileAt(unit.col, unit.row),
    cities: gameState?.cities ?? const [],
  );
  return _cityFoundingFailureReason(failure, l10n);
}

String? _cityFoundingFailureReason(
  CityFoundingFailure? failure,
  AppLocalizations l10n,
) => switch (failure) {
  null => null,
  CityFoundingFailure.noCommander => l10n.selectionActionFoundCityNoCommander,
  CityFoundingFailure.noSettlers => l10n.selectionActionFoundCityNoSettlers,
  CityFoundingFailure.invalidCenter =>
    l10n.selectionActionFoundCityInvalidCenter,
  CityFoundingFailure.cityAlreadyExists =>
    l10n.selectionActionFoundCityCityAlreadyExists,
  CityFoundingFailure.centerOccupied =>
    l10n.selectionActionFoundCityCenterOccupied,
  CityFoundingFailure.tooCloseToCity =>
    l10n.selectionActionFoundCityTooCloseToCity,
  CityFoundingFailure.invalidControlledHexes =>
    l10n.selectionActionFoundCityInvalidControlledHexes,
};
