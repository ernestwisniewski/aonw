import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/util/collection_equality.dart';

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
    final turnAdvanced = _turnAdvanced(
      authoritativeState: authoritativeState,
      interactionSource: interactionSource,
    );
    final selection = _refreshedSelection(
      authoritativeState,
      interactionSource.selection,
    );
    final selectedUnitId = selection?.unit?.id;
    final authoritativeSelectedUnit = selectedUnitId == null
        ? null
        : authoritativeState.unitById(selectedUnitId);
    final canKeepSelectedUnitAction =
        authoritativeSelectedUnit != null &&
        _canPreserveInteraction(
          authoritativeState,
          authoritativeSelectedUnit.ownerPlayerId,
        );
    final pendingAction = _reconciledPendingAction(
      authoritativeState,
      interactionSource,
      turnAdvanced: turnAdvanced,
    );
    final authoritativeDraft = authoritativeState.cityFoundingDraft;
    final cityFoundingDraft =
        authoritativeDraft ??
        _validCityFoundingDraft(
          authoritativeState,
          interactionSource.cityFoundingDraft,
        );
    final movement = _reconciledMovement(
      authoritativeState: authoritativeState,
      interactionSource: interactionSource,
      selectedUnit: authoritativeSelectedUnit,
      canKeepSelectedUnitAction: canKeepSelectedUnitAction,
      turnAdvanced: turnAdvanced,
      pendingAction: pendingAction,
    );

    return authoritativeState.copyWith(
      interaction: sourceInteraction.copyWith(
        selection: selection,
        movePreview: movement.preview,
        cityFoundingDraft: cityFoundingDraft,
        pendingAction: pendingAction,
        moveCommandActive: movement.active,
      ),
    );
  }

  static PendingPlayerAction? _reconciledPendingAction(
    GameState authoritativeState,
    GameState interactionSource, {
    required bool turnAdvanced,
  }) {
    final resolved =
        authoritativeState.pendingAction ??
        _validPendingAction(
          authoritativeState,
          interactionSource.pendingAction,
        );
    return turnAdvanced && resolved is PendingUnitTurnSkip ? null : resolved;
  }

  static ({UnitMovementPlan? preview, bool active}) _reconciledMovement({
    required GameState authoritativeState,
    required GameState interactionSource,
    required GameUnit? selectedUnit,
    required bool canKeepSelectedUnitAction,
    required bool turnAdvanced,
    required PendingPlayerAction? pendingAction,
  }) {
    final canTarget =
        canKeepSelectedUnitAction && _canStartMoveTargeting(selectedUnit);
    final active =
        canTarget &&
        (turnAdvanced
            ? pendingAction == null
            : interactionSource.moveCommandActive);
    final preview =
        _canPreserveMovePreview(
          authoritativeState: authoritativeState,
          interactionSource: interactionSource,
          selectedUnit: selectedUnit,
          canKeepSelectedUnitAction: canKeepSelectedUnitAction,
          turnAdvanced: turnAdvanced,
        )
        ? interactionSource.movePreview
        : null;
    return (preview: preview, active: active);
  }

  static bool _canPreserveMovePreview({
    required GameState authoritativeState,
    required GameState interactionSource,
    required GameUnit? selectedUnit,
    required bool canKeepSelectedUnitAction,
    required bool turnAdvanced,
  }) {
    final preview = interactionSource.movePreview;
    return !turnAdvanced &&
        preview != null &&
        selectedUnit != null &&
        preview.unitId == selectedUnit.id &&
        preview.availableMovementPoints == selectedUnit.movementPoints &&
        canKeepSelectedUnitAction &&
        _canKeepMovePreview(selectedUnit) &&
        _selectedMovementStateStayedValid(
          interactionSource.unitById(selectedUnit.id),
          selectedUnit,
        ) &&
        _pathfindingInputsStayedValid(authoritativeState, interactionSource);
  }

  static bool _selectedMovementStateStayedValid(
    GameUnit? source,
    GameUnit authoritative,
  ) =>
      source != null &&
      source.col == authoritative.col &&
      source.row == authoritative.row &&
      source.movementPoints == authoritative.movementPoints &&
      source.queuedPath == authoritative.queuedPath &&
      source.posture == authoritative.posture;

  static bool _turnAdvanced({
    required GameState authoritativeState,
    required GameState interactionSource,
  }) {
    final authoritativeStart = authoritativeState.turnStartedAt;
    final sourceStart = interactionSource.turnStartedAt;
    if (authoritativeStart != null &&
        sourceStart != null &&
        authoritativeStart.isAfter(sourceStart)) {
      return true;
    }

    final sourcePending = interactionSource.pendingAction;
    if (sourcePending is! PendingUnitTurnSkip) return false;
    final sourceUnit = interactionSource.unitById(sourcePending.unitId);
    final authoritativeUnit = authoritativeState.unitById(sourcePending.unitId);
    return sourceUnit != null &&
        authoritativeUnit != null &&
        sourceUnit.movementPoints == 0 &&
        authoritativeUnit.movementPoints > 0;
  }

  static bool _canStartMoveTargeting(GameUnit? unit) {
    return unit != null && unit.movementPoints > 0 && _canKeepMovePreview(unit);
  }

  static bool _canKeepMovePreview(GameUnit? unit) {
    return unit != null &&
        !unit.isWorking &&
        !unit.isMerchant &&
        unit.queuedPath == null &&
        !unit.isFortified &&
        !unit.isAutoExploring;
  }

  static bool _pathfindingInputsStayedValid(
    GameState authoritativeState,
    GameState interactionSource,
  ) {
    return listEquals(authoritativeState.units, interactionSource.units) &&
        listEquals(authoritativeState.cities, interactionSource.cities) &&
        authoritativeState.fogOfWar == interactionSource.fogOfWar &&
        authoritativeState.diplomacy == interactionSource.diplomacy;
  }

  static GameSelection? _refreshedSelection(
    GameState state,
    GameSelection? selection,
  ) {
    if (selection == null) return null;
    return switch (selection.type) {
      GameSelectionType.tile =>
        selection.tile == null ? null : GameSelection.tile(selection.tile!),
      GameSelectionType.fieldImprovement =>
        selection.fieldImprovement == null
            ? null
            : GameSelection.fieldImprovement(
                selection.fieldImprovement!,
                tile: selection.tile,
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
    return GameSelection.unit(unit, tile: selection.tile);
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
