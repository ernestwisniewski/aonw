import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/lobby_presence_policy.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:test/test.dart';

void main() {
  const policy = LobbyPresencePolicy(
    initialConnectionTimeout: Duration(seconds: 20),
    connectedPresenceTimeout: Duration(seconds: 30),
    reconnectGracePeriod: Duration(seconds: 10),
  );
  final now = DateTime.utc(2026, 8, 8, 12);

  test('uses distinct initial, connected, and reconnect deadlines', () {
    expect(
      policy
          .initialLease(
            userIdentifier: 'user-1',
            connectionGeneration: 'initial',
            nowUtc: now,
          )
          .expiresAt,
      now.add(const Duration(seconds: 20)),
    );
    expect(
      policy
          .connectedLease(
            userIdentifier: 'user-1',
            connectionGeneration: 'connected',
            nowUtc: now,
          )
          .expiresAt,
      now.add(const Duration(seconds: 30)),
    );
    expect(
      policy
          .reconnectLease(
            userIdentifier: 'user-1',
            connectionGeneration: 'reconnect',
            nowUtc: now,
          )
          .expiresAt,
      now.add(const Duration(seconds: 10)),
    );
  });

  test('requires both connected projection and a live durable lease', () {
    final liveLease = policy.connectedLease(
      userIdentifier: 'owner',
      connectionGeneration: 'generation-1',
      nowUtc: now,
    );
    final state = _state(
      ownerConnection: WirePlayerConnectionState.connected,
      presenceLeases: {'owner': liveLease},
    );

    expect(policy.hasLiveConnectedOwner(state, nowUtc: now), isTrue);
    expect(
      policy.hasLiveConnectedOwner(state, nowUtc: liveLease.expiresAt),
      isFalse,
    );
    expect(
      policy.hasLiveConnectedOwner(
        _state(
          ownerConnection: WirePlayerConnectionState.reconnecting,
          presenceLeases: {'owner': liveLease},
        ),
        nowUtc: now,
      ),
      isFalse,
    );
  });
}

StoredMatchState _state({
  required WirePlayerConnectionState ownerConnection,
  required Map<String, StoredMatchPresenceLease> presenceLeases,
}) {
  final createdAt = DateTime.utc(2026, 8, 8, 12);
  return StoredMatchState(
    match: WireMatch(
      id: 'match-1',
      ownerUserId: 'owner',
      name: 'Lobby',
      mapName: 'verdantia',
      players: [
        WirePlayer(
          id: 'player-1',
          userId: 'owner',
          name: 'Owner',
          colorValue: 0,
          country: PlayerCountry.poland,
          kind: WirePlayerKind.human,
          connectionState: ownerConnection,
          ready: false,
        ),
      ],
      maxPlayers: 2,
      minPlayers: 2,
      quickplay: false,
      turn: 0,
      state: 'open',
      createdAt: createdAt,
    ),
    snapshot: const WireSnapshot(
      matchId: 'match-1',
      offset: 0,
      save: {},
      state: {'phase': 'lobby'},
    ),
    presenceLeases: presenceLeases,
  );
}
