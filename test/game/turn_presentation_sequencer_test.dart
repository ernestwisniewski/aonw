import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/services/turn_presentation_sequencer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TurnPresentationSequencer', () {
    test('plays turn-advance effects before confirm and focus', () async {
      final calls = <String>[];
      final sequencer = TurnPresentationSequencer(
        playTurnAdvanceEffects: (effects) async {
          calls.add('effects:${effects.length}');
          return effects.length;
        },
        confirmHumanTurn: (playerId) async {
          calls.add('confirm:$playerId');
        },
        focusTurnStartMapTarget: (playerId) async {
          calls.add('focus:$playerId');
        },
      );

      final report = await sequencer.presentHumanTurnStart(
        playerId: 'human',
        shouldPlayTurnAdvanceEffects: true,
        turnAdvanceEffects: const [
          ShowFloatingTextEffect(
            text: 'turn',
            col: 1,
            row: 2,
            colorValue: 0xFFFFFFFF,
          ),
        ],
      );

      expect(calls, const ['effects:1', 'confirm:human', 'focus:human']);
      expect(report.turnAdvanceEffectsPlayed, isTrue);
      expect(report.turnAdvanceEffectCount, 1);
      expect(report.confirmedHumanTurn, isTrue);
      expect(report.focusedTurnStart, isTrue);
    });

    test('confirms and focuses without effects when not requested', () async {
      final calls = <String>[];
      final sequencer = TurnPresentationSequencer(
        playTurnAdvanceEffects: (effects) async {
          calls.add('effects');
          return effects.length;
        },
        confirmHumanTurn: (playerId) async {
          calls.add('confirm:$playerId');
        },
        focusTurnStartMapTarget: (playerId) async {
          calls.add('focus:$playerId');
        },
      );

      final report = await sequencer.presentHumanTurnStart(
        playerId: 'human',
        shouldPlayTurnAdvanceEffects: false,
        turnAdvanceEffects: const [],
      );

      expect(calls, const ['confirm:human', 'focus:human']);
      expect(report.turnAdvanceEffectsPlayed, isFalse);
      expect(report.turnAdvanceEffectCount, 0);
      expect(report.confirmedHumanTurn, isTrue);
      expect(report.focusedTurnStart, isTrue);
    });

    test(
      'stops after turn-advance effects when continuation is lost',
      () async {
        final calls = <String>[];
        var canContinue = true;
        final sequencer = TurnPresentationSequencer(
          canContinue: () => canContinue,
          playTurnAdvanceEffects: (effects) async {
            calls.add('effects');
            canContinue = false;
            return effects.length;
          },
          confirmHumanTurn: (playerId) async {
            calls.add('confirm:$playerId');
          },
          focusTurnStartMapTarget: (playerId) async {
            calls.add('focus:$playerId');
          },
        );

        final report = await sequencer.presentHumanTurnStart(
          playerId: 'human',
          shouldPlayTurnAdvanceEffects: true,
          turnAdvanceEffects: const [
            ShowFloatingTextEffect(
              text: 'turn',
              col: 1,
              row: 2,
              colorValue: 0xFFFFFFFF,
            ),
          ],
        );

        expect(calls, const ['effects']);
        expect(report.turnAdvanceEffectsPlayed, isTrue);
        expect(report.confirmedHumanTurn, isFalse);
        expect(report.focusedTurnStart, isFalse);
      },
    );

    test('stops after confirm when continuation is lost', () async {
      final calls = <String>[];
      var canContinue = true;
      final sequencer = TurnPresentationSequencer(
        canContinue: () => canContinue,
        playTurnAdvanceEffects: (effects) async => effects.length,
        confirmHumanTurn: (playerId) async {
          calls.add('confirm:$playerId');
          canContinue = false;
        },
        focusTurnStartMapTarget: (playerId) async {
          calls.add('focus:$playerId');
        },
      );

      final report = await sequencer.presentHumanTurnStart(
        playerId: 'human',
        shouldPlayTurnAdvanceEffects: false,
        turnAdvanceEffects: const [],
      );

      expect(calls, const ['confirm:human']);
      expect(report.confirmedHumanTurn, isTrue);
      expect(report.focusedTurnStart, isFalse);
    });
  });
}
