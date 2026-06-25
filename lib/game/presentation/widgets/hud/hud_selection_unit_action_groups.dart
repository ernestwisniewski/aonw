part of 'hud_selection_actions.dart';

List<List<_HudSelectionActionSpec>> _unitActionGroups({
  required GameUnit unit,
  required GameState? gameState,
  required GameSelection? selection,
  required MapData mapData,
  required bool actionsLocked,
  required bool moveModeActive,
  required bool armyDetailActive,
  required WorkerActionPanelViewModel? workerAction,
  required bool canStartCityFounding,
  required bool cityFoundingActive,
  required AppLocalizations l10n,
  required VoidCallback onMoveSelectedUnit,
  required VoidCallback onAutoExploreSelectedUnit,
  required VoidCallback onStartAttackTargeting,
  required VoidCallback onCancelAttackTargeting,
  required VoidCallback onShowArmy,
  required VoidCallback onStartWorkerActionSelection,
  required VoidCallback onCancelWorkerActionSelection,
  required VoidCallback onCancelWorkerJob,
  required VoidCallback onStartMerchantTradeRouteSelection,
  required VoidCallback onCancelMerchantTradeRouteSelection,
  required VoidCallback onStartMerchantMoveToCitySelection,
  required VoidCallback onCancelMerchantMoveToCitySelection,
  required VoidCallback onStartArtifactExcavation,
  required VoidCallback onStoreArtifactInCity,
  required VoidCallback onStartCityFounding,
  required VoidCallback onCancelCityFounding,
  required VoidCallback onSkipSelectedUnitTurn,
  required VoidCallback onFortifySelectedUnit,
  required VoidCallback onCancelSelectedUnitAction,
}) {
  final lockedReason = actionsLocked ? l10n.selectionActionLockedReason : null;
  final movement = unit.type == GameUnitType.merchant
      ? <_HudSelectionActionSpec>[]
      : <_HudSelectionActionSpec>[
          _moveActionFor(
            unit: unit,
            gameState: gameState,
            moveModeActive: moveModeActive,
            lockedReason: lockedReason,
            l10n: l10n,
            onMoveSelectedUnit: onMoveSelectedUnit,
            onCancelSelectedUnitAction: onCancelSelectedUnitAction,
          ),
        ];
  final specialGroups = <List<_HudSelectionActionSpec>>[];
  final attack = _attackActionFor(
    unit: unit,
    gameState: gameState,
    lockedReason: lockedReason,
    l10n: l10n,
    onStartAttackTargeting: onStartAttackTargeting,
    onCancelAttackTargeting: onCancelAttackTargeting,
  );
  if (attack != null) specialGroups.add([attack]);
  if (unit.type == GameUnitType.scout) {
    specialGroups.add([
      _autoExploreActionFor(
        unit: unit,
        lockedReason: lockedReason,
        l10n: l10n,
        onAutoExploreSelectedUnit: onAutoExploreSelectedUnit,
        onCancelSelectedUnitAction: onCancelSelectedUnitAction,
      ),
    ]);
  }

  if (unit.type == GameUnitType.commander) {
    specialGroups.add([
      _commanderArmyActionFor(
        armyDetailActive: armyDetailActive,
        lockedReason: lockedReason,
        l10n: l10n,
        onShowArmy: onShowArmy,
      ),
    ]);
  }
  if (_supportsCityFoundingAction(unit)) {
    specialGroups.add([
      _cityFoundingActionFor(
        unit: unit,
        gameState: gameState,
        selection: selection,
        canStartCityFounding: canStartCityFounding,
        cityFoundingActive: cityFoundingActive,
        lockedReason: lockedReason,
        l10n: l10n,
        onStartCityFounding: onStartCityFounding,
        onCancelCityFounding: onCancelCityFounding,
      ),
    ]);
  }
  if (unit.type == GameUnitType.worker) {
    specialGroups.add([
      _workerBuildActionFor(
        unit: unit,
        gameState: gameState,
        workerAction: workerAction,
        lockedReason: lockedReason,
        l10n: l10n,
        onStartWorkerActionSelection: onStartWorkerActionSelection,
        onCancelWorkerActionSelection: onCancelWorkerActionSelection,
        onCancelWorkerJob: onCancelWorkerJob,
      ),
    ]);
  }
  if (unit.type == GameUnitType.merchant) {
    specialGroups.add([
      _merchantTradeRouteActionFor(
        unit: unit,
        gameState: gameState,
        mapData: mapData,
        lockedReason: lockedReason,
        l10n: l10n,
        onStartMerchantTradeRouteSelection: onStartMerchantTradeRouteSelection,
        onCancelMerchantTradeRouteSelection:
            onCancelMerchantTradeRouteSelection,
        onCancelSelectedUnitAction: onCancelSelectedUnitAction,
      ),
      if (unit.merchantTradeRoute == null)
        _merchantMoveToCityActionFor(
          unit: unit,
          gameState: gameState,
          mapData: mapData,
          lockedReason: lockedReason,
          l10n: l10n,
          onStartMerchantMoveToCitySelection:
              onStartMerchantMoveToCitySelection,
          onCancelMerchantMoveToCitySelection:
              onCancelMerchantMoveToCitySelection,
          onCancelSelectedUnitAction: onCancelSelectedUnitAction,
        ),
    ]);
  }
  final artifactActions = <_HudSelectionActionSpec>[
    ?_artifactExcavationActionFor(
      unit: unit,
      gameState: gameState,
      lockedReason: lockedReason,
      l10n: l10n,
      onStartArtifactExcavation: onStartArtifactExcavation,
    ),
    ?_storeArtifactActionFor(
      unit: unit,
      gameState: gameState,
      lockedReason: lockedReason,
      l10n: l10n,
      onStoreArtifactInCity: onStoreArtifactInCity,
    ),
  ];
  if (artifactActions.isNotEmpty) specialGroups.add(artifactActions);

  final routine = <_HudSelectionActionSpec>[
    _skipTurnActionFor(
      unit: unit,
      gameState: gameState,
      lockedReason: lockedReason,
      l10n: l10n,
      onSkipSelectedUnitTurn: onSkipSelectedUnitTurn,
      onCancelSelectedUnitAction: onCancelSelectedUnitAction,
    ),
    _fortifyActionFor(
      unit: unit,
      lockedReason: lockedReason,
      l10n: l10n,
      onFortifySelectedUnit: onFortifySelectedUnit,
      onCancelSelectedUnitAction: onCancelSelectedUnitAction,
    ),
  ];
  final fallbackCancel = _fallbackCancelActionFor(
    unit: unit,
    gameState: gameState,
    lockedReason: lockedReason,
    l10n: l10n,
    onCancelSelectedUnitAction: onCancelSelectedUnitAction,
  );
  if (fallbackCancel != null) routine.add(fallbackCancel);

  return [if (movement.isNotEmpty) movement, ...specialGroups, routine];
}
