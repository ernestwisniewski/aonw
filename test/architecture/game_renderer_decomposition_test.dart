import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _rendererDirectory = 'lib/game/presentation/engine';
const _rendererPath = '$_rendererDirectory/game_renderer.dart';

void main() {
  test('GameRenderer delegates its five runtime responsibilities', () {
    final source = File(_rendererPath).readAsStringSync();
    const modules = {
      'game_renderer_input.dart': 'mixin GameRendererInput',
      'game_renderer_camera.dart': 'mixin GameRendererCamera',
      'game_renderer_state_sync.dart': 'mixin GameRendererStateSync',
      'game_renderer_transitions.dart': 'mixin GameRendererTransitions',
      'game_renderer_lifecycle.dart': 'mixin GameRendererLifecycle',
    };

    for (final entry in modules.entries) {
      expect(source, contains("part '${entry.key}';"), reason: entry.key);
      final moduleSource = File(
        '$_rendererDirectory/${entry.key}',
      ).readAsStringSync();
      expect(moduleSource, contains(entry.value), reason: entry.key);
    }

    expect(source.split('\n'), hasLength(lessThan(250)));
    expect(source, isNot(contains('void handleViewportPointerDown(')));
    expect(source, isNot(contains('void setZoom(')));
    expect(source, isNot(contains('void applyState(')));
    expect(source, isNot(contains('Future<void> applyTransition(')));
    expect(source, isNot(contains('Future<void> buildWorld(')));

    for (final removedFile in const [
      'game_renderer_state_application.dart',
      'game_renderer_transition_queue.dart',
      'game_renderer_world_lifecycle.dart',
    ]) {
      expect(
        File('$_rendererDirectory/$removedFile').existsSync(),
        isFalse,
        reason: removedFile,
      );
    }
  });
}
