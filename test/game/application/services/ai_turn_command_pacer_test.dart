import 'package:aonw/game/application/services/ai_turn_command_pacer.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnCommandPacer', () {
    test('pauses after dispatch when visible UI effects are present', () async {
      final delays = <Duration>[];
      final pacer = AiTurnCommandPacer(
        delay: (duration) async {
          delays.add(duration);
        },
      );

      final report = await pacer.pauseAfterDispatch(
        result: const DispatchCommandResult(
          state: GameState(),
          uiEffects: [JumpCameraEffect(col: 1, row: 2)],
        ),
        interCommandDelay: const Duration(milliseconds: 40),
      );

      expect(delays, const [Duration(milliseconds: 40)]);
      expect(report.paused, isTrue);
      expect(report.duration, greaterThanOrEqualTo(Duration.zero));
    });

    test(
      'skips pause when delay is zero or result has no UI effects',
      () async {
        final pacer = AiTurnCommandPacer(
          delay: (_) async {
            fail('pacer should not delay without both duration and UI effects');
          },
        );

        final noEffects = await pacer.pauseAfterDispatch(
          result: const DispatchCommandResult(state: GameState()),
          interCommandDelay: const Duration(milliseconds: 40),
        );
        final noDelay = await pacer.pauseAfterDispatch(
          result: const DispatchCommandResult(
            state: GameState(),
            uiEffects: [JumpCameraEffect(col: 1, row: 2)],
          ),
          interCommandDelay: Duration.zero,
        );

        expect(noEffects.paused, isFalse);
        expect(noEffects.duration, Duration.zero);
        expect(noDelay.paused, isFalse);
        expect(noDelay.duration, Duration.zero);
      },
    );
  });
}
