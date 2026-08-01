part of 'game_state_reducer.dart';

abstract final class _ActivePlayerReducer {
  static GameStateTransition handleSetActivePlayer(
    GameClientState state,
    String playerId,
    bool canAct,
  ) {
    final next = _activePlayerChanged(state, playerId, canAct)
        ? _applyControlChange(state, playerId, canAct)
        : _applyPlayerIdentity(state, playerId, canAct);

    return GameStateTransition(state: next);
  }

  static bool _activePlayerChanged(
    GameClientState state,
    String playerId,
    bool canAct,
  ) {
    return state.activePlayerId != playerId ||
        state.activePlayerCanAct != canAct;
  }

  static GameClientState _applyControlChange(
    GameClientState state,
    String playerId,
    bool canAct,
  ) {
    final next = _clearMapInteractionState(
      _applyPlayerIdentity(state, playerId, canAct),
      clearPendingAction: true,
    );
    return _clearSelectionIfUnavailable(next, state.selection);
  }

  static GameClientState _applyPlayerIdentity(
    GameClientState state,
    String playerId,
    bool canAct,
  ) {
    return state.copyWith(activePlayerId: playerId, activePlayerCanAct: canAct);
  }

  static GameClientState _clearSelectionIfUnavailable(
    GameClientState state,
    GameSelection? selection,
  ) {
    if (selection == null || _canKeepSelection(state, selection)) return state;
    return state.copyWithInteraction(selection: null);
  }

  static bool _canKeepSelection(
    GameClientState state,
    GameSelection selection,
  ) {
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
    GameClientState state,
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

  static bool _canKeepUnitSelection(
    GameClientState state,
    GameSelection selection,
  ) {
    final unit = selection.unit;
    if (unit == null) return false;
    final liveUnit = state.unitById(unit.id);
    if (liveUnit == null) return false;
    return state.canControlUnit(liveUnit) ||
        _isActivePlayerOwned(state, liveUnit.ownerPlayerId);
  }

  static bool _canKeepCitySelection(
    GameClientState state,
    GameSelection selection,
  ) {
    final city = selection.city;
    if (city == null) return false;
    return state.canControlCity(city) ||
        _isActivePlayerOwned(state, city.ownerPlayerId);
  }

  static bool _isActivePlayerOwned(
    GameClientState state,
    String ownerPlayerId,
  ) {
    return state.activePlayerId.isNotEmpty &&
        state.activePlayerId == ownerPlayerId;
  }
}
