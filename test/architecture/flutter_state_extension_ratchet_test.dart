import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _reviewedStateExtensions = {
  'lib/developer/assets_editor_models.dart:'
      '_AssetsEditorAdjustmentQueries on _AssetsEditorScreenState',
  'lib/editor/map_editor_screen_lifecycle.dart:'
      '_MapEditorScreenLifecycle on _MapEditorScreenState',
  'lib/editor/map_editor_screen_persistence_support.dart:'
      '_MapEditorScreenPersistenceSupport on _MapEditorScreenState',
  'lib/game/presentation/screens/game/game_screen_renderer_lifecycle.dart:'
      '_GameScreenRendererLifecycle on _GameRendererSessionHostState',
  'lib/game/presentation/screens/lobby/lobby_screen_map_capacity.dart:'
      '_LobbyScreenMapCapacity on _LobbyScreenState',
  'lib/game/presentation/screens/lobby/lobby_screen_multiplayer_panel_builder.dart:'
      '_LobbyScreenMultiplayerPanelBuilder on _LobbyScreenState',
  'lib/game/presentation/screens/lobby/lobby_screen_session_actions.dart:'
      '_LobbyScreenSessionActions on _LobbyScreenState',
  'lib/game/presentation/screens/lobby/lobby_screen_state_actions.dart:'
      '_LobbyScreenStateActions on _LobbyScreenState',
  'lib/game/presentation/screens/lobby/lobby_screen_state_lifecycle.dart:'
      '_LobbyScreenStateLifecycle on _LobbyScreenState',
  'lib/game/presentation/screens/lobby/lobby_screen_state_view.dart:'
      '_LobbyScreenStateView on _LobbyScreenState',
  'lib/game/presentation/screens/new_game/new_game_screen_content.dart:'
      '_NewGameScreenContent on _NewGameScreenState',
  'lib/game/presentation/screens/replay/replay_renderer_host_controls.dart:'
      '_ReplayRendererHostControls on _ReplayRendererHostState',
  'lib/game/presentation/screens/replay/replay_renderer_host_lifecycle.dart:'
      '_ReplayRendererHostLifecycle on _ReplayRendererHostState',
  'lib/game/presentation/widgets/activity_log/turn_timeline_popup_gamepad.dart:'
      '_TurnTimelinePopupGamepad on _TurnTimelinePopupState',
  'lib/game/presentation/widgets/city/city_production_panel_details.dart:'
      '_CityProductionPanelDetails on _CityProductionPanelState',
  'lib/game/presentation/widgets/diplomacy/diplomatic_popup_presentation.dart:'
      '_PopupPresentation on _DiplomaticMessagePopupOverlayState',
  'lib/game/presentation/widgets/hud/action_deck/hud_action_deck_auto_flow.dart:'
      '_HudActionDeckAutoFlow on _HudActionDeckState',
  'lib/game/presentation/widgets/hud/action_deck/hud_action_deck_auto_flow_predicates.dart:'
      '_HudActionDeckAutoFlowPredicates on _HudActionDeckState',
  'lib/game/presentation/widgets/hud/action_deck/hud_action_deck_combat_modal.dart:'
      '_HudActionDeckCombatModal on _HudActionDeckState',
  'lib/game/presentation/widgets/hud/action_deck/hud_action_deck_commands.dart:'
      '_HudActionDeckCommands on _HudActionDeckState',
  'lib/game/presentation/widgets/hud/action_deck/hud_action_deck_detail_modal.dart:'
      '_HudActionDeckDetailModal on _HudActionDeckState',
  'lib/game/presentation/widgets/hud/action_deck/hud_action_deck_gamepad_focus.dart:'
      '_HudActionDeckGamepadFocus on _HudActionDeckState',
  'lib/game/presentation/widgets/hud/action_deck/hud_action_deck_layout.dart:'
      '_HudActionDeckLayout on _HudActionDeckState',
  'lib/game/presentation/widgets/hud/action_deck/hud_action_deck_modals.dart:'
      '_HudActionDeckModals on _HudActionDeckState',
  'lib/game/presentation/widgets/hud/game_hud_chrome.dart:'
      '_GameHudGamepadFocusTargets on _GameHudState',
  'lib/game/presentation/widgets/hud/game_hud_chrome.dart:'
      '_GameHudLifecycleActions on _GameHudState',
  'lib/game/presentation/widgets/hud/game_hud_chrome.dart:'
      '_GameHudNetworkActions on _GameHudState',
  'lib/game/presentation/widgets/hud/game_hud_handoff.dart:'
      '_GameHudHandoffHelpers on _GameHudState',
  'lib/game/presentation/widgets/hud/overlay/game_hud_overlay_host_gamepad_focus.dart:'
      '_GameHudOverlayHostGamepadFocus on _GameHudOverlayHostState',
  'lib/game/presentation/widgets/hud/overlay/game_hud_overlay_host_helpers.dart:'
      '_GameHudOverlayHostHelpers on _GameHudOverlayHostState',
  'lib/game/presentation/widgets/multiplayer/multiplayer_avatars_rail_gamepad.dart:'
      '_MultiplayerAvatarsRailOverlayGamepad '
      'on _MultiplayerAvatarsRailOverlayState',
  'lib/game/presentation/widgets/options/game_options_overlay_side_menu.dart:'
      '_GameOptionsOverlaySideMenu on _GameOptionsOverlayState',
  'lib/game/presentation/widgets/options/game_options_overlay_state_transitions.dart:'
      '_GameOptionsOverlayStateTransitions on _GameOptionsOverlayState',
  'lib/game/presentation/widgets/technology/technology_tree_panel_details.dart:'
      '_TechnologyTreePanelDetails on _TechnologyTreePanelState',
  'lib/game/presentation/widgets/technology/technology_tree_panel_gamepad_selection.dart:'
      '_TechnologyTreePanelGamepadSelection on _TechnologyTreePanelState',
  'lib/menu/main_menu_panel_items.dart:'
      '_MenuPanelItems on _MenuPanelState',
};

final _stateExtensionPattern = RegExp(
  r'^extension\s+([A-Za-z0-9_]+)\s+on\s+(_[A-Za-z0-9_]+State)\b',
  multiLine: true,
);

void main() {
  test('new Flutter State responsibilities are not hidden in extensions', () {
    final current = <String>{};

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) {
        continue;
      }

      final source = entity.readAsStringSync();
      for (final match in _stateExtensionPattern.allMatches(source)) {
        current.add('${entity.path}:${match[1]} on ${match[2]}');
      }
    }

    final unreviewed = current.difference(_reviewedStateExtensions).toList()
      ..sort();
    expect(
      unreviewed,
      isEmpty,
      reason:
          'Prefer an explicit collaborator or a method owned by the State. '
          'Only extend this ratchet after an architectural review.',
    );
  });
}
