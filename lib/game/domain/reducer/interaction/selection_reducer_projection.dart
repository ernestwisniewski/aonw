part of 'selection_reducer.dart';

_ClientState _selectTileDirect(_ClientState state, MapTileView tile) {
  final visibleTile = _visibleTileForActivePlayer(state, tile);
  return _withFreshInteractionSelection(state, GameSelection.tile(visibleTile));
}

_ClientState _selectUnitDirect(
  _ClientState state,
  GameUnit unit,
  MapTileLookup mapTiles,
) {
  final tile = mapTiles.tileAt(unit.col, unit.row);
  final visibleTile = tile == null
      ? null
      : _visibleTileForActivePlayer(state, tile);

  var next = _withFreshInteractionSelection(
    state,
    GameSelection.unit(unit, tile: visibleTile),
  );

  if (next.canControlUnit(unit) &&
      UnitManualMovementRules.canStartTargeting(unit)) {
    next = next.copyWithInteraction(moveCommandActive: true);
  } else {
    next = next.copyWithInteraction(moveCommandActive: false);
  }

  return next;
}

_ClientState _selectFieldImprovementDirect(
  _ClientState state,
  FieldImprovement improvement,
  MapTileView tile,
) {
  final visibleTile = _visibleTileForActivePlayer(state, tile);
  return _withFreshInteractionSelection(
    state,
    GameSelection.fieldImprovement(improvement, tile: visibleTile),
  );
}

_ClientState _selectCityDirect(
  _ClientState state,
  GameCity city,
  MapTileLookup mapTiles, {
  GameRuleset ruleset = GameRuleset.defaults,
  PaceBalance paceBalance = PaceBalance.unlimited,
}) {
  return _withFreshInteractionSelection(
    state,
    CitySelectionProjector.project(
      state: state,
      city: city,
      mapTiles: mapTiles,
      ruleset: ruleset,
      paceBalance: paceBalance,
    ),
  );
}

_ClientState _selectCityCenterTile(
  _ClientState state,
  GameCity city,
  MapTileLookup mapTiles,
) {
  final centerTile = mapTiles.tileAt(city.center.col, city.center.row);
  if (centerTile != null) {
    return _selectTileDirect(state, centerTile);
  }
  return _withFreshInteractionSelection(state, null);
}

SelectedTile _visibleTileForActivePlayer(
  GameClientState state,
  MapTileView tile,
) {
  final snapshot = SelectedTile.fromMapTileView(tile);
  return snapshot.withResources(
    ResourceVisibilityRules.visibleResources(
      resources: snapshot.resources,
      playerId: state.activePlayerId,
      research: state.research,
    ),
  );
}

GameClientState _withFreshInteractionSelection(
  GameClientState state,
  GameSelection? selection,
) {
  return state.copyWith(
    interaction: state.interaction
        .clearMapState(clearPendingAction: true)
        .copyWith(selection: selection),
  );
}
