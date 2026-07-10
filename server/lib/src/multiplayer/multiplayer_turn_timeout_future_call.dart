import 'package:serverpod/serverpod.dart';

import 'multiplayer_endpoint.dart';
import 'multiplayer_match_store.dart';

const multiplayerTurnTimeoutSweepCallName = 'multiplayerTurnTimeoutSweep';
const multiplayerTurnTimeoutSweepIdentifier = 'multiplayer-turn-timeout-sweep';
const multiplayerTurnTimeoutSweepInterval = Duration(seconds: 10);

final class MultiplayerTurnTimeoutSweepCall
    extends FutureCall<SerializableModel> {
  MultiplayerTurnTimeoutSweepCall({required RealtimeMatchHub hub}) : _hub = hub;

  final RealtimeMatchHub _hub;

  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    try {
      final failures = await _hub.advanceTimedOutTurns(
        store: ServerpodMultiplayerMatchStore(session),
      );
      for (final failure in failures) {
        session.log(
          'event=multiplayer_timeout_sweep_failure '
          'match_id=${failure.matchId}',
          level: LogLevel.error,
          exception: failure.error,
          stackTrace: failure.stackTrace,
        );
      }
    } finally {
      await scheduleMultiplayerTurnTimeoutSweep(session.serverpod);
    }
  }
}

Future<void> scheduleMultiplayerTurnTimeoutSweep(Serverpod pod) async {
  // ignore: deprecated_member_use
  await pod.cancelFutureCall(multiplayerTurnTimeoutSweepIdentifier);
  // ignore: deprecated_member_use
  await pod.futureCallWithDelay(
    multiplayerTurnTimeoutSweepCallName,
    null,
    multiplayerTurnTimeoutSweepInterval,
    identifier: multiplayerTurnTimeoutSweepIdentifier,
  );
}
