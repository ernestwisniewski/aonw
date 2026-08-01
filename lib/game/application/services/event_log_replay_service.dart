import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';

enum AuthoritativeSnapshotRequiredReason { redactedCommand, missingGameTurn }

/// Signals that projected history cannot safely reconstruct the current
/// state and the caller must reload a server-owned snapshot.
final class AuthoritativeSnapshotRequiredException implements Exception {
  final int offset;
  final AuthoritativeSnapshotRequiredReason reason;

  const AuthoritativeSnapshotRequiredException({
    required this.offset,
    required this.reason,
  });

  @override
  String toString() => switch (reason) {
    AuthoritativeSnapshotRequiredReason.redactedCommand =>
      'Cannot replay redacted multiplayer event at offset $offset; '
          'reload an authoritative snapshot.',
    AuthoritativeSnapshotRequiredReason.missingGameTurn =>
      'Cannot replay legacy multiplayer event without a game turn at offset '
          '$offset; reload an authoritative snapshot.',
  };
}

class EventLogReplayResult {
  final GameClientState state;
  final CanonicalGameSnapshot snapshot;
  final int offset;

  const EventLogReplayResult({
    required this.state,
    required this.snapshot,
    required this.offset,
  });
}

class EventLogReplayService {
  final EventLog eventLog;
  final LocalCommandResolver commandResolver;

  EventLogReplayService({
    required this.eventLog,
    required GameStateReducer reducer,
  }) : commandResolver = LocalCommandResolver(reducer: reducer);

  Future<EventLogReplayResult> replaySinceSnapshot({
    required String saveId,
    required CanonicalGameSnapshot snapshot,
    required GameClientState state,
  }) async {
    var currentSnapshot = snapshot;
    var currentState = state;
    var currentOffset = snapshot.eventLogOffset;
    await for (final logged in eventLog.readSince(
      saveId,
      offset: currentOffset + 1,
    )) {
      if (logged.offset <= currentOffset) continue;
      if (logged.offset != currentOffset + 1) {
        throw StateError(
          'Missing multiplayer event between offsets $currentOffset and '
          '${logged.offset}.',
        );
      }
      final command = logged.command;
      if (command == null) {
        throw AuthoritativeSnapshotRequiredException(
          offset: logged.offset,
          reason: AuthoritativeSnapshotRequiredReason.redactedCommand,
        );
      }
      if (logged.turn == null) {
        throw AuthoritativeSnapshotRequiredException(
          offset: logged.offset,
          reason: AuthoritativeSnapshotRequiredReason.missingGameTurn,
        );
      }
      final resolved = commandResolver.resolve(
        baseSnapshot: currentSnapshot,
        currentState: currentState,
        command: command,
        savedAt: logged.timestamp,
        context: logged.toCommandContext(
          victoryRules: currentSnapshot.domain.matchRules.victory,
          paceBalance: currentSnapshot.domain.matchRules.paceBalance,
        ),
      );
      currentSnapshot = resolved.snapshot.withEventLogOffset(logged.offset);
      currentState = resolved.state;
      currentOffset = logged.offset;
    }
    return EventLogReplayResult(
      state: currentState,
      snapshot: currentSnapshot,
      offset: currentOffset,
    );
  }
}
