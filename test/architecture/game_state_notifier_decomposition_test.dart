import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _providerDirectory = 'lib/game/presentation/providers/game';
const _providerPath = '$_providerDirectory/game_state_provider.dart';

void main() {
  test('GameStateNotifier delegates its four runtime responsibilities', () {
    final source = File(_providerPath).readAsStringSync();
    const parts = {
      'game_state_provider_application_bootstrap.dart':
          'GameStateNotifierApplicationBootstrap',
      'game_state_provider_commands.dart': 'GameStateNotifierCommands',
      'game_state_provider_multiplayer_sync.dart':
          'GameStateNotifierMultiplayerSync',
      'game_state_provider_effects.dart': 'GameStateNotifierEffects',
    };

    for (final entry in parts.entries) {
      expect(source, contains("part '${entry.key}';"), reason: entry.key);
      final partSource = File(
        '$_providerDirectory/${entry.key}',
      ).readAsStringSync();
      expect(partSource, contains('extension ${entry.value}'));
    }

    expect(source.split('\n'), hasLength(lessThan(100)));
    expect(
      File(
        '$_providerDirectory/game_state_provider_turn_lifecycle.dart',
      ).existsSync(),
      isFalse,
    );
    expect(
      File(
        '$_providerDirectory/game_state_provider_renderer_effects.dart',
      ).existsSync(),
      isFalse,
    );
  });
}
