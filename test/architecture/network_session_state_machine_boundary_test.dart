import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _stateMachinePath =
    'lib/game/application/services/network_session_state_machine.dart';
const _providerPath =
    'lib/game/presentation/providers/session/repository_providers.dart';

void main() {
  test('network session mutations use one reducer and effect runner', () {
    final stateMachine = File(_stateMachinePath).readAsStringSync();
    final provider = File(_providerPath).readAsStringSync();

    expect(stateMachine, contains('final class NetworkSessionTransportState'));
    expect(stateMachine, contains('final class NetworkSessionReducer'));
    expect(stateMachine, contains('final class NetworkSessionEffectRunner'));
    expect(provider, contains('.reduce(state, action)'));
    expect(provider, contains('.runAll(transition.effects)'));
  });

  test('presentation does not persist or publish transport state directly', () {
    const allowedPaths = {
      _providerPath,
      'lib/game/presentation/providers/multiplayer/'
          'multiplayer_connection_status_provider.dart',
    };
    final violations = <String>[];
    for (final root in ['lib/game', 'lib/menu']) {
      for (final entry in Directory(root).listSync(recursive: true)) {
        if (entry is! File || !entry.path.endsWith('.dart')) continue;
        final path = entry.path.replaceAll('\\', '/');
        if (allowedPaths.contains(path)) continue;
        final lines = entry.readAsLinesSync();
        for (var index = 0; index < lines.length; index++) {
          final line = lines[index];
          if (line.contains('.saveMatchId(') || line.contains('.setStatus(')) {
            violations.add('$path:${index + 1} $line');
          }
        }
      }
    }

    expect(violations, isEmpty);
  });
}
