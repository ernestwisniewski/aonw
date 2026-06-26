import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('game and shared UI widgets do not use raw color alpha', () {
    expect(
      _rawAlphaViolations(
        roots: const [
          'lib/game/presentation/widgets',
          'lib/shared/widgets/game_ui',
        ],
      ),
      isEmpty,
    );
  });
}

List<String> _rawAlphaViolations({required List<String> roots}) {
  final violations = <String>[];
  final rawAlphaPattern = RegExp(r'\.withAlpha\(\d+\)');

  for (final file in roots.expand(_dartFiles)) {
    final relativePath = _relativePath(file.path);
    final lines = file.readAsLinesSync();
    final legacyCount = _legacyRawAlphaBaseline[relativePath] ?? 0;
    var rawAlphaCount = 0;
    for (var i = 0; i < lines.length; i++) {
      if (rawAlphaPattern.hasMatch(lines[i])) {
        rawAlphaCount++;
        if (rawAlphaCount <= legacyCount) continue;
        violations.add('$relativePath:${i + 1} use SurfaceElevation helpers');
      }
    }
  }

  return violations;
}

const _legacyRawAlphaBaseline = <String, int>{
  'lib/game/presentation/widgets/city/city_yield_breakdown_panel.dart': 1,
  'lib/game/presentation/widgets/diplomacy/civilization_met_popup_overlay.dart':
      1,
  'lib/game/presentation/widgets/empire/empire_overview_statistics.dart': 4,
  'lib/game/presentation/widgets/hud/action_deck/hud_action_deck_combat_modal.dart':
      10,
  'lib/game/presentation/widgets/hud/outcome/hud_game_outcome_overlay.dart': 8,
  'lib/game/presentation/widgets/hud/map/hud_map_inspection_menu.dart': 21,
  'lib/game/presentation/widgets/hud/overlay/turn_start_banner_overlay.dart': 9,
  'lib/game/presentation/widgets/multiplayer/multiplayer_avatar_tile.dart': 2,
  'lib/game/presentation/widgets/multiplayer/multiplayer_status_sheet.dart': 6,
  'lib/game/presentation/widgets/options/game_options_overlay.dart': 1,
  'lib/game/presentation/widgets/resources/resource_breakdown_popup_widgets.dart':
      2,
  'lib/game/presentation/widgets/resources/victory_status_popup.dart': 2,
  'lib/game/presentation/widgets/screen/game_screen_state_views.dart': 35,
  'lib/game/presentation/widgets/visual/game_insight_widgets.dart': 6,
  'lib/shared/widgets/game_ui/game_color_picker.dart': 4,
  'lib/shared/widgets/game_ui/game_toast.dart': 3,
  'lib/shared/widgets/game_ui/game_ui_epic_header.dart': 8,
  'lib/shared/widgets/game_ui/game_ui_screen_header.dart': 3,
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
