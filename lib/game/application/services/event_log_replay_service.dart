import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw_core/game/domain/match_rules.dart';

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
  final GameState state;
  final int offset;

  const EventLogReplayResult({required this.state, required this.offset});
}

class EventLogReplayService {
  final EventLog eventLog;
  final GameStateReducer reducer;

  const EventLogReplayService({required this.eventLog, required this.reducer});

  Future<EventLogReplayResult> replaySinceSnapshot({
    required String saveId,
    required GameState state,
    required int offset,
    MatchRules matchRules = MatchRules.standard,
  }) async {
    var currentState = state;
    var currentOffset = offset;
    await for (final logged in eventLog.readSince(saveId, offset: offset + 1)) {
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
      final transition = reducer.reduce(
        currentState,
        command,
        context: logged.toCommandContext(
          victoryRules: matchRules.victory,
          paceBalance: matchRules.paceBalance,
        ),
      );
      currentState = transition.state;
      currentOffset = logged.offset;
    }
    return EventLogReplayResult(state: currentState, offset: currentOffset);
  }
}
