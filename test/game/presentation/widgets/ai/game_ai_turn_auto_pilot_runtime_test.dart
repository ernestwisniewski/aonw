import 'package:aonw/game/presentation/services/ai_turn_execution_runner.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_runner.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_context.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_runtime.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('runtime resolves AI runners through callback boundaries', (
    tester,
  ) async {
    late GameAiTurnAutoPilotContext autoPilot;

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, child) {
            autoPilot = GameAiTurnAutoPilotContext(
              ref: ref,
              saveReader: () => null,
              contextReader: () => context,
              interCommandDelayReader: () => Duration.zero,
              canContinue: () => true,
              notifyStateChanged: () {},
              cancelTurnOpening: (_) {},
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    autoPilot.runtimeCoordinator = autoPilot.createAiTurnRuntimeCoordinator();

    expect(
      autoPilot.runtimeCoordinator.executionRunner(),
      isA<AiTurnExecutionRunner>(),
    );
    expect(
      autoPilot.runtimeCoordinator.precomputeRunner(),
      isA<AiTurnPrecomputeRunner>(),
    );
  });
}
