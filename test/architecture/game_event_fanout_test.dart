import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GameEvent type fanout stays inside the architecture allowlist', () {
    final eventTypes = _gameEventTypes();

    expect(
      _fanoutViolations(
        roots: const ['lib', 'packages/aonw_core/lib', 'server/lib'],
        gameEventTypes: eventTypes,
      ),
      isEmpty,
    );
  });
}

List<String> _fanoutViolations({
  required List<String> roots,
  required Set<String> gameEventTypes,
}) {
  final violations = <String>[];
  for (final file in roots.expand(_dartFiles)) {
    final relativePath = _relativePath(file.path);
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_switchEventPattern.hasMatch(line) &&
          !_allowedSwitchEventPaths.contains(relativePath)) {
        violations.add(
          '$relativePath:${i + 1} move switch(event) into GameEventDescriptor',
        );
      }

      for (final match in _eventIsPattern.allMatches(line)) {
        final typeName = match.group(1);
        if (typeName == null || !gameEventTypes.contains(typeName)) continue;
        if (_allowedEventIsPaths.contains(relativePath)) continue;
        violations.add(
          '$relativePath:${i + 1} move "$typeName" check into GameEventDescriptor',
        );
      }
    }
  }
  return violations;
}

Set<String> _gameEventTypes() {
  final types = <String>{};
  for (final file in _dartFiles('packages/aonw_core/lib/game/domain/event')) {
    final source = file.readAsStringSync();
    for (final match in _gameEventClassPattern.allMatches(source)) {
      types.add(match.group(1)!);
    }
  }
  return types;
}

Iterable<File> _dartFiles(String root) {
  final directory = Directory(root);
  if (!directory.existsSync()) return const [];
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart'))
      .where((file) => !file.path.endsWith('.freezed.dart'))
      .where((file) => !file.path.contains('/generated/'));
}

String _relativePath(String path) {
  final root = '${Directory.current.path}${Platform.pathSeparator}';
  return path.startsWith(root) ? path.substring(root.length) : path;
}

final _switchEventPattern = RegExp(r'switch\s*\(\s*event\s*\)');
final _eventIsPattern = RegExp(
  r'\bevent\s+is\s+([A-Za-z_][A-Za-z0-9_]*Event)\b',
);
final _gameEventClassPattern = RegExp(
  r'(?:abstract\s+|base\s+|final\s+|sealed\s+|interface\s+)*class\s+'
  r'([A-Za-z_][A-Za-z0-9_]*Event)\s+extends\s+GameEvent\b',
);

const _allowedSwitchEventPaths = {
  // The central descriptor factory is the only production event switch.
  'lib/game/application/services/game_event_descriptor.dart',

  // Serialization is an explicit architecture exception.
  'packages/aonw_core/lib/game/domain/event/event_serialization.dart',

  // Legacy fanout that should be migrated behind GameEventDescriptor.
  'lib/game/analysis/human_trace_analyzer.dart',
  'lib/game/application/services/ai_recent_hostility_tracker.dart',
  'lib/game/presentation/formatters/diplomacy_history_presenter.dart',
  'lib/game/presentation/formatters/game_event_notification_city_messages.dart',
  'lib/game/presentation/formatters/game_event_notification_combat_messages.dart',
  'lib/game/presentation/formatters/game_event_notification_message.dart',
  'lib/game/presentation/widgets/diplomacy/diplomatic_popup_event_policy.dart',
  'packages/aonw_core/lib/ai/simulation/economy_simulation_hostility_memory.dart',
  'packages/aonw_core/lib/game/domain/stability/persistent_stability_processor.dart',
  'packages/aonw_core/lib/game/domain/telemetry/balance_telemetry_player_activity.dart',
};

const _allowedEventIsPaths = {
  // Legacy fanout that should be migrated behind GameEventDescriptor.
  'lib/game/presentation/providers/game/game_actions_provider_turns.dart',
  'lib/game/presentation/providers/game/game_state_provider_renderer_effects.dart',
  'lib/game/presentation/services/hidden_ai_command_presenter.dart',
  'lib/game/presentation/widgets/activity_log/activity_log_filter.dart',
  'lib/game/presentation/widgets/diplomacy/civilization_met_popup_overlay.dart',
  'lib/game/presentation/widgets/diplomacy/diplomatic_message_popup_overlay.dart',
  'lib/game/presentation/widgets/diplomacy/diplomatic_popup_event_policy.dart',
  'lib/game/presentation/widgets/hud/notifications/game_event_notifications_overlay.dart',
  'packages/aonw_core/lib/game/domain/telemetry/balance_telemetry_player_activity.dart',
};
