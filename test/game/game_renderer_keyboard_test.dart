import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw/game/presentation/engine/artifact_marker_tap_cycle.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_option.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_management_overlay.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/game_intent_test_resolver.dart';
import 'support/game_renderer_keyboard_shared_fixtures.dart';

part 'game_renderer_keyboard_movement_fixture.dart';
part 'support/game_renderer_keyboard_pan_scenarios.dart';
part 'support/game_renderer_bridge_interaction_scenarios.dart';
part 'support/game_renderer_bridge_interaction_tap_priority_scenarios.dart';
part 'support/game_renderer_bridge_interaction_objective_city_scenarios.dart';
part 'support/game_renderer_bridge_state_sync_scenarios.dart';
part 'support/game_renderer_bridge_transition_scenarios.dart';
part 'support/game_renderer_bridge_transition_movement_scenarios.dart';
part 'support/game_renderer_bridge_transition_focus_selection_scenarios.dart';
part 'support/game_renderer_bridge_visual_density_scenarios.dart';
part 'support/game_renderer_bridge_action_palette_scenarios.dart';
part 'support/game_renderer_bridge_action_palette_selection_palette_scenarios.dart';
part 'support/game_renderer_bridge_action_palette_target_confirmation_scenarios.dart';
part 'support/game_renderer_bridge_planning_scenarios.dart';
part 'support/game_renderer_bridge_planning_city_sites_scenarios.dart';
part 'support/game_renderer_bridge_planning_worker_hints_scenarios.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _registerKeyboardPanScenarios();
  group('GameRenderer renderer bridge', () {
    _registerRendererInteractionScenarios();
    _registerRendererStateSyncScenarios();
    _registerRendererTransitionScenarios();
    _registerRendererVisualDensityScenarios();
    _registerRendererActionPaletteScenarios();
    _registerRendererPlanningScenarios();
  });
}
