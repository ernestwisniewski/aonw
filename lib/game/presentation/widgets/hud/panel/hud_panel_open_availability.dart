import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_modes.dart';

abstract final class HudPanelOpenAvailability {
  static bool cityProduction({
    required HudPanelModes modes,
    required GameState? state,
  }) {
    return !modes.cityBuildings && state?.selection?.city != null;
  }

  static bool technology({
    required HudPanelModes modes,
    required String activePlayerId,
  }) {
    return !modes.technology && activePlayerId.isNotEmpty;
  }

  static bool objectives({
    required HudPanelModes modes,
    required String activePlayerId,
  }) {
    return !modes.objectives && activePlayerId.isNotEmpty;
  }

  static bool empire({
    required HudPanelModes modes,
    required GameState? state,
    required String activePlayerId,
  }) {
    return !modes.empire && activePlayerId.isNotEmpty && state != null;
  }

  static bool activityLog({
    required HudPanelModes modes,
    required String activePlayerId,
  }) {
    return !modes.activityLog && activePlayerId.isNotEmpty;
  }
}
