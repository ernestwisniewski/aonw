abstract final class SystemEventWire {
  static const commandRejectedType = 'CommandRejectedEvent';
  static const allPlayersSubmittedType = 'AllPlayersSubmittedEvent';
  static const playerTimedOutType = 'PlayerTimedOutEvent';
  static const turnAutoResolvedType = 'TurnAutoResolvedEvent';
  static const playerKickedType = 'PlayerKickedEvent';

  static Map<String, dynamic> commandRejected({required String reason}) {
    if (reason.isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'Expected a non-empty String',
      );
    }
    return {'type': commandRejectedType, 'reason': reason};
  }

  static Map<String, dynamic> allPlayersSubmitted({
    required int turn,
    required Iterable<String> playerIds,
  }) {
    final ids = List<String>.unmodifiable(playerIds);
    if (ids.any((id) => id.isEmpty)) {
      throw ArgumentError.value(
        ids,
        'playerIds',
        'Expected non-empty player ids',
      );
    }
    return {'type': allPlayersSubmittedType, 'turn': turn, 'playerIds': ids};
  }

  static Map<String, dynamic> playerTimedOut({
    required int turn,
    required String playerId,
  }) {
    if (playerId.isEmpty) {
      throw ArgumentError.value(
        playerId,
        'playerId',
        'Expected a non-empty String',
      );
    }
    return {'type': playerTimedOutType, 'turn': turn, 'playerId': playerId};
  }

  static Map<String, dynamic> turnAutoResolved({
    required int turn,
    required String playerId,
    required int unitOrderCount,
    required int cityProductionCount,
    required bool researchSelected,
  }) {
    if (playerId.isEmpty) {
      throw ArgumentError.value(
        playerId,
        'playerId',
        'Expected a non-empty String',
      );
    }
    if (unitOrderCount < 0) {
      throw ArgumentError.value(
        unitOrderCount,
        'unitOrderCount',
        'Expected a non-negative integer',
      );
    }
    if (cityProductionCount < 0) {
      throw ArgumentError.value(
        cityProductionCount,
        'cityProductionCount',
        'Expected a non-negative integer',
      );
    }
    return {
      'type': turnAutoResolvedType,
      'turn': turn,
      'playerId': playerId,
      'unitOrderCount': unitOrderCount,
      'cityProductionCount': cityProductionCount,
      'researchSelected': researchSelected,
    };
  }

  static Map<String, dynamic> playerKicked({
    required int turn,
    required String playerId,
    required String reason,
    required int timeoutStreak,
  }) {
    if (playerId.isEmpty) {
      throw ArgumentError.value(
        playerId,
        'playerId',
        'Expected a non-empty String',
      );
    }
    if (reason.isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'Expected a non-empty String',
      );
    }
    if (timeoutStreak <= 0) {
      throw ArgumentError.value(
        timeoutStreak,
        'timeoutStreak',
        'Expected a positive integer',
      );
    }
    return {
      'type': playerKickedType,
      'turn': turn,
      'playerId': playerId,
      'reason': reason,
      'timeoutStreak': timeoutStreak,
    };
  }

  static bool isCommandRejected(Map<String, dynamic> event) {
    return event['type'] == commandRejectedType;
  }

  static bool containsCommandRejected(Iterable<Map<String, dynamic>> events) {
    return events.any(isCommandRejected);
  }

  static String? firstCommandRejectedReason(
    Iterable<Map<String, dynamic>> events,
  ) {
    for (final event in events) {
      if (!isCommandRejected(event)) continue;
      final reason = event['reason'];
      if (reason is String && reason.isNotEmpty) return reason;
    }
    return null;
  }
}
