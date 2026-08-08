import 'package:aonw_server/src/multiplayer/multiplayer_endpoint.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_input_validator.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/scheduling/background_task_support.dart';
import 'package:aonw_server/src/scheduling/reconciled_future_call_scheduler.dart';
import 'package:serverpod/serverpod.dart';

const multiplayerTurnTimeoutSweepCallName = 'multiplayerTurnTimeoutSweep';
const multiplayerTurnTimeoutSweepIdentifier = 'multiplayer-turn-timeout-sweep';
const multiplayerTurnTimeoutSweepInterval = Duration(seconds: 10);
const multiplayerTurnTimeoutCrashRecoveryDelay = Duration(minutes: 2);
const multiplayerTurnTimeoutScheduleReconcileInterval = Duration(seconds: 30);
const multiplayerTurnTimeoutReconcilerShutdownTaskId =
    'multiplayer-turn-timeout-schedule-reconciler';

const _turnTimeoutScheduler = ReconciledFutureCallScheduler(
  callName: multiplayerTurnTimeoutSweepCallName,
  identifier: multiplayerTurnTimeoutSweepIdentifier,
  lockName: 'aonw_multiplayer_turn_timeout_schedule',
);

typedef MultiplayerTimeoutSweepErrorKind = BackgroundTaskErrorKind;

final class MultiplayerTurnTimeoutSweepCall
    extends FutureCall<SerializableModel> {
  MultiplayerTurnTimeoutSweepCall({required RealtimeMatchHub hub}) : _hub = hub;

  final RealtimeMatchHub _hub;

  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    final startedAt = DateTime.now().toUtc();
    await _trySchedule(
      session,
      notAfter: multiplayerTurnTimeoutCrashRecoveryDeadline(startedAt),
      accelerateExisting: true,
    );

    try {
      final failures = await _hub.expireLobbyPresence(
        store: ServerpodMultiplayerMatchStore(session),
      );
      for (final failure in failures) {
        _logFailure(
          session,
          target: 'presence',
          matchId: multiplayerTimeoutLogMatchId(failure.matchId),
          kind: multiplayerTimeoutSweepErrorKind(failure.error),
          stackTrace: failure.stackTrace,
        );
      }
    } catch (error, stackTrace) {
      _logFailure(
        session,
        target: 'presence_orchestration',
        kind: multiplayerTimeoutSweepErrorKind(error),
        stackTrace: stackTrace,
      );
    }

    try {
      final failures = await _hub.advanceTimedOutTurns(
        store: ServerpodMultiplayerMatchStore(session),
      );
      for (final failure in failures) {
        _logFailure(
          session,
          target: 'match',
          matchId: multiplayerTimeoutLogMatchId(failure.matchId),
          kind: multiplayerTimeoutSweepErrorKind(failure.error),
          stackTrace: failure.stackTrace,
        );
      }
    } catch (error, stackTrace) {
      _logFailure(
        session,
        target: 'orchestration',
        kind: multiplayerTimeoutSweepErrorKind(error),
        stackTrace: stackTrace,
      );
    }

    final completedAt = DateTime.now().toUtc();
    await _trySchedule(
      session,
      notAfter: multiplayerTurnTimeoutNextSweepDeadline(completedAt),
      accelerateExisting: true,
    );
  }
}

final class MultiplayerTurnTimeoutScheduleReconciler {
  MultiplayerTurnTimeoutScheduleReconciler(Serverpod pod)
    : _delegate = FutureCallScheduleReconciler(
        reconcileInterval: multiplayerTurnTimeoutScheduleReconcileInterval,
        initialDelay: multiplayerTurnTimeoutSweepInterval,
        recoveryDelay: multiplayerTurnTimeoutCrashRecoveryDelay,
        ensureScheduled: ({required delay, required accelerateExisting}) =>
            ensureMultiplayerTurnTimeoutSweepScheduled(
              pod,
              delay: delay,
              accelerateExisting: accelerateExisting,
            ),
      );

  final FutureCallScheduleReconciler _delegate;

  Future<void> start() => _delegate.start();

  Future<void> close() => _delegate.close();
}

Future<bool> ensureMultiplayerTurnTimeoutSweepScheduled(
  Serverpod pod, {
  Duration delay = multiplayerTurnTimeoutSweepInterval,
  bool accelerateExisting = true,
}) async {
  final session = await pod.createSession(enableLogging: true);
  try {
    return await _trySchedule(
      session,
      notAfter: DateTime.now().toUtc().add(delay),
      accelerateExisting: accelerateExisting,
    );
  } finally {
    await session.close();
  }
}

Future<bool> _trySchedule(
  Session session, {
  required DateTime notAfter,
  required bool accelerateExisting,
}) async {
  try {
    final result = await _turnTimeoutScheduler.scheduleNoLaterThan(
      session,
      serverId: session.serverpod.serverId,
      notAfter: notAfter,
      accelerateExisting: accelerateExisting,
    );
    if (result.duplicatesRemoved > 0 || result.repaired) {
      session.log(
        'event=multiplayer_timeout_schedule_reconciled '
        'duplicates_removed=${result.duplicatesRemoved} '
        'repaired=${result.repaired}',
        level: LogLevel.warning,
      );
    }
    return true;
  } catch (error, stackTrace) {
    _logFailure(
      session,
      target: 'scheduler',
      kind: multiplayerTimeoutSweepErrorKind(error),
      stackTrace: stackTrace,
    );
    return false;
  }
}

MultiplayerTimeoutSweepErrorKind multiplayerTimeoutSweepErrorKind(
  Object error,
) => backgroundTaskErrorKind(error);

String multiplayerTimeoutLogMatchId(String matchId) {
  return MultiplayerInputValidator.logSafeMatchId(matchId);
}

DateTime multiplayerTurnTimeoutCrashRecoveryDeadline(DateTime startedAt) {
  return startedAt.toUtc().add(multiplayerTurnTimeoutCrashRecoveryDelay);
}

DateTime multiplayerTurnTimeoutNextSweepDeadline(DateTime completedAt) {
  return completedAt.toUtc().add(multiplayerTurnTimeoutSweepInterval);
}

void _logFailure(
  Session session, {
  required String target,
  String? matchId,
  required MultiplayerTimeoutSweepErrorKind kind,
  required StackTrace stackTrace,
}) {
  session.log(
    'event=multiplayer_timeout_sweep_failure target=$target '
    '${matchId == null ? '' : 'match_id=$matchId '}'
    'error_kind=${kind.name}',
    level: LogLevel.error,
    stackTrace: stackTrace,
  );
}
