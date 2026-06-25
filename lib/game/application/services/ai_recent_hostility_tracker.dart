import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw_core/game/domain/event.dart';

class AiRecentHostilityTracker {
  final EventLog eventLog;
  final int commandWindow;

  const AiRecentHostilityTracker({
    required this.eventLog,
    this.commandWindow = 16,
  }) : assert(commandWindow > 0);

  Future<Set<String>> hostilePlayerIds({
    required SaveSnapshot snapshot,
    required String playerId,
  }) async {
    final startOffset = _startOffset(snapshot.eventLogOffset, commandWindow);
    final hostilePlayerIds = <String>{};

    await for (final logged in eventLog.readSince(
      snapshot.save.id,
      offset: startOffset,
    )) {
      if (logged.offset > snapshot.eventLogOffset) continue;
      for (final event in logged.events) {
        final hostilePlayerId = _hostilePlayerIdFrom(
          logged: logged,
          event: event,
          playerId: playerId,
        );
        if (hostilePlayerId != null && hostilePlayerId != playerId) {
          hostilePlayerIds.add(hostilePlayerId);
        }
      }
    }

    return Set.unmodifiable(hostilePlayerIds);
  }

  static int _startOffset(int latestOffset, int commandWindow) {
    final start = latestOffset - commandWindow + 1;
    return start < 0 ? 0 : start;
  }

  static String? _hostilePlayerIdFrom({
    required LoggedCommand logged,
    required GameEvent event,
    required String playerId,
  }) {
    return switch (event) {
      UnitAttackedEvent(
        :final attackerOwnerPlayerId,
        :final defenderOwnerPlayerId,
      )
          when defenderOwnerPlayerId == playerId =>
        attackerOwnerPlayerId,
      CityCapturedEvent(:final previousOwnerPlayerId, :final newOwnerPlayerId)
          when previousOwnerPlayerId == playerId =>
        newOwnerPlayerId,
      CityDestroyedEvent(
        :final previousOwnerPlayerId,
        :final attackerOwnerPlayerId,
      )
          when previousOwnerPlayerId == playerId =>
        attackerOwnerPlayerId,
      UnitKilledEvent(:final ownerPlayerId)
          when ownerPlayerId == playerId &&
              logged.actorPlayerId != null &&
              logged.actorPlayerId!.isNotEmpty =>
        logged.actorPlayerId,
      _ => null,
    };
  }
}
