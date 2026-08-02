import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('API adapters do not re-export application-owned contracts', () {
    expect(
      _packageExportViolations(
        roots: const ['lib/api'],
        forbiddenPrefix: 'package:aonw/game/application/',
      ),
      isEmpty,
    );
  });

  test('app libraries do not facade aonw_core domain entrypoints', () {
    expect(
      _packageExportViolations(
        roots: const ['lib/game', 'lib/map'],
        forbiddenPrefix: 'package:aonw_core/',
      ),
      isEmpty,
    );
  });

  test('server implementation facades do not re-export capabilities', () {
    for (final path in const {
      'server/lib/src/multiplayer/matchmaking_service.dart',
      'server/lib/src/multiplayer/multiplayer_match_store.dart',
      'server/lib/src/multiplayer/running_match_snapshot_codec.dart',
      'server/lib/src/multiplayer/server_command_reducer.dart',
    }) {
      expect(
        _exportsFrom(File(path)),
        isEmpty,
        reason: '$path must expose only declarations it owns.',
      );
    }
  });

  test('obsolete compatibility entrypoints stay removed', () {
    for (final path in const {
      'lib/api/session/auth_token.dart',
      'lib/api/session/connection_state.dart',
      'lib/api/session/network_session.dart',
      'lib/api/session/network_session_state_machine.dart',
      'lib/api/transport/live_server_event.dart',
      'lib/api/transport/live_wire_command_dispatcher.dart',
      'lib/api/transport/multiplayer_snapshot_cache_key.dart',
      'lib/game/domain/city.dart',
      'lib/game/domain/game_save.dart',
      'lib/map/domain/hex_grid_topology.dart',
      'lib/map/domain/map_config.dart',
      'lib/map/domain/map_constraints.dart',
      'lib/map/domain/map_selection.dart',
      'lib/map/domain/map_view_mode.dart',
      'lib/map/domain/terrain_type.dart',
    }) {
      expect(File(path).existsSync(), isFalse, reason: '$path must stay gone.');
    }
  });
}

List<String> _packageExportViolations({
  required List<String> roots,
  required String forbiddenPrefix,
}) {
  final violations = <String>[];
  for (final root in roots) {
    for (final file in Directory(root).listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      for (final uri in _exportsFrom(file)) {
        if (uri.startsWith(forbiddenPrefix)) {
          violations.add('${file.path}: $uri');
        }
      }
    }
  }
  return violations..sort();
}

List<String> _exportsFrom(File file) {
  final unit = parseString(
    content: file.readAsStringSync(),
    path: file.path,
    throwIfDiagnostics: false,
  ).unit;
  return unit.directives
      .whereType<ExportDirective>()
      .map((directive) => directive.uri.stringValue)
      .whereType<String>()
      .toList();
}
