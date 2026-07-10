import 'dart:async';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../scheduling/reconciled_future_call_scheduler.dart';
import 'multiplayer_endpoint.dart';
import 'multiplayer_match_store.dart';

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

enum MultiplayerTimeoutSweepErrorKind {
  database,
  network,
  timeout,
  invalidState,
  invalidArgument,
  unexpected,
}

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
  MultiplayerTurnTimeoutScheduleReconciler(this._pod);

  final Serverpod _pod;
  Timer? _timer;
  Future<void>? _activeReconciliation;

  Future<void> start() async {
    if (_timer != null) return;
    await _reconcileOnce(delay: multiplayerTurnTimeoutSweepInterval);
    _timer = Timer.periodic(
      multiplayerTurnTimeoutScheduleReconcileInterval,
      (_) => _triggerReconciliation(),
    );
  }

  Future<void> close() async {
    _timer?.cancel();
    _timer = null;
    await _activeReconciliation;
  }

  void _triggerReconciliation() {
    if (_activeReconciliation != null) return;
    final reconciliation = _reconcileOnce(
      delay: multiplayerTurnTimeoutCrashRecoveryDelay,
    );
    _activeReconciliation = reconciliation;
    unawaited(
      reconciliation.whenComplete(() {
        _activeReconciliation = null;
      }),
    );
  }

  Future<void> _reconcileOnce({required Duration delay}) async {
    try {
      await ensureMultiplayerTurnTimeoutSweepScheduled(
        _pod,
        delay: delay,
        accelerateExisting: false,
      );
    } catch (_) {
      // Scheduling failures are logged by _trySchedule. A session lifecycle
      // failure must not terminate the periodic recovery loop.
    }
  }
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
) {
  return switch (error) {
    DatabaseException() => MultiplayerTimeoutSweepErrorKind.database,
    SocketException() => MultiplayerTimeoutSweepErrorKind.network,
    TimeoutException() => MultiplayerTimeoutSweepErrorKind.timeout,
    StateError() => MultiplayerTimeoutSweepErrorKind.invalidState,
    ArgumentError() => MultiplayerTimeoutSweepErrorKind.invalidArgument,
    _ => MultiplayerTimeoutSweepErrorKind.unexpected,
  };
}

String multiplayerTimeoutLogMatchId(String matchId) {
  // Keep the 64-character bound aligned with MultiplayerInputValidator.
  return RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$').hasMatch(matchId)
      ? matchId
      : 'invalid';
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
