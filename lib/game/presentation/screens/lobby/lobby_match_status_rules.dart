import 'package:aonw_core/protocol.dart';

abstract final class LobbyMatchStatusRules {
  static const defaultMinimumHumanPlayers = 2;
  static const defaultMaximumPlayers = 4;

  static int humanPlayerCount(WireMatch? match, {int whenMissing = 0}) {
    if (match == null) return whenMissing;
    return match.players
        .where((player) => player.kind == WirePlayerKind.human)
        .length;
  }

  static int requiredHumanPlayers(WireMatch? match) {
    if (match == null) return defaultMinimumHumanPlayers;
    return match.minPlayers < defaultMinimumHumanPlayers
        ? defaultMinimumHumanPlayers
        : match.minPlayers;
  }

  static int maximumPlayers(WireMatch? match) {
    return match?.maxPlayers ?? defaultMaximumPlayers;
  }

  static bool hasRequiredHumans(WireMatch match) {
    return humanPlayerCount(match) >= requiredHumanPlayers(match);
  }

  static bool canLoadOrRun(WireMatch match) {
    return match.state == 'loading' || match.state == 'running';
  }

  static bool canEnter(WireMatch match) {
    return canLoadOrRun(match) && hasRequiredHumans(match);
  }

  static bool isTerminal(WireMatch match) {
    return match.state == 'finished' || match.state == 'abandoned';
  }

  static String? playerIdForUser(WireMatch match, String userId) {
    for (final player in match.players) {
      if (player.userId == userId) return player.id;
    }
    return null;
  }

  static bool isOwner(WireMatch? match, String? userId) {
    if (match == null || userId == null) return false;
    return match.ownerUserId == userId;
  }

  static bool canStartPrivateMatch({
    required WireMatch? match,
    required String? userId,
    required bool busy,
  }) {
    if (match == null || busy || match.state != 'open') return false;
    if (!isOwner(match, userId)) return false;
    return hasRequiredHumans(match);
  }
}
