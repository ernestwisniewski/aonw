part of 'hud_selection_actions.dart';

int _visibleEnemyUnitAttackTargetCount(GameUnit unit, GameState gameState) {
  final combatStats = UnitCombatStats.derive(unit);
  if (combatStats.attack <= 0) return 0;

  final visibility = gameState.activePlayerVisibility;
  final origin = HexCoordinate(col: unit.col, row: unit.row);
  var count = 0;
  for (final target in gameState.units) {
    if (target.id == unit.id || target.ownerPlayerId == unit.ownerPlayerId) {
      continue;
    }
    if (visibility.isEnabled &&
        !visibility.canSeeDynamicAt(target.col, target.row)) {
      continue;
    }
    final distance = HexDistance.between(
      origin,
      HexCoordinate(col: target.col, row: target.row),
    );
    if (distance <= combatStats.range) count += 1;
  }
  return count;
}

bool _canUseTurnAction(GameUnit unit) {
  return unit.movementPoints > 0 && !unit.isWorking && !unit.isFortified;
}

bool _enabled(bool available, String? lockedReason) {
  return available && lockedReason == null;
}

String? _disabledReason({
  required String? lockedReason,
  required String? actionReason,
}) {
  return lockedReason ?? actionReason;
}

bool _supportsCityFoundingAction(GameUnit unit) {
  return unit.type == GameUnitType.commander ||
      unit.type == GameUnitType.settler;
}

String? _turnActionBlockedReason(AppLocalizations l10n, GameUnit unit) {
  if (unit.isWorking) return l10n.selectionActionUnitWorking;
  if (unit.isFortified) return _fortifiedUnitReason(l10n, unit);
  if (unit.movementPoints <= 0) {
    return l10n.selectionActionNoMovement;
  }
  return null;
}

bool _unitIsHealing(GameUnit unit) {
  return unit.isFortified && UnitFortificationRules.canHeal(unit);
}

String _fortifiedUnitReason(AppLocalizations l10n, GameUnit unit) {
  return _unitIsHealing(unit)
      ? l10n.selectionActionUnitHealing
      : l10n.selectionActionUnitFortified;
}

String? _attackBlockedReason({
  required AppLocalizations l10n,
  required GameUnit unit,
  required CombatStats combatStats,
}) {
  if (combatStats.attack <= 0) return l10n.selectionActionNoAttack;
  final turnReason = _turnActionBlockedReason(l10n, unit);
  if (turnReason != null) return turnReason;
  return null;
}

String? _cityFoundingBlockedReason({
  required AppLocalizations l10n,
  required GameUnit unit,
  required GameState? gameState,
  required GameSelection? selection,
}) {
  final selectedTile = selection?.tile;
  final failure = CityFoundingRules.startFailure(
    unit: unit,
    centerTile: selectedTile == null
        ? null
        : TileData(
            col: selectedTile.col,
            row: selectedTile.row,
            terrains: selectedTile.terrains,
            resources: selectedTile.resources,
            height: selectedTile.height,
          ),
    cities: gameState?.cities ?? const [],
  );
  return _cityFoundingFailureReason(l10n, failure) ??
      l10n.selectionActionCannotFoundCityHere;
}

String? _cityFoundingFailureReason(
  AppLocalizations l10n,
  CityFoundingFailure? failure,
) {
  return switch (failure) {
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
}
