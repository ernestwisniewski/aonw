import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('save AI benchmark uses only the canonical snapshot boundary', () {
    final sources = <String, String>{};
    for (final entity in Directory(
      'tool/run_save_ai_benchmark',
    ).listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        sources[entity.path] = entity.readAsStringSync();
      }
    }
    sources['tool/run_save_ai_benchmark.dart'] = File(
      'tool/run_save_ai_benchmark.dart',
    ).readAsStringSync();

    final combined = sources.values.join('\n');
    expect(combined, contains('CanonicalGameSnapshot'));
    for (final forbidden in const [
      'PersistentGameState',
      'GameRuntimeState',
      'MatchSessionState',
      'LegacyGameSnapshotAdapter',
      '.toLegacy(',
      '.toCanonical(',
    ]) {
      expect(combined, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}
