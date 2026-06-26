part of 'hud_selection_actions.dart';

_HudSelectionActionSpec? _artifactExcavationActionFor({
  required GameUnit unit,
  required GameState? gameState,
  required String? lockedReason,
  required AppLocalizations l10n,
  required VoidCallback onStartArtifactExcavation,
}) {
  final artifact = _mapArtifactAtUnit(unit, gameState);
  if (artifact == null) return null;
  final canStart =
      _canUseTurnAction(unit) &&
      unit.queuedPath == null &&
      unit.carriedArtifactId == null;
  final reason = unit.carriedArtifactId != null
      ? l10n.selectionActionArtifactAlreadyCarried
      : unit.queuedPath != null
      ? l10n.selectionActionCancelCurrentMoveFirst
      : _turnActionBlockedReason(l10n, unit);
  return _HudSelectionActionSpec(
    icon: GameIcons.shovel,
    actionId: 'excavateArtifact',
    label: l10n.selectionActionExcavateArtifact,
    color: const Color(0xFFA78BFA),
    enabled: _enabled(canStart, lockedReason),
    prominent: canStart && lockedReason == null,
    pulseBorder: canStart && lockedReason == null,
    disabledReason: _disabledReason(
      lockedReason: lockedReason,
      actionReason: reason,
    ),
    badgeLabel: GameDisplayNames.worldArtifactShortBonus(l10n, artifact.type),
    onTap: onStartArtifactExcavation,
  );
}

_HudSelectionActionSpec? _storeArtifactActionFor({
  required GameUnit unit,
  required GameState? gameState,
  required String? lockedReason,
  required AppLocalizations l10n,
  required VoidCallback onStoreArtifactInCity,
}) {
  if (unit.carriedArtifactId == null) return null;
  final city = _ownCityAtUnit(unit, gameState);
  final cityHasArtifact =
      city != null && _cityAlreadyStoresArtifact(city.id, gameState);
  final canStore = city != null && !cityHasArtifact;
  final reason = city == null
      ? l10n.selectionActionStoreArtifactOwnCityRequired
      : l10n.selectionActionStoreArtifactCityOccupied;
  return _HudSelectionActionSpec(
    icon: GameIcons.artifact,
    actionId: 'storeArtifact',
    label: l10n.selectionActionStoreArtifact,
    color: const Color(0xFFA78BFA),
    enabled: _enabled(canStore, lockedReason),
    prominent: canStore && lockedReason == null,
    disabledReason: _disabledReason(
      lockedReason: lockedReason,
      actionReason: canStore ? null : reason,
    ),
    onTap: onStoreArtifactInCity,
  );
}

WorldArtifact? _mapArtifactAtUnit(GameUnit unit, GameState? gameState) {
  if (gameState == null) return null;
  for (final artifact in gameState.artifacts) {
    final location = artifact.location;
    if (location.isOnMap &&
        location.col == unit.col &&
        location.row == unit.row) {
      return artifact;
    }
  }
  return null;
}

GameCity? _ownCityAtUnit(GameUnit unit, GameState? gameState) {
  if (gameState == null) return null;
  for (final city in gameState.cities) {
    if (city.ownerPlayerId == unit.ownerPlayerId &&
        city.occupiesCenter(unit.col, unit.row)) {
      return city;
    }
  }
  return null;
}

bool _cityAlreadyStoresArtifact(String cityId, GameState? gameState) {
  if (gameState == null) return false;
  for (final artifact in gameState.artifacts) {
    final location = artifact.location;
    if (location.isStored && location.cityId == cityId) return true;
  }
  return false;
}
