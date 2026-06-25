import 'package:aonw/game/application/services/ai_turn_run_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnRunScheduler', () {
    test('builds deterministic per-turn keys', () {
      expect(
        AiTurnRunScheduler.turnKey(saveId: 'save', turn: 7, playerId: 'ai'),
        'save:7:ai',
      );
    });

    test('schedules each player turn once until it is completed', () {
      final scheduler = AiTurnRunScheduler();

      final first = scheduler.schedule(saveId: 'save', turn: 7, playerId: 'ai');
      final duplicateScheduled = scheduler.schedule(
        saveId: 'save',
        turn: 7,
        playerId: 'ai',
      );

      expect(first, isNotNull);
      expect(first!.turnKey, 'save:7:ai');
      expect(duplicateScheduled, isNull);

      scheduler
        ..markCompleted(first)
        ..markFinished(first);
      final duplicateCompleted = scheduler.schedule(
        saveId: 'save',
        turn: 7,
        playerId: 'ai',
      );
      final nextTurn = scheduler.schedule(
        saveId: 'save',
        turn: 8,
        playerId: 'ai',
      );

      expect(duplicateCompleted, isNull);
      expect(nextTurn, isNotNull);
      expect(nextTurn!.turnKey, 'save:8:ai');
    });

    test('blocks new scheduling while an AI turn is running', () {
      final scheduler = AiTurnRunScheduler();
      final request = scheduler.schedule(
        saveId: 'save',
        turn: 7,
        playerId: 'ai',
      )!;

      expect(scheduler.canStart(request), isTrue);
      scheduler.markStarted(request);

      expect(scheduler.running, isTrue);
      expect(scheduler.canStart(request), isFalse);
      expect(
        scheduler.schedule(saveId: 'save', turn: 7, playerId: 'ai_2'),
        isNull,
      );

      scheduler.markFinished(request);

      expect(scheduler.running, isFalse);
      expect(
        scheduler.schedule(saveId: 'save', turn: 7, playerId: 'ai_2'),
        isNotNull,
      );
    });

    test(
      'resetForTurn clears stale scheduled key without dropping completed',
      () {
        final scheduler = AiTurnRunScheduler();
        final completed = scheduler.schedule(
          saveId: 'save',
          turn: 7,
          playerId: 'ai',
        )!;
        scheduler
          ..markCompleted(completed)
          ..resetForTurn();

        expect(
          scheduler.schedule(saveId: 'save', turn: 7, playerId: 'ai'),
          isNull,
        );
        expect(
          scheduler.schedule(saveId: 'save', turn: 8, playerId: 'ai'),
          isNotNull,
        );
      },
    );

    test('resetForSave clears scheduled and completed turn keys', () {
      final scheduler = AiTurnRunScheduler();
      final completed = scheduler.schedule(
        saveId: 'save',
        turn: 7,
        playerId: 'ai',
      )!;
      scheduler
        ..markCompleted(completed)
        ..resetForSave();

      final rescheduled = scheduler.schedule(
        saveId: 'save',
        turn: 7,
        playerId: 'ai',
      );

      expect(rescheduled, isNotNull);
    });
  });
}
