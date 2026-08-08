import 'package:aonw_core/protocol/wire_match.dart';
import 'package:aonw_core/protocol/wire_player.dart';

/// Shared, transport-neutral rules for interpreting a lobby roster.
///
/// Membership and live presence are deliberately separate: reconnecting or
/// offline players can temporarily retain a seat, but they are not counted as
/// active and cannot make an open lobby startable.
final class LobbyRosterPolicy {
  const LobbyRosterPolicy();

  int humanMemberCount(WireMatch match) {
    var count = 0;
    for (final player in match.players) {
      if (player.kind == WirePlayerKind.human) count += 1;
    }
    return count;
  }

  int connectedHumanCount(WireMatch match) {
    var count = 0;
    for (final player in match.players) {
      if (isConnectedHuman(player)) count += 1;
    }
    return count;
  }

  bool isConnectedHuman(WirePlayer player) {
    return player.kind == WirePlayerKind.human &&
        player.connectionState == WirePlayerConnectionState.connected;
  }

  bool containsUser(WireMatch match, String userIdentifier) {
    return match.players.any((player) => player.userId == userIdentifier);
  }

  bool hasConnectedOwner(WireMatch match) {
    return match.players.any(
      (player) =>
          player.userId == match.ownerUserId && isConnectedHuman(player),
    );
  }

  bool allHumanMembersConnected(WireMatch match) {
    final members = humanMemberCount(match);
    return members > 0 && connectedHumanCount(match) == members;
  }

  bool canStart(WireMatch match) {
    return connectedHumanCount(match) >= match.minPlayers &&
        allHumanMembersConnected(match);
  }
}
