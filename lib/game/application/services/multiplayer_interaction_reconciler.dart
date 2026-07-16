import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/runtime.dart';

/// Reapplies valid client-owned interaction state over a network snapshot.
///
/// Multiplayer snapshots are authoritative for game data, but selection and
/// targeting drafts live only on the client. Replacing the whole [GameState]
/// would otherwise cancel an in-progress action whenever any player acts.
abstract final class MultiplayerInteractionReconciler {
  static GameState reconcile({
    required GameState authoritativeState,
    required GameState interactionSource,
  }) {
    final sourceInteraction = interactionSource.interaction;
    final selection = _refreshedSelection(
      authoritativeState,
      interactionSource.selection,
    );
    final selectedUnitId = selection?.unit?.id;
    final sourceSelectedUnit = selectedUnitId == null
        ? null
        : interactionSource.unitById(selectedUnitId);
    final authoritativeSelectedUnit = selectedUnitId == null
        ? null
        : authoritativeState.unitById(selectedUnitId);
    final selectedUnitStayedPut =
        sourceSelectedUnit != null &&
        authoritativeSelectedUnit != null &&
        sourceSelectedUnit.col == authoritativeSelectedUnit.col &&
        sourceSelectedUnit.row == authoritativeSelectedUnit.row;
    final canKeepSelectedUnitAction =
        authoritativeSelectedUnit != null &&
        _canPreserveInteraction(
          authoritativeState,
          authoritativeSelectedUnit.ownerPlayerId,
        );

    final authoritativePending = authoritativeState.pendingAction;
    final pendingAction =
        authoritativePending ??
        _validPendingAction(
          authoritativeState,
          interactionSource.pendingAction,
        );
    final authoritativeDraft = authoritativeState.cityFoundingDraft;
    final cityFoundingDraft =
        authoritativeDraft ??
        _validCityFoundingDraft(
          authoritativeState,
          interactionSource.cityFoundingDraft,
        );
    final movePreview =
        selectedUnitStayedPut &&
            canKeepSelectedUnitAction &&
            interactionSource.movePreview?.unitId == selectedUnitId
        ? interactionSource.movePreview
        : null;

    return authoritativeState.copyWith(
      interaction: sourceInteraction.copyWith(
        selection: selection,
        movePreview: movePreview,
        cityFoundingDraft: cityFoundingDraft,
        pendingAction: pendingAction,
        moveCommandActive:
            sourceInteraction.moveCommandActive &&
            canKeepSelectedUnitAction &&
            authoritativeSelectedUnit.movementPoints > 0,
      ),
    );
  }

  static GameSelection? _refreshedSelection(
    GameState state,
    GameSelection? selection,
  ) {
    if (selection == null) return null;
    return switch (selection.type) {
      GameSelectionType.tile =>
        selection.tile == null
            ? null
            : GameSelection.tile(selection.tile!.toTileData()),
      GameSelectionType.fieldImprovement =>
        selection.fieldImprovement == null
            ? null
            : GameSelection.fieldImprovement(
                selection.fieldImprovement!,
                tile: selection.tile?.toTileData(),
              ),
      GameSelectionType.unit => _refreshedUnitSelection(state, selection),
      GameSelectionType.city => _refreshedCitySelection(state, selection),
    };
  }

  static GameSelection? _refreshedUnitSelection(
    GameState state,
    GameSelection selection,
  ) {
    final unitId = selection.unit?.id;
    if (unitId == null) return null;
    final unit = state.unitById(unitId);
    if (unit == null) return null;
    return GameSelection.unit(unit, tile: selection.tile?.toTileData());
  }

  static GameSelection? _refreshedCitySelection(
    GameState state,
    GameSelection selection,
  ) {
    final cityId = selection.city?.id;
    final cityYield = selection.cityYield;
    if (cityId == null || cityYield == null) return null;
    final city = state.cityById(cityId);
    if (city == null) return null;
    return GameSelection.city(
      city,
      cityYield: cityYield,
      cityTileYieldBreakdown: selection.cityTileYieldBreakdown,
      cityEconomy: selection.cityEconomy,
      playerColor:
          state.colorForPlayer(city.ownerPlayerId) ??
          selection.cityPlayerColor ??
          0,
    );
  }

  static PendingPlayerAction? _validPendingAction(
    GameState state,
    PendingPlayerAction? pending,
  ) {
    if (pending == null) return null;
    if (!_canPreserveInteraction(state, pending.ownerPlayerId)) return null;
    return switch (pending) {
      PendingResearchSelection() => pending,
      PendingCityWorkedHexSelection(:final cityId) ||
      PendingCityExpansionSelection(
        :final cityId,
      ) => _ownsCity(state, cityId, pending.ownerPlayerId) ? pending : null,
      PendingWorkerActionSelection(:final unitId) ||
      PendingMerchantTradeRouteSelection(:final unitId) ||
      PendingMerchantMoveToCitySelection(:final unitId) ||
      PendingUnitTurnSkip(
        :final unitId,
      ) => _ownsUnit(state, unitId, pending.ownerPlayerId) ? pending : null,
      PendingAttackTargeting(:final attackerUnitId) =>
        _canKeepAttackTargeting(state, attackerUnitId, pending.ownerPlayerId)
            ? pending
            : null,
      PendingCommanderMergeSelection(:final commanderUnitId) =>
        _ownsUnit(state, commanderUnitId, pending.ownerPlayerId)
            ? pending
            : null,
    };
  }

  static CityFoundingDraft? _validCityFoundingDraft(
    GameState state,
    CityFoundingDraft? draft,
  ) {
    if (draft == null) return null;
    return _canPreserveInteraction(state, draft.ownerPlayerId) &&
            _ownsUnit(state, draft.unitId, draft.ownerPlayerId)
        ? draft
        : null;
  }

  static bool _canKeepAttackTargeting(
    GameState state,
    String unitId,
    String ownerPlayerId,
  ) {
    final unit = state.unitById(unitId);
    return unit != null &&
        unit.ownerPlayerId == ownerPlayerId &&
        unit.movementPoints > 0 &&
        !unit.isWorking;
  }

  static bool _ownsUnit(GameState state, String unitId, String ownerPlayerId) {
    return state.unitById(unitId)?.ownerPlayerId == ownerPlayerId;
  }

  static bool _ownsCity(GameState state, String cityId, String ownerPlayerId) {
    return state.cityById(cityId)?.ownerPlayerId == ownerPlayerId;
  }

  static bool _canPreserveInteraction(GameState state, String ownerPlayerId) {
    return state.activePlayerCanAct &&
        (state.activePlayerId.isEmpty || state.activePlayerId == ownerPlayerId);
  }
}
