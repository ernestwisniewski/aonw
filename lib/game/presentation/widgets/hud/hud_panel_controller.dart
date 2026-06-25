import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_panel_modes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hudPanelControllerProvider =
    NotifierProvider<HudPanelController, HudPanelModes>(HudPanelController.new);

final hudResearchAutoPromptControllerProvider =
    NotifierProvider<HudResearchAutoPromptController, Set<String>>(
      HudResearchAutoPromptController.new,
    );

final hudAutoTurnFlowProvider =
    NotifierProvider<HudAutoTurnFlowController, bool>(
      HudAutoTurnFlowController.new,
    );

final hudAutoActionFlowProvider =
    NotifierProvider<HudAutoActionFlowController, bool>(
      HudAutoActionFlowController.new,
    );

String? hudResearchActionKey({
  required GameSave? save,
  required String activePlayerId,
}) {
  if (save == null || activePlayerId.isEmpty) return null;
  return '${save.id}:${save.turn}:$activePlayerId:research';
}

class HudPanelController extends Notifier<HudPanelModes> {
  @override
  HudPanelModes build() => const HudPanelModes();

  HudPanelModes normalized(GameState? gameState) {
    return normalizeHudPanelModes(current: state, gameState: gameState);
  }

  HudPanelModes syncWithGameState(GameState? gameState) {
    final next = normalized(gameState);
    state = next;
    return next;
  }

  void apply(HudPanelModes modes) {
    state = modes;
  }
}

class HudResearchAutoPromptController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void dismiss(String key) {
    state = {...state, key};
  }

  void clear(String key) {
    if (!state.contains(key)) return;
    state = {...state}..remove(key);
  }
}

class HudAutoTurnFlowController extends Notifier<bool> {
  @override
  bool build() => false;

  void setEnabled(bool enabled) {
    state = enabled;
  }
}

class HudAutoActionFlowController extends Notifier<bool> {
  @override
  bool build() => true;

  void setEnabled(bool enabled) {
    state = enabled;
  }
}
