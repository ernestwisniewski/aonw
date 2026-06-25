import 'dart:async';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_city_production_commands.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_next_action_panel.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_panel_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_panel_modes.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_panel_open_availability.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_pending_action_commands.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_pending_action_targets.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_resource_breakdown_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_selection_commands.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_strip.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/selection_info/selection_info.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'hud_command_dispatcher_city_research.dart';
part 'hud_command_dispatcher_panels.dart';
part 'hud_command_dispatcher_resources.dart';
part 'hud_command_dispatcher_selection.dart';
part 'hud_command_dispatcher_turn_flow.dart';

class HudCommandDispatcher {
  const HudCommandDispatcher(this._ref);

  final Ref _ref;

  Future<void> dispatch(GameCommand command) async {
    _ref.read(mapInspectionControllerProvider.notifier).clear();
    await _ref.read(gameCommandControllerProvider.notifier).dispatch(command);
  }

  void _applyPanelModes(HudPanelModes modes, {bool playSound = true}) {
    final current = _ref.read(hudPanelControllerProvider);
    final cue = _panelTransitionCue(current, modes);
    _ref.read(hudPanelControllerProvider.notifier).apply(modes);
    if (playSound && cue != null) _ref.playSound(cue);
  }

  GameSoundCue? _panelTransitionCue(HudPanelModes current, HudPanelModes next) {
    if (current == next) return null;
    final opened = _openPanelCount(next) > _openPanelCount(current);
    return opened ? GameSoundCue.uiPanelOpen : GameSoundCue.uiPanelClose;
  }

  int _openPanelCount(HudPanelModes modes) {
    return [
      modes.cityBuildings,
      modes.technology,
      modes.objectives,
      modes.empire,
      modes.activityLog,
    ].where((open) => open).length;
  }

  void _cancelResearchSelectionIfPending({
    required GameState? state,
    String activePlayerId = '',
  }) {
    final command = HudPendingActionCommands.cancelResearchSelection(
      state: state,
      activePlayerId: activePlayerId,
    );
    if (command == null) return;
    unawaited(dispatch(command));
  }

  void _cancelWorkerActionSelectionIfPending(GameState? state) {
    final command = HudPendingActionCommands.cancelWorkerActionSelection(state);
    if (command == null) return;
    unawaited(dispatch(command));
  }
}
