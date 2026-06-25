import 'package:aonw/game/presentation/providers/game_event_notifications_provider.dart';

abstract final class HudActivityLogEntries {
  static List<GameEventNotification> visibleTo({
    required List<GameEventNotification> entries,
    required String activePlayerId,
  }) {
    if (activePlayerId.isEmpty) return const [];
    return [
      for (final entry in entries)
        if (entry.isVisibleTo(activePlayerId)) entry,
    ];
  }
}
