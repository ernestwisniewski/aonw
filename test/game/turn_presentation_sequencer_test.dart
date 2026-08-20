import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/services/turn_presentation_sequencer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TurnPresentationSequencer', () {
    test('plays effects before prepare, focus, and release', () async {
      final calls = <String>[];
      var inputBlocked = false;
      final sequencer = TurnPresentationSequencer(
        playTurnAdvanceEffects: (effects) async {
          expect(inputBlocked, isTrue);
          calls.add('effects:${effects.length}');
          return effects.length;
        },
        beginTurnOpening: (playerId) {
          inputBlocked = true;
          calls.add('begin:$playerId');
        },
        prepareHumanTurn: (playerId) async {
          calls.add('prepare:$playerId');
        },
        focusTurnStartMapTarget: (playerId) async {
          calls.add('focus:$playerId');
        },
        releaseHumanTurn: (playerId) async {
          calls.add('release:$playerId');
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

      expect(calls, const [
        'begin:human',
        'effects:1',
        'prepare:human',
        'focus:human',
        'release:human',
      ]);
      expect(report.turnAdvanceEffectsPlayed, isTrue);
      expect(report.turnAdvanceEffectCount, 1);
      expect(report.beganTurnOpening, isTrue);
      expect(report.preparedHumanTurn, isTrue);
      expect(report.focusedTurnStart, isTrue);
      expect(report.releasedHumanTurn, isTrue);
    });

    test('prepares, focuses, and releases without optional effects', () async {
      final calls = <String>[];
      final sequencer = TurnPresentationSequencer(
        playTurnAdvanceEffects: (effects) async {
          calls.add('effects');
          return effects.length;
        },
        beginTurnOpening: (playerId) {
          calls.add('begin:$playerId');
        },
        prepareHumanTurn: (playerId) async {
          calls.add('prepare:$playerId');
        },
        focusTurnStartMapTarget: (playerId) async {
          calls.add('focus:$playerId');
        },
        releaseHumanTurn: (playerId) async {
          calls.add('release:$playerId');
        },
      );

      final report = await sequencer.presentHumanTurnStart(
        playerId: 'human',
        shouldPlayTurnAdvanceEffects: false,
        turnAdvanceEffects: const [],
      );

      expect(calls, const [
        'begin:human',
        'prepare:human',
        'focus:human',
        'release:human',
      ]);
      expect(report.turnAdvanceEffectsPlayed, isFalse);
      expect(report.turnAdvanceEffectCount, 0);
      expect(report.preparedHumanTurn, isTrue);
      expect(report.focusedTurnStart, isTrue);
      expect(report.releasedHumanTurn, isTrue);
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
          beginTurnOpening: (playerId) {
            calls.add('begin:$playerId');
          },
          prepareHumanTurn: (playerId) async {
            calls.add('prepare:$playerId');
          },
          focusTurnStartMapTarget: (playerId) async {
            calls.add('focus:$playerId');
          },
          releaseHumanTurn: (playerId) async {
            calls.add('release:$playerId');
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

        expect(calls, const ['begin:human', 'effects']);
        expect(report.turnAdvanceEffectsPlayed, isTrue);
        expect(report.preparedHumanTurn, isFalse);
        expect(report.focusedTurnStart, isFalse);
        expect(report.releasedHumanTurn, isFalse);
      },
    );

    test(
      'does not focus or release when continuation is lost after prepare',
      () async {
        final calls = <String>[];
        var canContinue = true;
        final sequencer = TurnPresentationSequencer(
          canContinue: () => canContinue,
          playTurnAdvanceEffects: (effects) async => effects.length,
          beginTurnOpening: (playerId) {
            calls.add('begin:$playerId');
          },
          prepareHumanTurn: (playerId) async {
            calls.add('prepare:$playerId');
            canContinue = false;
          },
          focusTurnStartMapTarget: (playerId) async {
            calls.add('focus:$playerId');
          },
          releaseHumanTurn: (playerId) async {
            calls.add('release:$playerId');
          },
        );

        final report = await sequencer.presentHumanTurnStart(
          playerId: 'human',
          shouldPlayTurnAdvanceEffects: false,
          turnAdvanceEffects: const [],
        );

        expect(calls, const ['begin:human', 'prepare:human']);
        expect(report.preparedHumanTurn, isTrue);
        expect(report.focusedTurnStart, isFalse);
        expect(report.releasedHumanTurn, isFalse);
      },
    );

    test('focuses exactly once before human input is released', () async {
      final calls = <String>[];
      var focusCount = 0;
      final sequencer = TurnPresentationSequencer(
        playTurnAdvanceEffects: (effects) async => effects.length,
        beginTurnOpening: (playerId) {
          calls.add('begin:$playerId');
        },
        prepareHumanTurn: (playerId) async {
          calls.add('prepare:$playerId');
        },
        focusTurnStartMapTarget: (playerId) async {
          focusCount++;
          calls.add('focus:$playerId');
        },
        releaseHumanTurn: (playerId) async {
          calls.add('release:$playerId');
        },
      );

      await sequencer.presentHumanTurnStart(
        playerId: 'human',
        shouldPlayTurnAdvanceEffects: false,
        turnAdvanceEffects: const [],
      );

      expect(focusCount, 1);
      expect(calls, const [
        'begin:human',
        'prepare:human',
        'focus:human',
        'release:human',
      ]);
    });

    test('releases human input when turn-advance playback fails', () async {
      final calls = <String>[];
      final sequencer = TurnPresentationSequencer(
        playTurnAdvanceEffects: (effects) async {
          calls.add('effects');
          throw StateError('effects failed');
        },
        beginTurnOpening: (playerId) {
          calls.add('begin:$playerId');
        },
        prepareHumanTurn: (playerId) async {
          calls.add('prepare:$playerId');
        },
        focusTurnStartMapTarget: (playerId) async {
          calls.add('focus:$playerId');
        },
        releaseHumanTurn: (playerId) async {
          calls.add('release:$playerId');
        },
      );

      await expectLater(
        sequencer.presentHumanTurnStart(
          playerId: 'human',
          shouldPlayTurnAdvanceEffects: true,
          turnAdvanceEffects: const [],
        ),
        throwsStateError,
      );
      expect(calls, const ['begin:human', 'effects', 'release:human']);
    });

    test('releases human input when turn preparation fails', () async {
      final calls = <String>[];
      final sequencer = TurnPresentationSequencer(
        playTurnAdvanceEffects: (effects) async => effects.length,
        beginTurnOpening: (playerId) {
          calls.add('begin:$playerId');
        },
        prepareHumanTurn: (playerId) async {
          calls.add('prepare:$playerId');
          throw StateError('prepare failed');
        },
        focusTurnStartMapTarget: (playerId) async {
          calls.add('focus:$playerId');
        },
        releaseHumanTurn: (playerId) async {
          calls.add('release:$playerId');
        },
      );

      await expectLater(
        sequencer.presentHumanTurnStart(
          playerId: 'human',
          shouldPlayTurnAdvanceEffects: false,
          turnAdvanceEffects: const [],
        ),
        throwsStateError,
      );
      expect(calls, const ['begin:human', 'prepare:human', 'release:human']);
    });

    test('releases human input when turn-start focus fails', () async {
      final calls = <String>[];
      final sequencer = TurnPresentationSequencer(
        playTurnAdvanceEffects: (effects) async => effects.length,
        beginTurnOpening: (playerId) {
          calls.add('begin:$playerId');
        },
        prepareHumanTurn: (playerId) async {
          calls.add('prepare:$playerId');
        },
        focusTurnStartMapTarget: (playerId) async {
          calls.add('focus:$playerId');
          throw StateError('focus failed');
        },
        releaseHumanTurn: (playerId) async {
          calls.add('release:$playerId');
        },
      );

      await expectLater(
        sequencer.presentHumanTurnStart(
          playerId: 'human',
          shouldPlayTurnAdvanceEffects: false,
          turnAdvanceEffects: const [],
        ),
        throwsStateError,
      );
      expect(calls, const [
        'begin:human',
        'prepare:human',
        'focus:human',
        'release:human',
      ]);
    });
  });
}
