import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_core/util/wire_json.dart';

/// Wire codec for command and multiplayer turn lifecycle events.
abstract final class SystemEventSerializer {
  static Map<String, dynamic> toJson(GameEvent event) {
    return switch (event) {
      CommandRejectedEvent(:final reason) => SystemEventWire.commandRejected(
        reason: reason,
      ),
      AllPlayersSubmittedEvent(:final turn, :final playerIds) =>
        SystemEventWire.allPlayersSubmitted(turn: turn, playerIds: playerIds),
      PlayerTimedOutEvent(:final turn, :final playerId) =>
        SystemEventWire.playerTimedOut(turn: turn, playerId: playerId),
      TurnAutoResolvedEvent(
        :final turn,
        :final playerId,
        :final unitOrderCount,
        :final cityProductionCount,
        :final researchSelected,
      ) =>
        SystemEventWire.turnAutoResolved(
          turn: turn,
          playerId: playerId,
          unitOrderCount: unitOrderCount,
          cityProductionCount: cityProductionCount,
          researchSelected: researchSelected,
        ),
      PlayerKickedEvent(
        :final turn,
        :final playerId,
        :final reason,
        :final timeoutStreak,
      ) =>
        SystemEventWire.playerKicked(
          turn: turn,
          playerId: playerId,
          reason: reason,
          timeoutStreak: timeoutStreak,
        ),
      _ => throw ArgumentError.value(event, 'event', 'Not a system event'),
    };
  }

  static GameEvent? tryFromJson(Map<String, dynamic> json, String type) {
    return switch (type) {
      SystemEventWire.commandRejectedType => CommandRejectedEvent(
        reason: requiredStringField(json, type, 'reason'),
      ),
      SystemEventWire.allPlayersSubmittedType => AllPlayersSubmittedEvent(
        turn: requiredIntField(json, type, 'turn'),
        playerIds: requiredStringListField(json, type, 'playerIds'),
      ),
      SystemEventWire.playerTimedOutType => PlayerTimedOutEvent(
        turn: requiredIntField(json, type, 'turn'),
        playerId: requiredStringField(json, type, 'playerId'),
      ),
      SystemEventWire.turnAutoResolvedType => TurnAutoResolvedEvent(
        turn: requiredIntField(json, type, 'turn'),
        playerId: requiredStringField(json, type, 'playerId'),
        unitOrderCount: requiredIntField(json, type, 'unitOrderCount'),
        cityProductionCount: requiredIntField(
          json,
          type,
          'cityProductionCount',
        ),
        researchSelected: requiredBoolField(json, type, 'researchSelected'),
      ),
      SystemEventWire.playerKickedType => PlayerKickedEvent(
        turn: requiredIntField(json, type, 'turn'),
        playerId: requiredStringField(json, type, 'playerId'),
        reason: requiredStringField(json, type, 'reason'),
        timeoutStreak: requiredIntField(json, type, 'timeoutStreak'),
      ),
      _ => null,
    };
  }
}
