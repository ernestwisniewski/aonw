import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/hud_command_dispatcher_provider.dart';
import 'package:aonw/game/presentation/providers/renderer_provider.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_map_focus_target.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_panel_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_panel_modes.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HudMapFocusController {
  const HudMapFocusController(this._ref);

  final Ref _ref;

  Future<void> focusEmpireUnit(GameUnit unit) {
    final modes = _ref.read(hudPanelControllerProvider);
    return _focusMapTarget(
      HudMapFocusTarget.unit(unit),
      panelModes: modes.closePrimaryPanels().closeEmpire(),
    );
  }

  Future<void> focusEmpireCity(GameCity city) {
    final modes = _ref.read(hudPanelControllerProvider);
    return _focusMapTarget(
      HudMapFocusTarget.city(city),
      panelModes: modes.closePrimaryPanels().closeEmpire(),
    );
  }

  Future<void> focusActivityLogEntry({
    required GameEventNotification notification,
    required GameState? currentState,
  }) async {
    final target = HudMapFocusTarget.notification(
      notification: notification,
      currentState: currentState,
    );
    if (target == null) return;

    final modes = _ref.read(hudPanelControllerProvider);
    await _focusMapTarget(
      target,
      panelModes: modes.closePrimaryPanels().closeActivityLog(),
    );
  }

  Future<void> _focusMapTarget(
    HudMapFocusTarget target, {
    required HudPanelModes panelModes,
  }) async {
    _ref.read(hudPanelControllerProvider.notifier).apply(panelModes);
    await _ref
        .read(hudCommandDispatcherProvider)
        .dispatch(target.selectCommand);
    await _ref
        .read(activeRendererViewModelProvider)
        ?.handleEffect(target.cameraEffect);
  }
}
