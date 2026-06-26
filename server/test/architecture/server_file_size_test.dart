import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('large server multiplayer files cannot regrow past baseline', () {
    expect(_lineCountViolations(_largeFileBaseline), isEmpty);
  });
}

List<String> _lineCountViolations(Map<String, int> baseline) {
  final violations = <String>[];
  for (final entry in baseline.entries) {
    final file = File(entry.key);
    final lineCount = file.readAsLinesSync().length;
    if (lineCount > entry.value) {
      violations.add(
        '${entry.key} has $lineCount lines; max is ${entry.value}',
      );
    }
  }
  return violations;
}

const _largeFileBaseline = <String, int>{
  'lib/src/multiplayer/multiplayer_endpoint.dart': 429,
  'lib/src/multiplayer/matchmaking_service.dart': 324,
  'lib/src/multiplayer/match_lifecycle_service.dart': 354,
  'lib/src/multiplayer/match_command_service.dart': 180,
  'lib/src/multiplayer/match_connection_registry.dart': 281,
  'lib/src/multiplayer/match_query_service.dart': 40,
  'lib/src/multiplayer/match_broadcaster.dart': 49,
  'lib/src/multiplayer/match_state_access.dart': 75,
};
