import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:aonw/game/presentation/providers/audio/game_audio_provider.dart';
import 'package:aonw/game/presentation/widgets/hud/command/hud_command_dispatcher.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_breakdown_controller.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_strip.dart';

extension HudCommandDispatcherResources on HudCommandDispatcher {
  void toggleResourceBreakdown(ResourceBreakdownType type) {
    _toggleTopResourcePopup(type.popupType);
  }

  void toggleVictoryBreakdown() {
    _toggleTopResourcePopup(TopResourcePopupType.victory);
  }

  void closeResourceBreakdown() {
    ref.read(hudResourceBreakdownControllerProvider.notifier).close();
  }

  void _toggleTopResourcePopup(TopResourcePopupType type) {
    final opening = ref.read(hudResourceBreakdownControllerProvider) != type;
    if (opening && !canInteract) return;
    ref.read(hudResourceBreakdownControllerProvider.notifier).toggle(type);
    ref.playSound(
      opening ? GameSoundCue.uiPanelOpen : GameSoundCue.uiPanelClose,
    );
    if (!opening) return;

    final modes = ref.read(hudPanelControllerProvider);
    if (!modes.objectives) return;
    applyPanelModes(modes.closeObjectives());
  }
}
