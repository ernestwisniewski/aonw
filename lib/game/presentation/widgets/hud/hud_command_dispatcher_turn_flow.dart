part of 'hud_command_dispatcher.dart';

extension HudCommandDispatcherTurnFlow on HudCommandDispatcher {
  Future<void> focusNextAction({
    required String activePlayerId,
    required GameState? Function() currentState,
    GameObjectiveAdvice? preferredObjectiveAdvice,
    int? actionIndex,
  }) async {
    if (activePlayerId.isEmpty) return;

    await dispatch(
      FocusNextPendingActionCommand(
        activePlayerId,
        preferredObjectiveAdvice: preferredObjectiveAdvice,
        actionIndex: actionIndex,
      ),
    );
    if (!_ref.mounted) return;

    final focusedState = currentState();
    _applyPanelModes(
      _ref.read(hudPanelControllerProvider).closePrimaryPanels(),
    );

    switch (HudNextActionPanelResolver.afterFocus(
      state: focusedState,
      activePlayerId: activePlayerId,
    )) {
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
    bool moveCamera = true,
  }) async {
    if (activePlayerId.isEmpty) return;

    _ref.read(mapInspectionControllerProvider.notifier).clear();
    _applyPanelModes(
      _ref.read(hudPanelControllerProvider).closePrimaryPanels(),
    );

    final focused = await _ref
        .read(gameCommandControllerProvider.notifier)
        .focusTurnStartMapTarget(activePlayerId, moveCamera: moveCamera);
    if (!_ref.mounted || focused || !moveCamera) return;

    await _ref
        .read(gameCommandControllerProvider.notifier)
        .jumpToPlayerStart(activePlayerId);
  }

  Future<void> endTurn({
    required ValueListenable<Set<String>> animatingUnitIdsListenable,
    required GameSave gameSave,
    required String activePlayerId,
    required bool readyToEndTurn,
    required GameState? Function() currentState,
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
      moveCamera: true,
    );
  }
}
