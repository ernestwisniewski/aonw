import 'dart:async';

import 'package:aonw/game/application/services/local_single_player_turn_phase.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/services/turn_presentation_sequencer.dart';
import 'package:aonw/game/presentation/widgets/hud/city/hud_city_production_commands.dart';
import 'package:aonw/game/presentation/widgets/hud/command/hud_pending_action_commands.dart';
import 'package:aonw/game/presentation/widgets/hud/command/hud_pending_action_targets.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_next_action_panel.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_modes.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_open_availability.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_breakdown_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/selection/hud_selection_commands.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_strip.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/selection_info/selection_info.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'hud_command_dispatcher_city_research.dart';
part 'hud_command_dispatcher_panels.dart';
part 'hud_command_dispatcher_resources.dart';
part 'hud_command_dispatcher_selection.dart';
part 'hud_command_dispatcher_turn_flow.dart';

class HudCommandDispatcher {
  static const humanInteractionBlockedReason =
      'human turn interaction is blocked';

  const HudCommandDispatcher(this._ref);

  final Ref _ref;

  GameClientState? _currentGameState() {
    final saveId = _ref.read(activeGameSessionProvider)?.saveId;
    if (saveId == null || saveId.isEmpty) return null;
    return _ref.read(gameStateProvider(saveId)).value;
  }

  bool get _canInteract =>
      _ref.read(gamePlayerControlControllerProvider).canInteract;

  Future<void> dispatch(DomainCommand command) async {
    if (!_canInteract) return;
    await dispatchTransition(command);
  }

  Future<DispatchCommandResult> dispatchTransition(
    DomainCommand command,
  ) async {
    if (!_canInteract) return _blockedDispatchResult();
    _ref.read(mapInspectionControllerProvider.notifier).clear();
    return _ref
        .read(gameCommandControllerProvider.notifier)
        .dispatchTransition(command);
  }

  Future<void> dispatchIntent(GameIntent intent) async {
    if (!_canInteract) return;
    _ref.read(mapInspectionControllerProvider.notifier).clear();
    await _ref
        .read(gameCommandControllerProvider.notifier)
        .dispatchIntent(intent);
  }

  DispatchCommandResult _blockedDispatchResult() {
    return DispatchCommandResult(
      state: _currentGameState() ?? GameClientState(),
      accepted: false,
      rejectionReason: humanInteractionBlockedReason,
    );
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
    required GameClientState? state,
    String activePlayerId = '',
  }) {
    final command = HudPendingActionCommands.cancelResearchSelection(
      state: state,
      activePlayerId: activePlayerId,
    );
    if (command == null) return;
    unawaited(dispatchIntent(command));
  }

  void _cancelWorkerActionSelectionIfPending(GameClientState? state) {
    final command = HudPendingActionCommands.cancelWorkerActionSelection(state);
    if (command == null) return;
    unawaited(dispatchIntent(command));
  }
}
