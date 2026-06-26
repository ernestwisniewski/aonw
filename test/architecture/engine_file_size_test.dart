import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flame renderer files cannot grow past their refactor baselines', () {
    final violations = <String>[];
    for (final entry in _engineFileBaselines.entries) {
      final file = File(entry.key);
      final lineCount = file.readAsLinesSync().length;
      if (lineCount > entry.value) {
        violations.add(
          '${entry.key} has $lineCount lines; max is ${entry.value}',
        );
      }
    }

    expect(violations, isEmpty);
  });
}

const _engineFileBaselines = <String, int>{
  'lib/game/presentation/engine/game_renderer.dart': 601,
};
