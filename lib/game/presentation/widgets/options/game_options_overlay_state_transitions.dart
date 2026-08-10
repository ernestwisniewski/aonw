part of 'game_options_overlay.dart';

extension _GameOptionsOverlayStateTransitions on _GameOptionsOverlayState {
  bool get _overlayPanelActive =>
      !_menuCollapsed && (_optionsOpen || _helpOpen);

  void _toggleOptions(String activePlayerId, GameClientState? gameState) {
    final opening = !_optionsOpen;
    if (opening) {
      _closeHudSidePanels(activePlayerId: activePlayerId, gameState: gameState);
    }
    _updateOverlayState(() {
      _optionsOpen = opening;
      if (_optionsOpen) _helpOpen = false;
    });
  }

  void _toggleHelpPanel(String activePlayerId, GameClientState? gameState) {
    final opening = !_helpOpen;
    if (opening) {
      _closeHudSidePanels(activePlayerId: activePlayerId, gameState: gameState);
    }
    _updateOverlayState(() {
      _helpOpen = opening;
      if (_helpOpen) _optionsOpen = false;
    });
  }

  void _closeOptions() {
    if (!_optionsOpen && !_helpOpen) return;
    _updateOverlayState(() {
      _optionsOpen = false;
      _helpOpen = false;
    });
  }

  void _collapseMenu(String activePlayerId, GameClientState? gameState) {
    _closeHudSidePanels(activePlayerId: activePlayerId, gameState: gameState);
    _updateOverlayState(() {
      _menuCollapsed = true;
      _optionsOpen = false;
      _helpOpen = false;
    });
  }

  void _expandMenu() {
    _updateOverlayState(() => _menuCollapsed = false);
  }

  void _activateHelpEntry(HudMinimizedPopupEntry entry) {
    _updateOverlayState(() => _helpOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(hudMinimizedPopupsProvider.notifier).requestRestoreEntry(entry);
    });
  }
}
