import 'dart:async';
import 'dart:io';

import 'package:aonw_server/src/multiplayer/multiplayer_turn_timeout_future_call.dart';
import 'package:test/test.dart';

void main() {
  test('classifies expected failures without rendering error text', () {
    expect(
      multiplayerTimeoutSweepErrorKind(StateError('private state detail')),
      MultiplayerTimeoutSweepErrorKind.invalidState,
    );
    expect(
      multiplayerTimeoutSweepErrorKind(ArgumentError.value('private value')),
      MultiplayerTimeoutSweepErrorKind.invalidArgument,
    );
    expect(
      multiplayerTimeoutSweepErrorKind(TimeoutException('private timeout')),
      MultiplayerTimeoutSweepErrorKind.timeout,
    );
    expect(
      multiplayerTimeoutSweepErrorKind(
        const SocketException('private host detail'),
      ),
      MultiplayerTimeoutSweepErrorKind.network,
    );
    expect(
      multiplayerTimeoutSweepErrorKind(_SensitiveError()),
      MultiplayerTimeoutSweepErrorKind.unexpected,
    );
  });

  test('allows only bounded log-safe match identifiers', () {
    expect(multiplayerTimeoutLogMatchId('match_01-ABC'), 'match_01-ABC');
    expect(multiplayerTimeoutLogMatchId('_leading-underscore'), 'invalid');
    expect(multiplayerTimeoutLogMatchId('match\nforged=value'), 'invalid');
    expect(
      multiplayerTimeoutLogMatchId(List.filled(65, 'x').join()),
      'invalid',
    );
  });

  test('reserves a distant fallback then schedules from sweep completion', () {
    final startedAt = DateTime.utc(2026, 7, 10, 12);
    final completedAt = startedAt.add(const Duration(seconds: 90));

    final crashRecoveryAt = multiplayerTurnTimeoutCrashRecoveryDeadline(
      startedAt,
    );
    final nextSweepAt = multiplayerTurnTimeoutNextSweepDeadline(completedAt);

    expect(crashRecoveryAt, startedAt.add(const Duration(minutes: 2)));
    expect(nextSweepAt, completedAt.add(const Duration(seconds: 10)));
    expect(nextSweepAt.isAfter(completedAt), isTrue);
    expect(nextSweepAt.isBefore(crashRecoveryAt), isTrue);
    expect(
      crashRecoveryAt,
      isNot(startedAt.add(multiplayerTurnTimeoutSweepInterval)),
    );
  });

  test('reconciles missing schedules on a short bounded cadence', () {
    expect(
      multiplayerTurnTimeoutScheduleReconcileInterval,
      const Duration(seconds: 30),
    );
    expect(
      multiplayerTurnTimeoutScheduleReconcileInterval <=
          const Duration(minutes: 1),
      isTrue,
    );
  });
}

final class _SensitiveError implements Exception {
  @override
  String toString() => throw StateError('error text must not be rendered');
}
