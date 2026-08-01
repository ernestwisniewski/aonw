part of 'hud_command_dispatcher.dart';

extension HudCommandDispatcherTurnFlow on HudCommandDispatcher {
  Future<void> focusNextAction({
    required String activePlayerId,
    required GameClientState? Function() currentState,
    GameObjectiveAdvice? preferredObjectiveAdvice,
    int? actionIndex,
    int actionStep = 1,
  }) async {
    if (activePlayerId.isEmpty) return;

    await dispatchIntent(
      FocusNextPendingActionCommand(
        activePlayerId,
        preferredObjectiveAdvice: preferredObjectiveAdvice,
        actionIndex: actionIndex,
        actionStep: actionStep,
      ),
    );
    if (!_ref.mounted) return;

    final focusedState = currentState();
    final nextPanel = HudNextActionPanelResolver.afterFocus(
      state: focusedState,
      activePlayerId: activePlayerId,
    );
    _closePrimaryPanelsBeforeOpening(nextPanel);

    switch (nextPanel) {
      case HudNextActionPanel.technology:
        openTechnologyPanel(
          activePlayerId: activePlayerId,
          state: focusedState,
        );
      case HudNextActionPanel.cityProduction:
        openCityProductionPanel(state: focusedState);
      case HudNextActionPanel.none:
        return;
    }
  }

  Future<void> focusTurnStartMapTarget({
    required String activePlayerId,
    GameClientState? state,
    bool moveCamera = true,
  }) async {
    if (activePlayerId.isEmpty) return;

    _ref.read(mapInspectionControllerProvider.notifier).clear();
    _applyPanelModesForTurnFocus(state: state, activePlayerId: activePlayerId);

    final focused = await _ref
        .read(gameCommandControllerProvider.notifier)
        .focusTurnStartMapTarget(activePlayerId, moveCamera: moveCamera);
    if (!_ref.mounted || focused || !moveCamera) return;

    await _ref
        .read(gameCommandControllerProvider.notifier)
        .jumpToPlayerStart(activePlayerId);
  }

  void _closePrimaryPanelsBeforeOpening(HudNextActionPanel nextPanel) {
    final modes = _ref.read(hudPanelControllerProvider);
    _applyPanelModes(modes.closePrimaryPanelsPreserving(nextPanel));
  }

  void _applyPanelModesForTurnFocus({
    required GameClientState? state,
    required String activePlayerId,
  }) {
    final modes = _ref.read(hudPanelControllerProvider);
    final nextPanel = HudNextActionPanelResolver.afterFocus(
      state: state,
      activePlayerId: activePlayerId,
    );
    _applyPanelModes(modes.closePrimaryPanelsPreserving(nextPanel));
  }

  Future<void> endTurn({
    required ValueListenable<Set<String>> animatingUnitIdsListenable,
    required GameSave gameSave,
    required String activePlayerId,
    required bool readyToEndTurn,
    required GameClientState? Function() currentState,
    GameObjectiveAdvice? preferredObjectiveAdvice,
  }) async {
    if (animatingUnitIdsListenable.value.isNotEmpty) return;
    if (!readyToEndTurn) {
      await focusNextAction(
        activePlayerId: activePlayerId,
        currentState: currentState,
        preferredObjectiveAdvice: preferredObjectiveAdvice,
      );
      return;
    }

    final updatedSave = await _ref
        .read(gamePlayerControlControllerProvider.notifier)
        .endTurn(gameSave);
    if (!_ref.mounted) return;

    if (gameSave.gameMode != GameMode.multiplayer ||
        updatedSave == null ||
        updatedSave.turn <= gameSave.turn) {
      return;
    }

    await focusTurnStartMapTarget(
      activePlayerId: activePlayerId,
      state: currentState(),
      moveCamera: true,
    );
  }
}
