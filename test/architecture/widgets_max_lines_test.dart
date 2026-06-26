import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('game presentation widgets stay below max file length', () {
    expect(
      _lineCountViolations(
        root: 'lib/game/presentation/widgets',
        maxLines: 350,
        legacyLineCountBaseline: _legacyWidgetLineCountBaseline,
      ),
      isEmpty,
    );
  });

  test('game presentation screens cannot grow past refactor baselines', () {
    expect(
      _lineCountViolations(
        root: 'lib/game/presentation/screens',
        maxLines: 350,
        legacyLineCountBaseline: _legacyScreenLineCountBaseline,
      ),
      isEmpty,
    );
  });
}

List<String> _lineCountViolations({
  required String root,
  required int maxLines,
  required Map<String, int> legacyLineCountBaseline,
}) {
  final violations = <String>[];

  for (final file in _dartFiles(root)) {
    final relativePath = _relativePath(file.path);
    final lineCount = file.readAsLinesSync().length;
    if (lineCount <= maxLines) continue;

    final legacyLimit = legacyLineCountBaseline[relativePath];
    if (legacyLimit != null && lineCount <= legacyLimit) continue;

    final limit = legacyLimit ?? maxLines;
    if (lineCount > limit) {
      violations.add('$relativePath has $lineCount lines; max is $limit');
    }
  }

  return violations;
}

const _legacyWidgetLineCountBaseline = <String, int>{
  'lib/game/presentation/widgets/options/game_options_overlay.dart': 926,
  'lib/game/presentation/widgets/unit/unit_details_panel.dart': 361,
  'lib/game/presentation/widgets/city/city_yield_breakdown_panel.dart': 731,
  'lib/game/presentation/widgets/city/city_production_dialog_view_model.dart':
      482,
  'lib/game/presentation/widgets/city/city_yield_breakdown_view_model.dart':
      484,
  'lib/game/presentation/widgets/city/city_production_dialog.dart': 441,
  'lib/game/presentation/widgets/diplomacy/civilization_met_popup_overlay.dart':
      455,
  'lib/game/presentation/widgets/diplomacy/'
          'diplomacy_player_modal_primitives.dart':
      428,
  'lib/game/presentation/widgets/diplomacy/'
          'diplomatic_message_popup_overlay.dart':
      584,
  'lib/game/presentation/widgets/bottom_toolbar/end_turn_button.dart': 408,
  'lib/game/presentation/widgets/bottom_toolbar/end_turn_button_content.dart':
      634,
  'lib/game/presentation/widgets/technology/technology_tree_dialog.dart': 533,
  'lib/game/presentation/widgets/technology/technology_recommendations_view.dart':
      409,
  'lib/game/presentation/widgets/resources/top_resource_pill.dart': 366,
  'lib/game/presentation/widgets/activity_log/turn_timeline_popup.dart': 678,
  'lib/game/presentation/widgets/ai/game_ai_turn_auto_pilot.dart': 313,
  'lib/game/presentation/widgets/visual/game_insight_widgets.dart': 550,
  'lib/game/presentation/widgets/screen/game_screen_state_views.dart': 613,
  'lib/game/presentation/widgets/selection/view_models/'
          'selection_resource_value_card_factory.dart':
      514,
  'lib/game/presentation/widgets/selection/selection_command_chip.dart': 371,
  'lib/game/presentation/widgets/empire/empire_overview_statistics.dart': 1025,
  'lib/game/presentation/widgets/selection_info/contents/'
          'worker_action_selection_detail_content.dart':
      489,
  'lib/game/presentation/widgets/selection_info/contents/'
          'buildings_detail_content.dart':
      558,
  'lib/game/presentation/widgets/selection_info/contents/'
          'resources_detail_content.dart':
      412,
  'lib/game/presentation/widgets/multiplayer/multiplayer_status_sheet.dart':
      444,
  'lib/game/presentation/widgets/multiplayer/multiplayer_avatars_rail.dart':
      376,
  'lib/game/presentation/widgets/hud/map/hud_map_inspection_menu.dart': 870,
  'lib/game/presentation/widgets/hud/combat/hud_combat_preview.dart': 486,
  'lib/game/presentation/widgets/hud/objective/game_objectives_overlay.dart':
      586,
  'lib/game/presentation/widgets/hud/overlay/hud_overlay_frame.dart': 644,
  'lib/game/presentation/widgets/hud/game_hud.dart': 416,
  'lib/game/presentation/widgets/hud/overlay/game_hud_overlay_host.dart': 370,
  'lib/game/presentation/widgets/hud/turn/turn_action_hint.dart': 370,
  'lib/game/presentation/widgets/hud/outcome/hud_victory_status_summary.dart':
      617,
  'lib/game/presentation/widgets/hud/mode_banner/hud_mode_banner.dart': 711,
  'lib/game/presentation/widgets/hud/outcome/hud_game_outcome_summary.dart':
      355,
};

const _legacyScreenLineCountBaseline = <String, int>{
  'lib/game/presentation/screens/lobby/lobby_screen.dart': 1124,
  'lib/game/presentation/screens/new_game/new_game_screen.dart': 1881,
  'lib/game/presentation/screens/game/game_screen.dart': 852,
  'lib/game/presentation/screens/replay/replay_screen.dart': 1398,
  'lib/game/presentation/screens/game/load_game_screen.dart': 360,
};

Iterable<File> _dartFiles(String root) {
  final directory = Directory(root);
  if (!directory.existsSync()) return const [];
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart'));
}

String _relativePath(String path) {
  final root = '${Directory.current.path}${Platform.pathSeparator}';
  return path.startsWith(root) ? path.substring(root.length) : path;
}
