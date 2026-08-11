part of 'hud_selection_actions.dart';

HudSelectionActionSpec _moveActionFor({
  required GameUnit unit,
  required GameClientState? gameState,
  required bool moveModeActive,
  required String? lockedReason,
  required AppLocalizations l10n,
  required VoidCallback onMoveSelectedUnit,
  required VoidCallback onCancelSelectedUnitAction,
}) {
  final movePreviewActive = gameState?.movePreview?.unitId == unit.id;
  final queuedPath = unit.queuedPath;
  final queuedPathActive = queuedPath != null;
  final active = moveModeActive || movePreviewActive || queuedPathActive;
  const available = true;
  final cancelsQueuedPath =
      queuedPathActive && !moveModeActive && !movePreviewActive;

  return HudSelectionActionSpec(
    icon: GameIcons.move,
    actionId: 'move',
    label: l10n.selectionActionMove,
    active: active,
    enabled: _enabled(available, lockedReason),
    dangerOutlined: cancelsQueuedPath,
    prominent: !active && available && lockedReason == null,
    disabledReason: lockedReason,
    badgeLabel: _queuedPathTurnsLabel(unit, queuedPath),
    onTap: cancelsQueuedPath ? onCancelSelectedUnitAction : onMoveSelectedUnit,
  );
}

String? _queuedPathTurnsLabel(GameUnit unit, QueuedMovePath? queuedPath) {
  if (queuedPath == null || queuedPath.steps.isEmpty) return null;
  final perTurn = UnitMovementBalance.maxMovementPointsFor(
    type: unit.type,
    carriedArtifactId: unit.carriedArtifactId,
  );
  final paidCost = _queuedPathPaidCost(unit, queuedPath);
  final totalCost = queuedPath.steps.last.cumulativeCost;
  final remaining = totalCost - paidCost - unit.movementPoints;
  final turns = TurnEtaFormatter.turnsRemainingFromProgress(
    remaining: remaining,
    perTurn: perTurn,
  );
  if (turns == null || turns <= 0) return null;
  return '$turns';
}

int _queuedPathPaidCost(GameUnit unit, QueuedMovePath queuedPath) {
  for (final step in queuedPath.steps) {
    if (step.col == unit.col && step.row == unit.row) {
      return step.cumulativeCost;
    }
  }
  return 0;
}

HudSelectionActionSpec? _attackActionFor({
  required GameUnit unit,
  required GameClientState? gameState,
  required String? lockedReason,
  required AppLocalizations l10n,
  required VoidCallback onStartAttackTargeting,
  required VoidCallback onCancelAttackTargeting,
}) {
  final pendingAction = gameState?.pendingAction;
  final attackTargetingActive =
      pendingAction is PendingAttackTargeting &&
      pendingAction.attackerUnitId == unit.id;
  final combatStats = UnitCombatStats.derive(unit);
  final canAttack = _canUseTurnAction(unit) && combatStats.attack > 0;
  if (!attackTargetingActive && combatStats.attack <= 0) return null;
  final nearbyEnemyCount = gameState == null
      ? 0
      : _visibleEnemyUnitAttackTargetCount(unit, gameState);
  final available = attackTargetingActive || canAttack;

  return HudSelectionActionSpec(
    icon: GameIcons.attack,
    actionId: 'attack',
    label: l10n.selectionActionAttack,
    color: GameUiTheme.danger,
    active: attackTargetingActive,
    enabled: _enabled(available, lockedReason),
    dangerOutlined: attackTargetingActive,
    disabledOpacity: 0.68,
    prominent:
        !attackTargetingActive &&
        canAttack &&
        nearbyEnemyCount > 0 &&
        lockedReason == null,
    disabledReason: _disabledReason(
      lockedReason: lockedReason,
      actionReason: attackTargetingActive
          ? null
          : _attackBlockedReason(
              l10n: l10n,
              unit: unit,
              combatStats: combatStats,
            ),
    ),
    badgeLabel: nearbyEnemyCount > 0 ? '$nearbyEnemyCount' : null,
    onTap: attackTargetingActive
        ? onCancelAttackTargeting
        : onStartAttackTargeting,
  );
}

HudSelectionActionSpec _autoExploreActionFor({
  required GameUnit unit,
  required String? lockedReason,
  required AppLocalizations l10n,
  required VoidCallback onAutoExploreSelectedUnit,
  required VoidCallback onCancelSelectedUnitAction,
}) {
  final active = unit.isAutoExploring;
  final available =
      active || (_canUseTurnAction(unit) && unit.queuedPath == null);
  final needsGuidance = !active && available && lockedReason == null;
  return HudSelectionActionSpec(
    icon: GameIcons.visibility,
    actionId: 'autoExplore',
    label: l10n.selectionActionAutoExplore,
    color: GameUiTheme.info,
    active: active,
    enabled: _enabled(available, lockedReason),
    dangerOutlined: active,
    prominent: needsGuidance,
    pulseBorder: needsGuidance,
    disabledReason: _disabledReason(
      lockedReason: lockedReason,
      actionReason: active
          ? null
          : unit.queuedPath != null
          ? l10n.selectionActionCancelCurrentMoveFirst
          : _turnActionBlockedReason(l10n, unit),
    ),
    onTap: active ? onCancelSelectedUnitAction : onAutoExploreSelectedUnit,
  );
}

HudSelectionActionSpec _commanderArmyActionFor({
  required bool armyDetailActive,
  required String? lockedReason,
  required AppLocalizations l10n,
  required VoidCallback onShowArmy,
}) {
  return HudSelectionActionSpec(
    icon: GameIcons.army,
    actionId: 'army',
    label: l10n.selectionActionArmy,
    active: armyDetailActive,
    enabled: _enabled(true, lockedReason),
    disabledReason: lockedReason,
    onTap: onShowArmy,
  );
}

HudSelectionActionSpec _cityFoundingActionFor({
  required GameUnit unit,
  required GameClientState? gameState,
  required GameSelection? selection,
  required bool canStartCityFounding,
  required String? lockedReason,
  required AppLocalizations l10n,
  required VoidCallback onStartCityFounding,
}) {
  final needsGuidance = canStartCityFounding && lockedReason == null;
  return HudSelectionActionSpec(
    icon: GameIcons.foundCity,
    actionId: 'foundCity',
    label: l10n.selectionActionFoundCity,
    color: GameUiTheme.success,
    active: false,
    enabled: _enabled(canStartCityFounding, lockedReason),
    prominent: needsGuidance,
    pulseBorder: needsGuidance,
    disabledReason: _disabledReason(
      lockedReason: lockedReason,
      actionReason: _cityFoundingBlockedReason(
        l10n: l10n,
        unit: unit,
        gameState: gameState,
        selection: selection,
      ),
    ),
    onTap: onStartCityFounding,
  );
}

HudSelectionActionSpec _workerBuildActionFor({
  required GameUnit unit,
  required GameClientState? gameState,
  required WorkerActionPanelViewModel? workerAction,
  required String? lockedReason,
  required AppLocalizations l10n,
  required VoidCallback onStartWorkerActionSelection,
  required VoidCallback onCancelWorkerActionSelection,
  required VoidCallback onCancelWorkerJob,
}) {
  final pending = gameState?.pendingAction;
  final selectionActive =
      pending is PendingWorkerActionSelection && pending.unitId == unit.id;
  final jobActive = workerAction?.hasActiveJob ?? unit.workerJob != null;
  final active = selectionActive || jobActive;
  final canStart =
      _canUseTurnAction(unit) &&
      unit.queuedPath == null &&
      (workerAction?.canStartSelection ?? true);
  final needsGuidance = !active && canStart && lockedReason == null;

  return HudSelectionActionSpec(
    icon: GameIcons.production,
    actionId: 'improve',
    label: l10n.selectionActionImprove,
    color: GameUiTheme.success,
    active: active,
    enabled: _enabled(active || canStart, lockedReason),
    dangerOutlined: active,
    prominent: needsGuidance,
    pulseBorder: needsGuidance,
    disabledReason: _disabledReason(
      lockedReason: lockedReason,
      actionReason: active
          ? null
          : unit.queuedPath != null
          ? l10n.selectionActionCancelCurrentMoveFirst
          : _turnActionBlockedReason(l10n, unit) ??
                workerAction?.buildBlockedReason ??
                l10n.selectionActionNoBuildAvailable,
    ),
    onTap: jobActive
        ? onCancelWorkerJob
        : selectionActive
        ? onCancelWorkerActionSelection
        : onStartWorkerActionSelection,
  );
}

HudSelectionActionSpec _workerRoadActionFor({
  required GameUnit unit,
  required GameClientState? gameState,
  required WorldMap mapData,
  required String? lockedReason,
  required AppLocalizations l10n,
  required VoidCallback onBuildRoad,
}) {
  final legality = gameState == null
      ? const RoadConstructionLegality.blocked(
          RoadConstructionBlocker.missingTile,
        )
      : RoadConstructionRules.evaluate(
          unit: unit,
          cities: gameState.cities,
          network: gameState.transportNetwork,
          mapTiles: mapData,
        );
  final available = legality.allowed;
  return HudSelectionActionSpec(
    icon: GameIcons.route,
    actionId: 'buildRoad',
    label: l10n.selectionActionBuildRoad,
    color: GameUiTheme.gold,
    active: false,
    enabled: _enabled(available, lockedReason),
    disabledReason: _disabledReason(
      lockedReason: lockedReason,
      actionReason: available
          ? null
          : _roadConstructionBlockedReason(l10n, legality.blocker),
    ),
    onTap: onBuildRoad,
  );
}

String _roadConstructionBlockedReason(
  AppLocalizations l10n,
  RoadConstructionBlocker? blocker,
) {
  return switch (blocker) {
    RoadConstructionBlocker.workerBusy => l10n.selectionActionUnitWorking,
    RoadConstructionBlocker.noMovementPoints => l10n.selectionActionNoMovement,
    RoadConstructionBlocker.queuedPathActive =>
      l10n.selectionActionCancelCurrentMoveFirst,
    RoadConstructionBlocker.existingRoad =>
      l10n.selectionActionRoadAlreadyBuilt,
    RoadConstructionBlocker.enemyTerritory =>
      l10n.selectionActionRoadEnemyTerritory,
    RoadConstructionBlocker.impassableTerrain =>
      l10n.selectionActionRoadInvalidTerrain,
    RoadConstructionBlocker.cityCenter => l10n.selectionActionRoadCityCenter,
    RoadConstructionBlocker.notWorker ||
    RoadConstructionBlocker.missingTile ||
    null => l10n.selectionActionRoadUnavailable,
  };
}

HudSelectionActionSpec _skipTurnActionFor({
  required GameUnit unit,
  required GameClientState? gameState,
  required String? lockedReason,
  required AppLocalizations l10n,
  required VoidCallback onSkipSelectedUnitTurn,
  required VoidCallback onCancelSelectedUnitAction,
}) {
  final pendingAction = gameState?.pendingAction;
  final active =
      pendingAction is PendingUnitTurnSkip && pendingAction.unitId == unit.id;
  final available = active || _canUseTurnAction(unit);
  final needsGuidance =
      !active && available && unit.movementPoints == 1 && lockedReason == null;
  return HudSelectionActionSpec(
    icon: GameIcons.skipTurn,
    actionId: 'skip',
    label: l10n.selectionActionSkip,
    active: active,
    enabled: _enabled(available, lockedReason),
    dangerOutlined: active,
    pulseBorder: needsGuidance,
    disabledReason: _disabledReason(
      lockedReason: lockedReason,
      actionReason: active ? null : _turnActionBlockedReason(l10n, unit),
    ),
    onTap: active ? onCancelSelectedUnitAction : onSkipSelectedUnitTurn,
  );
}

HudSelectionActionSpec _fortifyActionFor({
  required GameUnit unit,
  required String? lockedReason,
  required AppLocalizations l10n,
  required VoidCallback onFortifySelectedUnit,
  required VoidCallback onCancelSelectedUnitAction,
}) {
  final active = unit.isFortified;
  final healing = UnitFortificationRules.canHeal(unit);
  final available = active || _canUseTurnAction(unit);
  return HudSelectionActionSpec(
    icon: healing ? GameIcons.heartPlus : GameIcons.defense,
    actionId: healing ? 'heal' : 'fortify',
    label: healing ? l10n.selectionActionHeal : l10n.selectionActionFortify,
    active: active,
    enabled: _enabled(available, lockedReason),
    dangerOutlined: active,
    disabledReason: _disabledReason(
      lockedReason: lockedReason,
      actionReason: active ? null : _turnActionBlockedReason(l10n, unit),
    ),
    onTap: active ? onCancelSelectedUnitAction : onFortifySelectedUnit,
  );
}

HudSelectionActionSpec? _fallbackCancelActionFor({
  required GameUnit unit,
  required GameClientState? gameState,
  required String? lockedReason,
  required AppLocalizations l10n,
  required VoidCallback onCancelSelectedUnitAction,
}) {
  final pendingAction = gameState?.pendingAction;
  final pendingForUnit = pendingAction?.ownsUnit(unit.id) ?? false;
  final coveredPending =
      pendingAction is PendingAttackTargeting ||
      pendingAction is PendingWorkerActionSelection ||
      pendingAction is PendingUnitTurnSkip;
  if (!pendingForUnit || coveredPending) return null;
  return _finishModeActionFor(
    label: _fallbackCancelActionLabelFor(pendingAction, l10n),
    disabledReason: lockedReason,
    l10n: l10n,
    onTap: onCancelSelectedUnitAction,
  );
}

String _fallbackCancelActionLabelFor(
  PendingPlayerAction? pendingAction,
  AppLocalizations l10n,
) {
  return switch (pendingAction) {
    PendingCommanderMergeSelection() =>
      l10n.selectionActionCancelCommanderMerge,
    _ => l10n.selectionActionCancel,
  };
}
