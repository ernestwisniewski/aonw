import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'web WASM AI runtime avoids extension tear-offs across async boundaries',
    () {
      final guardedSources = <String, List<String>>{
        'lib/game/presentation/widgets/ai/game_ai_turn_auto_pilot_execution.dart': [
          'prepareProcess: prepareAiTurnProcess,',
        ],
        'lib/game/presentation/widgets/ai/game_ai_turn_auto_pilot_runtime.dart': [
          'executionRunner: aiTurnExecutionRunner,',
          'precomputeRunner: aiTurnPrecomputeRunner,',
          'now: nowUtc,',
        ],
      };

      for (final entry in guardedSources.entries) {
        final source = File(entry.key).readAsStringSync();
        for (final forbidden in entry.value) {
          expect(
            source,
            isNot(contains(forbidden)),
            reason:
                '${entry.key} must invoke extension methods inside closures. '
                'Bound extension tear-offs can trap optimized dart2wasm when '
                'they cross the AI runtime async boundary.',
          );
        }
      }
    },
  );
}
