part of 'game_state_reducer.dart';

abstract final class _ActivePlayerReducer {
  static GameStateTransition handleSetActivePlayer(
    GameState state,
    SetActivePlayerCommand command,
    ReducerEnvironment environment,
  ) {
    final next = _activePlayerChanged(state, command)
        ? _applyControlChange(state, command)
        : _applyPlayerIdentity(state, command);

    return GameStateTransition(
      state: _recomputeFogOfWarIfNeeded(next, environment),
    );
  }

  static bool _activePlayerChanged(
    GameState state,
    SetActivePlayerCommand command,
  ) {
    return state.activePlayerId != command.playerId ||
        state.activePlayerCanAct != command.canAct;
  }

  static GameState _applyControlChange(
    GameState state,
    SetActivePlayerCommand command,
  ) {
    final next = _clearMapInteractionState(
      _applyPlayerIdentity(state, command),
      clearPendingAction: true,
    );
    return _clearSelectionIfUnavailable(next, state.selection);
  }

  static GameState _applyPlayerIdentity(
    GameState state,
    SetActivePlayerCommand command,
  ) {
    return state.copyWith(
      activePlayerId: command.playerId,
      activePlayerCanAct: command.canAct,
    );
  }

  static GameState _clearSelectionIfUnavailable(
    GameState state,
    GameSelection? selection,
  ) {
    if (selection == null || _canKeepSelection(state, selection)) return state;
    return state.copyWithInteraction(selection: null);
  }

  static bool _canKeepSelection(GameState state, GameSelection selection) {
    return switch (selection.type) {
      GameSelectionType.tile => true,
      GameSelectionType.fieldImprovement => _canKeepFieldImprovementSelection(
        state,
        selection,
      ),
      GameSelectionType.unit => _canKeepUnitSelection(state, selection),
      GameSelectionType.city => _canKeepCitySelection(state, selection),
    };
  }

  static bool _canKeepFieldImprovementSelection(
    GameState state,
    GameSelection selection,
  ) {
    final improvement = selection.fieldImprovement;
    if (improvement == null) return false;
    if (!state.activePlayerVisibility.canRememberStaticAt(
      improvement.hex.col,
      improvement.hex.row,
    )) {
      return false;
    }
    return state.fieldImprovements.any(
      (item) => item.hex == improvement.hex && item.type == improvement.type,
    );
  }

  static bool _canKeepUnitSelection(GameState state, GameSelection selection) {
    final unit = selection.unit;
    if (unit == null) return false;
    final liveUnit = state.units.where((u) => u.id == unit.id).firstOrNull;
    if (liveUnit == null) return false;
    return state.canControlUnit(liveUnit) ||
        _isActivePlayerOwned(state, liveUnit.ownerPlayerId);
  }

  static bool _canKeepCitySelection(GameState state, GameSelection selection) {
    final city = selection.city;
    if (city == null) return false;
    return state.canControlCity(city) ||
        _isActivePlayerOwned(state, city.ownerPlayerId);
  }

  static bool _isActivePlayerOwned(GameState state, String ownerPlayerId) {
    return state.activePlayerId.isNotEmpty &&
        state.activePlayerId == ownerPlayerId;
  }

  static GameState _recomputeFogOfWarIfNeeded(
    GameState state,
    ReducerEnvironment environment,
  ) {
    if (!_hasFogRevealSources(state)) return state;

    final fogOfWar = environment.fogOfWarService.recompute(
      current: state.fogOfWar,
      mapData: environment.mapData,
      playerIds: knownPlayerIds(state),
      units: state.units,
      cities: state.cities,
    );
    if (fogOfWar == state.fogOfWar) {
      return withDiscoveredDiplomaticContacts(state);
    }

    return withDiscoveredDiplomaticContacts(state.copyWith(fogOfWar: fogOfWar));
  }

  static bool _hasFogRevealSources(GameState state) {
    return state.units.isNotEmpty ||
        state.cities.isNotEmpty ||
        state.fogOfWar.playerIds.isNotEmpty;
  }
}
