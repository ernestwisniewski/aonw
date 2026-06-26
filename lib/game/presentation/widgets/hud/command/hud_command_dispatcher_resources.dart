part of 'hud_command_dispatcher.dart';

extension HudCommandDispatcherResources on HudCommandDispatcher {
  void toggleResourceBreakdown(ResourceBreakdownType type) {
    _toggleTopResourcePopup(type.popupType);
  }

  void toggleVictoryBreakdown() {
    _toggleTopResourcePopup(TopResourcePopupType.victory);
  }

  void closeResourceBreakdown() {
    _ref.read(hudResourceBreakdownControllerProvider.notifier).close();
  }

  void _toggleTopResourcePopup(TopResourcePopupType type) {
    final opening = _ref.read(hudResourceBreakdownControllerProvider) != type;
    _ref.read(hudResourceBreakdownControllerProvider.notifier).toggle(type);
    _ref.playSound(
      opening ? GameSoundCue.uiPanelOpen : GameSoundCue.uiPanelClose,
    );
    if (!opening) return;

    final modes = _ref.read(hudPanelControllerProvider);
    if (!modes.objectives) return;
    _applyPanelModes(modes.closeObjectives());
  }
}
