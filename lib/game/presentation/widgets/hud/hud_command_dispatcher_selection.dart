part of 'hud_command_dispatcher.dart';

extension HudCommandDispatcherSelection on HudCommandDispatcher {
  void showArmySelectionDetail() {
    _applyPanelModes(
      _ref.read(hudPanelControllerProvider).closePrimaryPanels(),
    );
    _ref
        .read(openSelectionDetailControllerProvider.notifier)
        .toggle(SelectionInfoChipId.army);
  }

  void moveSelectedUnit() {
    _applyPanelModes(
      _ref.read(hudPanelControllerProvider).closeUnitActionPanels(),
    );
    unawaited(dispatch(const ToggleMoveTargetingCommand()));
  }

  Future<void> focusUnitMapTarget(String unitId) {
    return _ref
        .read(gameCommandControllerProvider.notifier)
        .focusUnitMapTarget(unitId);
  }

  Future<void> focusCityMapTarget(String cityId) {
    return _ref
        .read(gameCommandControllerProvider.notifier)
        .focusCityMapTarget(cityId);
  }

  void autoExploreSelectedUnit(GameState? state, MapData mapData) {
    final command = HudSelectionCommands.autoExploreSelectedUnit(
      state,
      mapData,
    );
    if (command == null) return;

    _clearFeedback();
    _applyPanelModes(
      _ref.read(hudPanelControllerProvider).closeUnitActionPanels(),
    );
    unawaited(dispatch(command));
  }

  void startAttackTargeting(GameState? state) {
    final command = HudSelectionCommands.startAttackTargeting(state);
    if (command == null) return;
    _applyPanelModes(
      _ref.read(hudPanelControllerProvider).closePrimaryPanels(),
    );
    unawaited(dispatch(command));
  }

  void cancelAttackTargeting(GameState? state) {
    final unitId = HudPendingActionTargets.attackUnitId(state);
    if (unitId == null) return;
    unawaited(dispatch(CancelAttackTargetingCommand(unitId)));
  }

  void detachTroop(TroopType troopType) {
    unawaited(
      _ref.read(gameCommandControllerProvider.notifier).detachTroop(troopType),
    );
  }

  void startCityFounding() {
    _applyPanelModes(
      _ref.read(hudPanelControllerProvider).closeUnitActionPanels(),
    );
    _ref.read(openSelectionDetailControllerProvider.notifier).close();
    unawaited(dispatch(const StartCityFoundingCommand()));
  }

  void cancelCityFounding() {
    unawaited(dispatch(const CancelCityFoundingCommand()));
  }

  void confirmCityFounding(GameState? state) {
    final draft = state?.cityFoundingDraft;
    if (draft == null || !draft.canConfirm) return;
    unawaited(
      dispatch(
        FoundCityCommand(draft.unitId, controlledHexes: draft.controlledHexes),
      ),
    );
  }

  void startCityWorkedHexSelection(GameState? state) {
    final command = HudSelectionCommands.startCityWorkedHexSelection(state);
    if (command == null) return;
    _applyPanelModes(
      _ref.read(hudPanelControllerProvider).closePrimaryPanels(),
    );
    unawaited(dispatch(command));
  }

  void cancelCityWorkedHexSelection(GameState? state) {
    final cityId = HudPendingActionTargets.cityWorkedHexCityId(state);
    if (cityId == null) return;
    unawaited(dispatch(CancelCityWorkedHexSelectionCommand(cityId)));
  }

  void startCityExpansionSelection(GameState? state) {
    final command = HudSelectionCommands.startCityExpansionSelection(state);
    if (command == null) return;
    _applyPanelModes(
      _ref.read(hudPanelControllerProvider).closePrimaryPanels(),
    );
    unawaited(dispatch(command));
  }

  void cancelCityExpansionSelection(GameState? state) {
    unawaited(confirmCityExpansionSelection(state));
  }

  Future<void> confirmCityExpansionSelection(GameState? state) async {
    final cityId = HudPendingActionTargets.cityExpansionCityId(state);
    if (cityId == null) return;
    await dispatch(CancelCityExpansionSelectionCommand(cityId));
  }

  void startWorkerActionSelection(GameState? state) {
    final command = HudSelectionCommands.startWorkerActionSelection(state);
    if (command == null) return;
    _applyPanelModes(
      _ref.read(hudPanelControllerProvider).closePrimaryPanels(),
    );
    unawaited(dispatch(command));
  }

  void _clearFeedback() {
    _ref.read(hudFeedbackProvider.notifier).clear();
  }

  void cancelWorkerActionSelection(GameState? state) {
    final unitId = HudPendingActionTargets.workerUnitId(state);
    if (unitId == null) return;
    unawaited(dispatch(CancelWorkerActionSelectionCommand(unitId)));
  }

  void startMerchantTradeRouteSelection(GameState? state) {
    final command = HudSelectionCommands.startMerchantTradeRouteSelection(
      state,
    );
    if (command == null) return;
    _applyPanelModes(
      _ref.read(hudPanelControllerProvider).closePrimaryPanels(),
    );
    unawaited(dispatch(command));
  }

  void cancelMerchantTradeRouteSelection(GameState? state) {
    final unitId = HudPendingActionTargets.merchantUnitId(state);
    if (unitId == null) return;
    unawaited(dispatch(CancelMerchantTradeRouteSelectionCommand(unitId)));
  }

  void assignMerchantTradeRoute(GameState? state, String destinationCityId) {
    final command = HudSelectionCommands.assignMerchantTradeRoute(
      state,
      destinationCityId,
    );
    if (command == null) return;
    unawaited(dispatch(command));
  }

  void startMerchantMoveToCitySelection(GameState? state) {
    final command = HudSelectionCommands.startMerchantMoveToCitySelection(
      state,
    );
    if (command == null) return;
    _applyPanelModes(
      _ref.read(hudPanelControllerProvider).closePrimaryPanels(),
    );
    unawaited(dispatch(command));
  }

  void cancelMerchantMoveToCitySelection(GameState? state) {
    final unitId = HudPendingActionTargets.merchantUnitId(state);
    if (unitId == null) return;
    unawaited(dispatch(CancelMerchantMoveToCitySelectionCommand(unitId)));
  }

  void moveMerchantToCity(GameState? state, String destinationCityId) {
    final command = HudSelectionCommands.moveMerchantToCity(
      state,
      destinationCityId,
    );
    if (command == null) return;
    unawaited(dispatch(command));
  }

  void selectWorkerImprovement(String unitId, FieldImprovementType type) {
    unawaited(dispatch(SelectWorkerImprovementCommand(unitId, type)));
  }

  void confirmWorkerImprovement(String unitId) {
    unawaited(dispatch(ConfirmWorkerImprovementCommand(unitId)));
  }

  void cancelWorkerJob(GameState? state) {
    final command = HudSelectionCommands.cancelWorkerJob(state);
    if (command == null) return;
    unawaited(dispatch(command));
  }

  void startArtifactExcavation(GameState? state) {
    final command = HudSelectionCommands.startArtifactExcavation(state);
    if (command == null) return;
    unawaited(dispatch(command));
  }

  void storeArtifactInCity(GameState? state) {
    final command = HudSelectionCommands.storeArtifactInCity(state);
    if (command == null) return;
    unawaited(dispatch(command));
  }

  void cancelSelectedUnitAction(GameState? state) {
    final command = HudSelectionCommands.cancelSelectedUnitAction(state);
    if (command == null) return;
    unawaited(dispatch(command));
  }

  void skipSelectedUnitTurn(GameState? state) {
    final command = HudSelectionCommands.skipSelectedUnitTurn(state);
    if (command == null) return;
    unawaited(dispatch(command));
  }

  void fortifySelectedUnit(GameState? state) {
    final command = HudSelectionCommands.fortifySelectedUnit(state);
    if (command == null) return;
    unawaited(dispatch(command));
  }
}
