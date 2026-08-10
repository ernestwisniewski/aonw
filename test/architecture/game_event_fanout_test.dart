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
  // Central application and domain descriptor factories.
  'lib/game/application/services/game_event_descriptor.dart',
  'lib/game/application/services/game_event_descriptor_fortification.dart',
  'packages/aonw_core/lib/game/domain/event/game_event_domain_descriptor.dart',
  'packages/aonw_core/lib/game/domain/event/'
      'fortification_event_domain_descriptor.dart',

  // Serialization is an explicit architecture exception.
  'packages/aonw_core/lib/game/domain/event/artifact_event_serialization.dart',
  'packages/aonw_core/lib/game/domain/event/city_event_serialization.dart',
  'packages/aonw_core/lib/game/domain/event/combat_event_serialization.dart',
  'packages/aonw_core/lib/game/domain/event/'
      'diplomacy_event_serialization.dart',
  'packages/aonw_core/lib/game/domain/event/event_serialization.dart',
  'packages/aonw_core/lib/game/domain/event/progress_event_serialization.dart',
  'packages/aonw_core/lib/game/domain/event/system_event_serialization.dart',
  'packages/aonw_core/lib/game/domain/event/unit_event_serialization.dart',

  // Legacy fanout that should be migrated behind GameEventDescriptor.
  'lib/game/presentation/engine/artifact_event_renderer_effect_mapper.dart',
  'lib/game/presentation/formatters/diplomacy_history_presenter.dart',
  'lib/game/presentation/formatters/game_event_notification_city_messages.dart',
  'lib/game/presentation/formatters/game_event_notification_combat_messages.dart',
  'lib/game/presentation/formatters/game_event_notification_message.dart',
};

const _allowedEventIsPaths = <String>{};
