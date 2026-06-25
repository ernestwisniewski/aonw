part of 'hud_selection_actions.dart';

List<_HudSelectionActionSpec>? _activeUnitModeActionsFor({
  required GameUnit unit,
  required GameState? gameState,
  required MapData mapData,
  required WorkerActionPanelViewModel? workerAction,
  required bool cityFoundingActive,
  required bool actionsLocked,
  required AppLocalizations l10n,
  required VoidCallback onCancelAttackTargeting,
  required VoidCallback onCancelWorkerActionSelection,
  required VoidCallback onCancelWorkerJob,
  required VoidCallback onCancelMerchantTradeRouteSelection,
  required ValueChanged<String> onAssignMerchantTradeRoute,
  required VoidCallback onCancelMerchantMoveToCitySelection,
  required ValueChanged<String> onMoveMerchantToCity,
  required VoidCallback onConfirmCityFounding,
  required VoidCallback onCancelCityFounding,
  required VoidCallback onCancelSelectedUnitAction,
}) {
  final lockedReason = actionsLocked ? l10n.selectionActionLockedReason : null;
  final pendingAction = gameState?.pendingAction;
  if (pendingAction is PendingAttackTargeting &&
      pendingAction.attackerUnitId == unit.id) {
    return [
      _finishModeActionFor(
        label: l10n.selectionActionCancelAttack,
        disabledReason: lockedReason,
        l10n: l10n,
        onTap: onCancelAttackTargeting,
      ),
    ];
  }

  if (pendingAction is PendingWorkerActionSelection &&
      pendingAction.unitId == unit.id) {
    return [
      _finishModeActionFor(
        label: l10n.selectionActionCancelWorkerBuild,
        disabledReason: lockedReason,
        l10n: l10n,
        onTap: onCancelWorkerActionSelection,
      ),
    ];
  }

  if (pendingAction is PendingMerchantTradeRouteSelection &&
      pendingAction.unitId == unit.id) {
    return [
      ..._merchantTradeRouteCityActionsFor(
        unit: unit,
        gameState: gameState,
        mapData: mapData,
        lockedReason: lockedReason,
        l10n: l10n,
        onAssignMerchantTradeRoute: onAssignMerchantTradeRoute,
      ),
      _finishModeActionFor(
        label: l10n.selectionActionCancelTradeRouteSelection,
        disabledReason: lockedReason,
        l10n: l10n,
        onTap: onCancelMerchantTradeRouteSelection,
      ),
    ];
  }

  if (pendingAction is PendingMerchantMoveToCitySelection &&
      pendingAction.unitId == unit.id) {
    return [
      ..._merchantMoveToCityActionsFor(
        unit: unit,
        gameState: gameState,
        mapData: mapData,
        lockedReason: lockedReason,
        l10n: l10n,
        onMoveMerchantToCity: onMoveMerchantToCity,
      ),
      _finishModeActionFor(
        label: l10n.selectionActionCancelMerchantMoveToCity,
        disabledReason: lockedReason,
        l10n: l10n,
        onTap: onCancelMerchantMoveToCitySelection,
      ),
    ];
  }

  if (pendingAction is PendingCommanderMergeSelection &&
      pendingAction.commanderUnitId == unit.id) {
    return [
      _finishModeActionFor(
        label: l10n.selectionActionCancelCommanderMerge,
        disabledReason: lockedReason,
        l10n: l10n,
        onTap: onCancelSelectedUnitAction,
      ),
    ];
  }

  final draft = gameState?.cityFoundingDraft;
  final ownsCityFounding =
      cityFoundingActive &&
      (draft == null || draft.unitId == unit.id) &&
      _supportsCityFoundingAction(unit);
  if (ownsCityFounding) {
    return [
      if (draft?.canConfirm == true)
        _confirmCityFoundingActionFor(
          disabledReason: lockedReason,
          l10n: l10n,
          onTap: onConfirmCityFounding,
        ),
      _finishModeActionFor(
        label: draft?.canConfirm == true
            ? l10n.selectionActionCancel
            : l10n.selectionActionCancelCityFounding,
        disabledReason: lockedReason,
        l10n: l10n,
        onTap: onCancelCityFounding,
      ),
    ];
  }

  if (unit.cityFoundingJob != null) {
    return [
      _finishModeActionFor(
        label: l10n.selectionActionCancelCityFounding,
        disabledReason: lockedReason,
        l10n: l10n,
        onTap: onCancelSelectedUnitAction,
      ),
    ];
  }

  if (unit.type == GameUnitType.scout && unit.isAutoExploring) {
    return [
      _finishModeActionFor(
        label: l10n.selectionActionCancelAutoExplore,
        disabledReason: lockedReason,
        l10n: l10n,
        onTap: onCancelSelectedUnitAction,
      ),
    ];
  }

  if (unit.excavatingArtifactId != null) {
    return [
      _finishModeActionFor(
        label: l10n.selectionActionCancelArtifactExcavation,
        disabledReason: lockedReason,
        l10n: l10n,
        onTap: onCancelSelectedUnitAction,
      ),
    ];
  }

  final workerJobActive =
      unit.type == GameUnitType.worker &&
      (workerAction?.hasActiveJob ?? unit.workerJob != null);
  if (workerJobActive) {
    return [
      _finishModeActionFor(
        label: l10n.selectionActionCancelWorkerBuild,
        disabledReason: lockedReason,
        l10n: l10n,
        onTap: onCancelWorkerJob,
      ),
    ];
  }

  if (unit.isFortified) {
    return [
      _stopFortifyingActionFor(
        unit: unit,
        disabledReason: lockedReason,
        l10n: l10n,
        onTap: onCancelSelectedUnitAction,
      ),
    ];
  }

  return null;
}

_HudSelectionActionSpec _confirmCityFoundingActionFor({
  required String? disabledReason,
  required AppLocalizations l10n,
  required VoidCallback onTap,
}) {
  return _HudSelectionActionSpec(
    icon: GameIcons.flag,
    actionId: 'foundCity',
    label: l10n.selectionActionFoundCity,
    color: GameUiTheme.success,
    active: true,
    prominent: disabledReason == null,
    showLabel: true,
    enabled: disabledReason == null,
    disabledReason: disabledReason,
    onTap: onTap,
  );
}

_HudSelectionActionSpec _finishModeActionFor({
  required String label,
  required String? disabledReason,
  required AppLocalizations l10n,
  required VoidCallback onTap,
}) {
  return _HudSelectionActionSpec(
    icon: GameIcons.close,
    actionId: 'cancel',
    label: label,
    color: GameUiTheme.danger,
    active: true,
    showLabel: true,
    dangerOutlined: true,
    enabled: disabledReason == null,
    disabledReason: disabledReason,
    onTap: onTap,
  );
}

_HudSelectionActionSpec _stopFortifyingActionFor({
  required GameUnit unit,
  required String? disabledReason,
  required AppLocalizations l10n,
  required VoidCallback onTap,
}) {
  final healing = _unitIsHealing(unit);
  return _HudSelectionActionSpec(
    icon: healing ? GameIcons.heartPlus : GameIcons.defense,
    actionId: healing ? 'stopHealing' : 'stopFortifying',
    label: healing
        ? l10n.selectionActionStopHealing
        : l10n.selectionActionStopFortifying,
    color: GameUiTheme.danger,
    active: true,
    showLabel: true,
    dangerOutlined: true,
    enabled: disabledReason == null,
    disabledReason: disabledReason,
    onTap: onTap,
  );
}
