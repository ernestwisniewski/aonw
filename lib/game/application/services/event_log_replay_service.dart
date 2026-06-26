import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';

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
      final transition = reducer.reduce(
        currentState,
        logged.command,
        context: GameCommandContext(actorPlayerId: logged.actorPlayerId),
      );
      currentState = transition.state;
      currentOffset = logged.offset;
    }
    return EventLogReplayResult(state: currentState, offset: currentOffset);
  }
}
