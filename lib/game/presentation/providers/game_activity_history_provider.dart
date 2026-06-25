import 'package:aonw/game/application/ports/activity_history_entry.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/repository_providers.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gameActivityHistoryProvider =
    FutureProvider.family<List<GameActivityHistoryRecord>, String>((
      ref,
      saveId,
    ) async {
      if (saveId.isEmpty) return const [];

      final records = <GameActivityHistoryRecord>[];
      await for (final command in ref.watch(eventLogProvider).readAll(saveId)) {
        for (final entry in command.activity) {
          records.add(
            GameActivityHistoryRecord(
              offset: command.offset,
              eventIndex: entry.eventIndex,
              timestamp: command.timestamp,
              turn: command.turn,
              playerId: entry.playerId,
              event: entry.event,
              context: entry.context,
            ),
          );
        }
      }
      records.sort((a, b) {
        final offsetCompare = a.offset.compareTo(b.offset);
        if (offsetCompare != 0) return offsetCompare;
        return a.eventIndex.compareTo(b.eventIndex);
      });
      return List.unmodifiable(records);
    });

class GameActivityHistoryRecord {
  const GameActivityHistoryRecord({
    required this.offset,
    required this.eventIndex,
    required this.timestamp,
    required this.turn,
    required this.playerId,
    required this.event,
    required this.context,
  });

  final int offset;
  final int eventIndex;
  final DateTime timestamp;
  final int turn;
  final String playerId;
  final GameEvent event;
  final GameActivityContext context;

  int get id => offset * 1000 + eventIndex;

  bool isVisibleTo(String activePlayerId) =>
      activePlayerId.isNotEmpty && playerId == activePlayerId;

  GameEventNotification toNotification(GameState state) {
    return GameEventNotification(
      id: id,
      event: event,
      state: state,
      playerId: playerId,
      turn: turn,
      context: context,
    );
  }
}
