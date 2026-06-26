part of 'hud_command_dispatcher.dart';

extension HudCommandDispatcherPanels on HudCommandDispatcher {
  void toggleCityProductionPanel({required GameState? state}) {
    final modes = _ref.read(hudPanelControllerProvider);
    if (modes.cityBuildings) {
      closeCityProductionPanel();
    } else {
      openCityProductionPanel(state: state);
    }
  }

  void openCityProductionPanel({required GameState? state}) {
    final modes = _ref.read(hudPanelControllerProvider);
    if (!HudPanelOpenAvailability.cityProduction(modes: modes, state: state)) {
      return;
    }

    _applyPanelModes(modes.openCityBuildings());
    _cancelResearchSelectionIfPending(state: state);
    _cancelWorkerActionSelectionIfPending(state);
  }

  void closeCityProductionPanel({bool playSound = true}) {
    final modes = _ref.read(hudPanelControllerProvider);
    if (!modes.cityBuildings) return;
    _applyPanelModes(modes.closeCityBuildings(), playSound: playSound);
  }

  void toggleTechnologyPanel({
    required String activePlayerId,
    required GameState? state,
  }) {
    final modes = _ref.read(hudPanelControllerProvider);
    if (modes.technology) {
      closeTechnologyPanel(state: state, activePlayerId: activePlayerId);
    } else {
      openTechnologyPanel(activePlayerId: activePlayerId, state: state);
    }
  }

  void openTechnologyPanel({
    required String activePlayerId,
    required GameState? state,
  }) {
    final modes = _ref.read(hudPanelControllerProvider);
    if (!HudPanelOpenAvailability.technology(
      modes: modes,
      activePlayerId: activePlayerId,
    )) {
      return;
    }

    _applyPanelModes(modes.openTechnology(), playSound: false);
    _ref.playSound(GameSoundCue.technology);
    _cancelWorkerActionSelectionIfPending(state);
  }

  void closeTechnologyPanel({
    required String activePlayerId,
    required GameState? state,
  }) {
    final modes = _ref.read(hudPanelControllerProvider);
    if (!modes.technology) return;
    _applyPanelModes(modes.closeTechnology());
    final cancelResearchCommand =
        HudPendingActionCommands.cancelResearchSelection(
          state: state,
          activePlayerId: activePlayerId,
        );
    if (cancelResearchCommand == null) return;
    final key = hudResearchActionKey(
      save: _ref.read(gamePlayerControlSaveProvider),
      activePlayerId: activePlayerId,
    );
    if (key != null) {
      _ref.read(hudResearchAutoPromptControllerProvider.notifier).dismiss(key);
    }
    unawaited(dispatch(cancelResearchCommand));
  }

  void toggleObjectivesPanel({
    required String activePlayerId,
    required GameState? state,
  }) {
    final modes = _ref.read(hudPanelControllerProvider);
    if (modes.objectives) {
      closeObjectivesPanel();
    } else {
      openObjectivesPanel(activePlayerId: activePlayerId, state: state);
    }
  }

  void openObjectivesPanel({
    required String activePlayerId,
    required GameState? state,
  }) {
    final modes = _ref.read(hudPanelControllerProvider);
    if (!HudPanelOpenAvailability.objectives(
      modes: modes,
      activePlayerId: activePlayerId,
    )) {
      return;
    }

    _applyPanelModes(modes.openObjectives());
    closeResourceBreakdown();
    _cancelResearchSelectionIfPending(
      state: state,
      activePlayerId: activePlayerId,
    );
    _cancelWorkerActionSelectionIfPending(state);
  }

  void closeObjectivesPanel() {
    final modes = _ref.read(hudPanelControllerProvider);
    if (!modes.objectives) return;
    _applyPanelModes(modes.closeObjectives());
  }

  void toggleEmpirePanel({
    required String activePlayerId,
    required GameState? state,
  }) {
    final modes = _ref.read(hudPanelControllerProvider);
    if (modes.empire) {
      closeEmpirePanel();
    } else {
      openEmpirePanel(activePlayerId: activePlayerId, state: state);
    }
  }

  void openEmpirePanel({
    required String activePlayerId,
    required GameState? state,
  }) {
    final modes = _ref.read(hudPanelControllerProvider);
    if (!HudPanelOpenAvailability.empire(
      modes: modes,
      state: state,
      activePlayerId: activePlayerId,
    )) {
      return;
    }

    _applyPanelModes(modes.openEmpire());
    _cancelResearchSelectionIfPending(
      state: state,
      activePlayerId: activePlayerId,
    );
    _cancelWorkerActionSelectionIfPending(state);
  }

  void closeEmpirePanel() {
    final modes = _ref.read(hudPanelControllerProvider);
    if (!modes.empire) return;
    _applyPanelModes(modes.closeEmpire());
  }

  void toggleActivityLogPanel({
    required String activePlayerId,
    required GameState? state,
  }) {
    final modes = _ref.read(hudPanelControllerProvider);
    if (modes.activityLog) {
      closeActivityLogPanel();
    } else {
      openActivityLogPanel(activePlayerId: activePlayerId, state: state);
    }
  }

  void openActivityLogPanel({
    required String activePlayerId,
    required GameState? state,
  }) {
    final modes = _ref.read(hudPanelControllerProvider);
    if (!HudPanelOpenAvailability.activityLog(
      modes: modes,
      activePlayerId: activePlayerId,
    )) {
      return;
    }

    _applyPanelModes(modes.openActivityLog());
    _cancelResearchSelectionIfPending(
      state: state,
      activePlayerId: activePlayerId,
    );
    _cancelWorkerActionSelectionIfPending(state);
  }

  void closeActivityLogPanel() {
    final modes = _ref.read(hudPanelControllerProvider);
    if (!modes.activityLog) return;
    _applyPanelModes(modes.closeActivityLog());
  }
}
