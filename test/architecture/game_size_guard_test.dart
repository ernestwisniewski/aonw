import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Game size guards', () {
    test('new game files stay below max length or current baseline', () {
      expect(
        _lineCountViolations(
          root: 'lib/game',
          maxLines: 600,
          legacyLineCountBaseline: _legacyGameFileLineCountBaseline,
        ),
        isEmpty,
      );
    });

    test('game classes stay below max length or current baseline', () {
      expect(
        _classLineCountViolations(
          root: 'lib/game',
          maxLines: 350,
          legacyClassLineCountBaseline: _legacyGameClassLineCountBaseline,
        ),
        isEmpty,
      );
    });

    test('application use cases stay small enough to orchestrate', () {
      expect(
        _lineCountViolations(
          root: 'lib/game/application/use_cases',
          maxLines: 180,
          legacyLineCountBaseline: const {},
        ),
        isEmpty,
      );
    });
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

    violations.add(
      '$relativePath has $lineCount lines; max is ${legacyLimit ?? maxLines}',
    );
  }

  violations.sort();
  return violations;
}

List<String> _classLineCountViolations({
  required String root,
  required int maxLines,
  required Map<String, int> legacyClassLineCountBaseline,
}) {
  final violations = <String>[];

  for (final file in _dartFiles(root)) {
    final relativePath = _relativePath(file.path);
    for (final span in _classSpans(file)) {
      if (span.lineCount <= maxLines) continue;

      final key = '$relativePath::${span.name}';
      final legacyLimit = legacyClassLineCountBaseline[key];
      if (legacyLimit != null && span.lineCount <= legacyLimit) continue;

      violations.add(
        '$relativePath:${span.startLine} ${span.name} has '
        '${span.lineCount} lines; max is ${legacyLimit ?? maxLines}',
      );
    }
  }

  violations.sort();
  return violations;
}

Iterable<File> _dartFiles(String root) {
  final directory = Directory(root);
  if (!directory.existsSync()) return const [];
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart'))
      .where((file) => !file.path.endsWith('.freezed.dart'));
}

Iterable<_ClassSpan> _classSpans(File file) sync* {
  final lines = file.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    final declaration = _classDeclaration.firstMatch(lines[i]);
    if (declaration == null) continue;

    var depth = 0;
    var foundBody = false;
    var end = i;
    for (; end < lines.length; end++) {
      final code = _stripLineComment(lines[end]);
      for (final codeUnit in code.codeUnits) {
        if (codeUnit == _openBrace) {
          depth++;
          foundBody = true;
        } else if (codeUnit == _closeBrace && foundBody) {
          depth--;
        }
      }
      if (foundBody && depth <= 0) break;
    }

    yield _ClassSpan(
      name: declaration.group(1)!,
      startLine: i + 1,
      lineCount: end - i + 1,
    );
    i = end;
  }
}

String _stripLineComment(String line) {
  final commentStart = line.indexOf('//');
  return commentStart == -1 ? line : line.substring(0, commentStart);
}

String _relativePath(String path) {
  final root = '${Directory.current.path}${Platform.pathSeparator}';
  return path.startsWith(root) ? path.substring(root.length) : path;
}

final _classDeclaration = RegExp(
  r'^\s*(?:abstract\s+|base\s+|final\s+|sealed\s+|interface\s+|mixin\s+)*class\s+([A-Za-z_][A-Za-z0-9_]*)\b',
);

const _openBrace = 123;
const _closeBrace = 125;

final class _ClassSpan {
  final String name;
  final int startLine;
  final int lineCount;

  const _ClassSpan({
    required this.name,
    required this.startLine,
    required this.lineCount,
  });
}

const _legacyGameFileLineCountBaseline = <String, int>{
  'lib/game/analysis/human_trace_analyzer.dart': 664,
  'lib/game/analysis/human_trace_benchmark.dart': 712,
  'lib/game/domain/reducer/city/city_production_reducer.dart': 631,
  'lib/game/domain/reducer/combat/combat_reducer.dart': 627,
  'lib/game/domain/reducer/turn/turn_reducer.dart': 787,
  'lib/game/presentation/engine/game_event_renderer_effect_mapper.dart': 616,
  'lib/game/presentation/engine/game_renderer.dart': 601,
  'lib/game/presentation/engine/rendering_layers/action_palette/'
          'action_palette_component.dart':
      656,
  'lib/game/presentation/engine/rendering_layers/city/'
          'city_marker.dart':
      710,
  'lib/game/presentation/engine/rendering_layers/city/'
          'city_territory_overlay.dart':
      737,
  'lib/game/presentation/engine/rendering_layers/units/'
          'unit_marker_layer.dart':
      655,
  'lib/game/presentation/engine/rendering_layers/units/'
          'unit_move_preview.dart':
      782,
  'lib/game/presentation/formatters/game_display_names.dart': 638,
  'lib/game/presentation/formatters/'
          'game_event_notification_message.dart':
      1018,
  'lib/game/presentation/screens/game/game_screen.dart': 850,
  'lib/game/presentation/screens/lobby/lobby_screen.dart': 680,
  'lib/game/presentation/widgets/activity_log/turn_timeline_popup.dart': 678,
  'lib/game/presentation/widgets/bottom_toolbar/end_turn_button_content.dart':
      634,
  'lib/game/presentation/widgets/city/city_yield_breakdown_panel.dart': 731,
  'lib/game/presentation/widgets/empire/empire_overview_statistics.dart': 1025,
  'lib/game/presentation/widgets/hud/map/hud_map_inspection_menu.dart': 844,
  'lib/game/presentation/widgets/hud/mode_banner/hud_mode_banner.dart': 711,
  'lib/game/presentation/widgets/hud/overlay/hud_overlay_frame.dart': 622,
  'lib/game/presentation/widgets/options/game_options_overlay.dart': 785,
  'lib/game/presentation/widgets/screen/game_screen_state_views.dart': 613,
};

const _legacyGameClassLineCountBaseline = <String, int>{
  'lib/game/domain/reducer/city/city_production_reducer.dart::'
          'CityProductionReducer':
      612,
  'lib/game/domain/reducer/combat/combat_reducer.dart::CombatReducer': 557,
  'lib/game/domain/reducer/diplomacy/diplomacy_reducer.dart::'
          'DiplomacyReducer':
      492,
  'lib/game/domain/reducer/game_state/game_state_reducer.dart::'
          'GameStateReducer':
      413,
  'lib/game/domain/reducer/game_state/game_state_reducer_taps.dart::'
          '_GameStateTapReducer':
      416,
  'lib/game/domain/reducer/interaction/selection_reducer.dart::'
          'SelectionReducer':
      486,
  'lib/game/domain/reducer/movement/movement_reducer.dart::MovementReducer':
      471,
  'lib/game/domain/reducer/turn/turn_reducer.dart::TurnReducer': 696,
  'lib/game/presentation/controllers/lobby_connection_controller.dart::'
          'LobbyConnectionController':
      432,
  'lib/game/presentation/engine/game_event_renderer_effect_mapper.dart::'
          'GameEventRendererEffectMapper':
      603,
  'lib/game/presentation/engine/game_renderer.dart::GameRenderer': 507,
  'lib/game/presentation/engine/game_rendering_coordinator.dart::'
          'GameRenderingCoordinator':
      508,
  'lib/game/presentation/engine/recommended_city_site_planner.dart::'
          'RecommendedCitySitePlanner':
      402,
  'lib/game/presentation/engine/rendering_layers/action_palette/'
          'action_palette_component.dart::ActionPaletteComponent':
      633,
  'lib/game/presentation/engine/rendering_layers/city/'
          'city_management_overlay_layer.dart::CityManagementOverlayLayer':
      478,
  'lib/game/presentation/engine/rendering_layers/city/'
          'city_marker.dart::CityMarker':
      694,
  'lib/game/presentation/engine/rendering_layers/city/'
          'city_territory_overlay.dart::CityTerritoryOverlay':
      634,
  'lib/game/presentation/engine/rendering_layers/effects/'
          'cloud_drift_layer.dart::CloudDriftLayer':
      472,
  'lib/game/presentation/engine/rendering_layers/units/'
          'unit_marker.dart::UnitMarker':
      494,
  'lib/game/presentation/engine/rendering_layers/units/'
          'unit_marker_layer.dart::UnitMarkerLayer':
      635,
  'lib/game/presentation/engine/rendering_layers/units/'
          'unit_marker_renderer.dart::UnitMarkerRenderer':
      500,
  'lib/game/presentation/engine/rendering_layers/units/'
          'unit_move_preview.dart::UnitMovePreview':
      766,
  'lib/game/presentation/formatters/diplomacy_history_presenter.dart::'
          'DiplomacyHistoryPresenter':
      381,
  'lib/game/presentation/formatters/game_display_names.dart::'
          'GameDisplayNames':
      629,
  'lib/game/presentation/formatters/game_event_notification_message.dart::'
          '_GameEventNotificationMessageFormatter':
      402,
  'lib/game/presentation/providers/game/game_actions_provider.dart::'
          'GameCommandController':
      451,
  'lib/game/presentation/providers/game/game_state_provider.dart::'
          'GameStateNotifier':
      464,
  'lib/game/presentation/screens/game/game_screen.dart::'
          '_GameRendererSessionHostState':
      438,
  'lib/game/presentation/screens/lobby/lobby_screen.dart::_LobbyScreenState':
      609,
  'lib/game/presentation/screens/new_game/new_game_screen.dart::'
          '_NewGameScreenState':
      400,
  'lib/game/presentation/widgets/diplomacy/'
          'diplomatic_message_popup_overlay.dart::'
          '_DiplomaticMessagePopupOverlayState':
      534,
  'lib/game/presentation/widgets/hud/outcome/'
          'hud_victory_status_summary.dart::HudVictoryStatusSummary':
      401,
  'lib/game/presentation/widgets/hud/overlay/hud_overlay_frame.dart::'
          'HudOverlayFrame':
      581,
  'lib/game/presentation/widgets/options/game_options_overlay.dart::'
          '_GameOptionsOverlayState':
      507,
  'lib/game/presentation/widgets/selection/view_models/'
          'selection_resource_value_card_factory.dart::'
          'SelectionResourceValueCardFactory':
      454,
};
