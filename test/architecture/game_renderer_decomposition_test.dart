import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _rendererDirectory = 'lib/game/presentation/engine';
const _rendererPath = '$_rendererDirectory/game_renderer.dart';

void main() {
  test('GameRenderer composes its five runtime responsibilities', () {
    final source = File(_rendererPath).readAsStringSync();
    const services = {
      'game_renderer_input_handler.dart': 'class GameRendererInputHandler',
      'game_renderer_camera_settings.dart':
          'class GameRendererCameraSettings',
      'game_renderer_state_sync_handler.dart':
          'class GameRendererStateSyncHandler',
      'game_renderer_transition_handler.dart':
          'class GameRendererTransitionHandler',
      'game_renderer_lifecycle_handler.dart':
          'class GameRendererLifecycleHandler',
    };

    for (final entry in services.entries) {
      expect(
        source,
        contains("engine/${entry.key}';"),
        reason: entry.key,
      );
      final serviceSource = File(
        '$_rendererDirectory/${entry.key}',
      ).readAsStringSync();
      expect(serviceSource, contains(entry.value), reason: entry.key);
      expect(serviceSource, isNot(contains("part of 'game_renderer.dart';")));
    }

    expect(source.split('\n'), hasLength(lessThan(500)));
    expect(source, contains('GameRendererInputHandler inputHandler'));
    expect(source, contains('GameRendererCameraSettings _cameraSettings'));
    expect(source, contains('GameRendererStateSyncHandler _stateSyncHandler'));
    expect(source, contains('GameRendererTransitionHandler _transitionHandler'));
    expect(source, contains('GameRendererLifecycleHandler _lifecycleHandler'));

    for (final removedPart in const [
      'game_renderer_input.dart',
      'game_renderer_camera.dart',
      'game_renderer_state_sync.dart',
      'game_renderer_transitions.dart',
      'game_renderer_lifecycle.dart',
    ]) {
      expect(source, isNot(contains("part '$removedPart';")));
      expect(
        File('$_rendererDirectory/$removedPart').existsSync(),
        isFalse,
        reason: removedPart,
      );
    }

    for (final legacyFile in const [
      'game_renderer_state_application.dart',
      'game_renderer_transition_queue.dart',
      'game_renderer_world_lifecycle.dart',
    ]) {
      expect(
        File('$_rendererDirectory/$legacyFile').existsSync(),
        isFalse,
        reason: legacyFile,
      );
    }
  });
}
