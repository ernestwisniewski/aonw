import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:serverpod/serverpod.dart';

const defaultLobbyInitialConnectionTimeout = Duration(seconds: 20);
const defaultLobbyConnectedPresenceTimeout = Duration(seconds: 30);
const defaultLobbyReconnectGracePeriod = Duration(seconds: 10);

abstract interface class PresenceGenerationGenerator {
  String next();
}

final class UuidPresenceGenerationGenerator
    implements PresenceGenerationGenerator {
  const UuidPresenceGenerationGenerator();

  @override
  String next() => const Uuid().v4();
}

/// Pure deadline and liveness rules for server-owned lobby presence leases.
final class LobbyPresencePolicy {
  const LobbyPresencePolicy({
    this.initialConnectionTimeout = defaultLobbyInitialConnectionTimeout,
    this.connectedPresenceTimeout = defaultLobbyConnectedPresenceTimeout,
    this.reconnectGracePeriod = defaultLobbyReconnectGracePeriod,
  });

  final Duration initialConnectionTimeout;
  final Duration connectedPresenceTimeout;
  final Duration reconnectGracePeriod;

  StoredMatchPresenceLease initialLease({
    required String userIdentifier,
    required String connectionGeneration,
    required DateTime nowUtc,
  }) {
    return _lease(
      userIdentifier: userIdentifier,
      connectionGeneration: connectionGeneration,
      nowUtc: nowUtc,
      duration: initialConnectionTimeout,
    );
  }

  StoredMatchPresenceLease connectedLease({
    required String userIdentifier,
    required String connectionGeneration,
    required DateTime nowUtc,
  }) {
    return _lease(
      userIdentifier: userIdentifier,
      connectionGeneration: connectionGeneration,
      nowUtc: nowUtc,
      duration: connectedPresenceTimeout,
    );
  }

  StoredMatchPresenceLease reconnectLease({
    required String userIdentifier,
    required String connectionGeneration,
    required DateTime nowUtc,
  }) {
    return _lease(
      userIdentifier: userIdentifier,
      connectionGeneration: connectionGeneration,
      nowUtc: nowUtc,
      duration: reconnectGracePeriod,
    );
  }

  bool isLiveConnectedParticipant(
    StoredMatchState state,
    WirePlayer player, {
    required DateTime nowUtc,
  }) {
    if (player.connectionState != WirePlayerConnectionState.connected) {
      return false;
    }
    final lease = state.presenceLeases[player.userId];
    return lease != null && !lease.isExpiredAt(nowUtc);
  }

  bool hasLiveConnectedOwner(
    StoredMatchState state, {
    required DateTime nowUtc,
  }) {
    for (final player in state.match.players) {
      if (player.userId == state.match.ownerUserId &&
          isLiveConnectedParticipant(state, player, nowUtc: nowUtc)) {
        return true;
      }
    }
    return false;
  }

  bool allHumanMembersLiveConnected(
    StoredMatchState state, {
    required DateTime nowUtc,
  }) {
    var humanCount = 0;
    for (final player in state.match.players) {
      if (player.kind != WirePlayerKind.human) continue;
      humanCount += 1;
      if (!isLiveConnectedParticipant(state, player, nowUtc: nowUtc)) {
        return false;
      }
    }
    return humanCount > 0;
  }

  StoredMatchPresenceLease _lease({
    required String userIdentifier,
    required String connectionGeneration,
    required DateTime nowUtc,
    required Duration duration,
  }) {
    final now = nowUtc.toUtc();
    return StoredMatchPresenceLease(
      userIdentifier: userIdentifier,
      connectionGeneration: connectionGeneration,
      expiresAt: now.add(duration),
      updatedAt: now,
    );
  }
}
