import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _providerDirectory = 'lib/game/presentation/providers/game';
const _providerPath = '$_providerDirectory/game_state_provider.dart';

void main() {
  test('GameStateNotifier delegates its four runtime responsibilities', () {
    final source = File(_providerPath).readAsStringSync();
    const services = {
      'game_state_provider_application_bootstrap.dart':
          'GameStateApplicationBootstrap',
      'game_state_provider_commands.dart': 'GameStateCommands',
      'game_state_provider_multiplayer_sync.dart': 'GameStateMultiplayerSync',
      'game_state_effects.dart': 'GameStateEffects',
    };

    for (final entry in services.entries) {
      expect(source, contains(entry.value), reason: entry.key);
      final serviceSource = File(
        '$_providerDirectory/${entry.key}',
      ).readAsStringSync();
      expect(serviceSource, contains('final class ${entry.value}'));
      expect(
        serviceSource,
        isNot(contains("part of 'game_state_provider.dart'")),
      );
    }

    expect(
      RegExp(
        r"^part '(?!game_state_provider\.g\.dart)",
        multiLine: true,
      ).hasMatch(source),
      isFalse,
    );

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
