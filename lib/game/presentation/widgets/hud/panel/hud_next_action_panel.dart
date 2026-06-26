import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/runtime.dart';

enum HudNextActionPanel { none, technology, cityProduction }

abstract final class HudNextActionPanelResolver {
  static HudNextActionPanel afterFocus({
    required GameState? state,
    required String activePlayerId,
  }) {
    if (state == null || activePlayerId.isEmpty) {
      return HudNextActionPanel.none;
    }

    if (state.pendingAction case PendingResearchSelection(
      ownerPlayerId: final ownerPlayerId,
    ) when ownerPlayerId == activePlayerId) {
      return HudNextActionPanel.technology;
    }

    final selectedCity = state.selection?.city;
    if (selectedCity == null ||
        selectedCity.ownerPlayerId != activePlayerId ||
        selectedCity.productionQueue != null ||
        state.pendingAction != null) {
      return HudNextActionPanel.none;
    }

    return HudNextActionPanel.cityProduction;
  }
}
