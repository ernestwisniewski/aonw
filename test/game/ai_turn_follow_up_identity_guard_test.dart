import 'package:aonw/game/presentation/services/ai_turn_follow_up_identity_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnFollowUpIdentityGuard', () {
    test('stale save cannot invoke human turn-opening callbacks', () async {
      final guard = AiTurnFollowUpIdentityGuard()
        ..initialize(const AiTurnSaveIdentity(saveId: 'old', turn: 4));
      final token = guard.beginExecution(
        saveId: 'old',
        turn: 4,
        playerId: 'ai_1',
      )!;

      final invalidatedLease = guard.handleSaveChange(
        const AiTurnSaveIdentity(saveId: 'new', turn: 1),
      );
      expect(invalidatedLease, token.openingLease);

      expect(
        guard.authorizeFollowUp(
          saveId: 'old',
          previousTurn: 4,
          updatedTurn: 5,
          playerId: 'ai_1',
        ),
        isNull,
      );

      final calls = <String>[];
      guard.runIfCurrent(token, () => calls.add('begin:human_same'));
      await guard.runAsyncIfCurrent(
        token,
        () async => calls.add('prepare:human_same'),
      );
      await guard.runAsyncIfCurrent(
        token,
        () async => calls.add('focus:human_same'),
      );
      await guard.runAsyncIfCurrent(
        token,
        () async => calls.add('release:human_same'),
      );

      expect(calls, isEmpty);
    });

    test(
      'an external T+1 update invalidates the old turn generation',
      () async {
        final guard = AiTurnFollowUpIdentityGuard()
          ..initialize(const AiTurnSaveIdentity(saveId: 'save', turn: 4));
        final token = guard.beginExecution(
          saveId: 'save',
          turn: 4,
          playerId: 'ai_1',
        )!;

        final invalidatedLease = guard.handleSaveChange(
          const AiTurnSaveIdentity(saveId: 'save', turn: 5),
        );
        expect(invalidatedLease, token.openingLease);

        expect(
          guard.authorizeFollowUp(
            saveId: 'save',
            previousTurn: 4,
            updatedTurn: 5,
            playerId: 'ai_1',
          ),
          isNull,
        );
        var callbackInvoked = false;
        await guard.runAsyncIfCurrent(token, () async {
          callbackInvoked = true;
        });
        expect(callbackInvoked, isFalse);
      },
    );

    test('the owning execution may advance from T to T+1', () async {
      final guard = AiTurnFollowUpIdentityGuard()
        ..initialize(const AiTurnSaveIdentity(saveId: 'save', turn: 4));
      final execution = guard.beginExecution(
        saveId: 'save',
        turn: 4,
        playerId: 'ai_1',
      )!;
      final token = guard.authorizeFollowUp(
        saveId: 'save',
        previousTurn: 4,
        updatedTurn: 5,
        playerId: 'ai_1',
      )!;
      expect(identical(token, execution), isTrue);

      final calls = <String>[];
      guard
        ..runIfCurrent(token, () => calls.add('begin'))
        ..handleSaveChange(const AiTurnSaveIdentity(saveId: 'save', turn: 5));
      final authorizedToken = guard.authorizedFollowUpToken(
        saveId: 'save',
        previousTurn: 4,
        updatedTurn: 5,
        playerId: 'ai_1',
      );
      expect(identical(authorizedToken, token), isTrue);
      await guard.runAsyncIfCurrent(token, () async => calls.add('prepare'));
      await guard.runAsyncIfCurrent(token, () async => calls.add('focus'));
      await guard.runAsyncIfCurrent(token, () async => calls.add('release'));

      expect(calls, const ['begin', 'prepare', 'focus', 'release']);
      guard.finishExecution(saveId: 'save', turn: 4, playerId: 'ai_1');
      expect(guard.isCurrent(token), isFalse);
    });
  });
}
