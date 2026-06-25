import 'package:aonw/game/presentation/replay/replay_turn_banner_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReplayTurnBannerPolicy', () {
    test('does not show while applying a step without animation', () {
      expect(
        ReplayTurnBannerPolicy.turnForTransition(
          previousTurn: 7,
          targetTurn: 8,
          animated: false,
          forward: true,
        ),
        isNull,
      );
    });

    test('does not show while moving backwards through the timeline', () {
      expect(
        ReplayTurnBannerPolicy.turnForTransition(
          previousTurn: 8,
          targetTurn: 7,
          animated: true,
          forward: false,
        ),
        isNull,
      );
    });

    test('does not show when replay stays on the same turn', () {
      expect(
        ReplayTurnBannerPolicy.turnForTransition(
          previousTurn: 8,
          targetTurn: 8,
          animated: true,
          forward: true,
        ),
        isNull,
      );
    });

    test('shows the target turn when replay advances into a new turn', () {
      expect(
        ReplayTurnBannerPolicy.turnForTransition(
          previousTurn: 8,
          targetTurn: 9,
          animated: true,
          forward: true,
        ),
        9,
      );
    });
  });
}
