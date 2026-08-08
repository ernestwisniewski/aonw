import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:test/test.dart';

void main() {
  const policy = LobbyRosterPolicy();

  test('separates reserved members from connected humans', () {
    final match = _match([
      _player('owner', WirePlayerConnectionState.connected),
      _player('guest', WirePlayerConnectionState.reconnecting),
    ]);

    expect(policy.humanMemberCount(match), 2);
    expect(policy.connectedHumanCount(match), 1);
    expect(policy.hasConnectedOwner(match), isTrue);
    expect(policy.canStart(match), isFalse);
  });

  test('requires every human member to be connected before start', () {
    final startable = _match([
      _player('owner', WirePlayerConnectionState.connected),
      _player('guest', WirePlayerConnectionState.connected),
    ]);
    final offlineOwner = startable.copyWith(
      players: [
        _player('owner', WirePlayerConnectionState.offline),
        _player('guest', WirePlayerConnectionState.connected),
      ],
    );

    expect(policy.canStart(startable), isTrue);
    expect(policy.canStart(offlineOwner), isFalse);
    expect(policy.hasConnectedOwner(offlineOwner), isFalse);
    expect(policy.containsUser(startable, 'guest'), isTrue);
  });
}

WireMatch _match(List<WirePlayer> players) {
  return WireMatch(
    id: 'match-1',
    ownerUserId: 'owner',
    name: 'Lobby',
    mapName: 'verdantia',
    players: players,
    maxPlayers: 4,
    minPlayers: 2,
    turn: 0,
    state: 'open',
    createdAt: DateTime.utc(2026, 8, 8),
  );
}

WirePlayer _player(String userId, WirePlayerConnectionState state) {
  return WirePlayer(
    id: 'player-$userId',
    userId: userId,
    name: userId,
    colorValue: 0,
    country: PlayerCountry.poland,
    kind: WirePlayerKind.human,
    connectionState: state,
  );
}
