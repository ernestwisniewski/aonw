part of 'game_options_overlay.dart';

extension _GameOptionsOverlaySideMenu on _GameOptionsOverlayState {
  List<HudMinimizedPopupEntry> _helpEntries({
    required AppLocalizations l10n,
    required String saveId,
    required List<HudMinimizedPopupEntry> minimizedPopups,
  }) {
    if (saveId.isEmpty) return minimizedPopups;
    final byId = <String, HudMinimizedPopupEntry>{
      HudMinimizedPopupIds.firstTurnTutorial(saveId): HudMinimizedPopupEntry(
        id: HudMinimizedPopupIds.firstTurnTutorial(saveId),
        kind: HudMinimizedPopupKind.firstTurnCoachmarks,
        title: l10n.firstTurnTutorialPopupTitle,
        subtitle: l10n.firstTurnTutorialPopupSubtitle,
      ),
      HudMinimizedPopupIds.autoTurnHint(saveId): HudMinimizedPopupEntry(
        id: HudMinimizedPopupIds.autoTurnHint(saveId),
        kind: HudMinimizedPopupKind.autoTurnHint,
        title: l10n.autoTurnHintTitle,
        subtitle: l10n.autoTurnHintMinimizedSubtitle,
      ),
    };
    for (final entry in minimizedPopups) {
      byId[entry.id] = entry;
    }
    return byId.values.toList(growable: false);
  }

  List<HudGamepadFocusTarget> _sideMenuFocusTargets({
    required AppLocalizations l10n,
    required bool menuCollapsed,
    required bool helpAvailable,
    required bool objectivesAvailable,
    required bool activityLogAvailable,
    required bool globalActionsAvailable,
    required String activePlayerId,
    required GameState? gameState,
  }) {
    if (menuCollapsed) {
      return [
        HudGamepadFocusTarget(
          section: HudGamepadFocusSection.globalActions,
          id: _sideMenuTargetId('menu'),
          label: l10n.optionsOpenMenuTooltip,
          onActivate: _expandMenu,
        ),
      ];
    }
    return [
      HudGamepadFocusTarget(
        section: HudGamepadFocusSection.globalActions,
        id: _sideMenuTargetId('options'),
        label: l10n.optionsTooltip,
        onActivate: () => _toggleOptions(activePlayerId, gameState),
      ),
      if (helpAvailable)
        HudGamepadFocusTarget(
          section: HudGamepadFocusSection.globalActions,
          id: _sideMenuTargetId('help'),
          label: l10n.helpPopupsTitle,
          onActivate: () => _toggleHelpPanel(activePlayerId, gameState),
        ),
      if (objectivesAvailable)
        HudGamepadFocusTarget(
          section: HudGamepadFocusSection.globalActions,
          id: _sideMenuTargetId('objectives'),
          label: l10n.objectivesPanelTitle,
          onActivate: () => _toggleObjectivesPanel(activePlayerId, gameState),
        ),
      if (activityLogAvailable)
        HudGamepadFocusTarget(
          section: HudGamepadFocusSection.globalActions,
          id: _sideMenuTargetId('activityLog'),
          label: l10n.activityLogTitle,
          onActivate: () => _toggleActivityLogPanel(activePlayerId, gameState),
        ),
      if (globalActionsAvailable)
        HudGamepadFocusTarget(
          section: HudGamepadFocusSection.globalActions,
          id: _sideMenuTargetId('research'),
          label: l10n.commonResearch,
          onActivate: () => _toggleTechnologyPanel(activePlayerId, gameState),
        ),
      if (globalActionsAvailable)
        HudGamepadFocusTarget(
          section: HudGamepadFocusSection.globalActions,
          id: _sideMenuTargetId('empire'),
          label: l10n.commonEmpire,
          onActivate: () => _toggleEmpirePanel(activePlayerId, gameState),
        ),
    ];
  }

  void _publishGamepadFocusTargets(List<HudGamepadFocusTarget> targets) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _gamepadFocusRegistry.setSource('gameOptions', targets);
    });
  }

  bool _sideMenuFocused(String? focusedTargetId, String targetId) {
    return focusedTargetId == _sideMenuTargetId(targetId);
  }

  String _sideMenuTargetId(String targetId) {
    return HudGamepadFocusTargetIds.globalAction(targetId);
  }

  void _toggleObjectivesPanel(String activePlayerId, GameState? gameState) {
    _closeOptions();
    ref
        .read(hudCommandDispatcherProvider)
        .toggleObjectivesPanel(
          activePlayerId: activePlayerId,
          state: gameState,
        );
  }

  void _toggleActivityLogPanel(String activePlayerId, GameState? gameState) {
    _closeOptions();
    ref
        .read(hudCommandDispatcherProvider)
        .toggleActivityLogPanel(
          activePlayerId: activePlayerId,
          state: gameState,
        );
  }

  void _toggleTechnologyPanel(String activePlayerId, GameState? gameState) {
    _closeOptions();
    ref
        .read(hudCommandDispatcherProvider)
        .toggleTechnologyPanel(
          activePlayerId: activePlayerId,
          state: gameState,
        );
  }

  void _toggleEmpirePanel(String activePlayerId, GameState? gameState) {
    _closeOptions();
    ref
        .read(hudCommandDispatcherProvider)
        .toggleEmpirePanel(activePlayerId: activePlayerId, state: gameState);
  }

  void _closeHudSidePanels({
    required String activePlayerId,
    required GameState? gameState,
  }) {
    final dispatcher = ref.read(hudCommandDispatcherProvider)
      ..closeObjectivesPanel()
      ..closeEmpirePanel()
      ..closeActivityLogPanel();
    if (activePlayerId.isNotEmpty) {
      dispatcher.closeTechnologyPanel(
        activePlayerId: activePlayerId,
        state: gameState,
      );
    }
  }
}
