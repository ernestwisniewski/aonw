import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/player_seat_allocator.dart';
import 'package:test/test.dart';

void main() {
  group('PlayerSeatAllocator', () {
    const allocator = PlayerSeatAllocator();

    test('creates a human player with the requested civilization', () {
      final player = allocator.createHumanPlayer(
        userIdentifier: 'owner-user',
        index: 0,
        existingPlayers: const [],
        displayName: '  Owner Nick  ',
        requestedCountryId: PlayerCountry.japan.name,
      );

      expect(player.id, 'player-1-owner-user');
      expect(player.name, 'Owner Nick');
      expect(player.country, PlayerCountry.japan);
      expect(player.kind, WirePlayerKind.human);
      expect(player.ready, isFalse);
    });

    test('fills an unrequested seat with the next free civilization', () {
      final existing = [
        _player(country: PlayerCountry.poland),
        _player(id: 'player_2', country: PlayerCountry.ukraine),
      ];

      final player = allocator.createHumanPlayer(
        userIdentifier: 'guest-user',
        index: 2,
        existingPlayers: existing,
      );

      expect(player.country, PlayerCountry.germany);
    });

    test('rejects an occupied or unknown civilization', () {
      final existing = [_player(country: PlayerCountry.france)];

      expect(
        () => allocator.createHumanPlayer(
          userIdentifier: 'guest-user',
          index: 1,
          existingPlayers: existing,
          requestedCountryId: PlayerCountry.france.name,
        ),
        throwsA(_allocationFailure('country_unavailable')),
      );
      expect(
        () => allocator.createHumanPlayer(
          userIdentifier: 'guest-user',
          index: 1,
          existingPlayers: const [],
          requestedCountryId: 'atlantis',
        ),
        throwsA(_allocationFailure('country_unavailable')),
      );
    });
  });
}

WirePlayer _player({
  String id = 'player_1',
  PlayerCountry country = PlayerCountry.poland,
}) {
  return WirePlayer(
    id: id,
    userId: id,
    name: id,
    colorValue: 0,
    country: country,
    kind: WirePlayerKind.human,
    connectionState: WirePlayerConnectionState.connected,
  );
}

Matcher _allocationFailure(String code) {
  return isA<PlayerSeatAllocationFailure>().having(
    (error) => error.code,
    'code',
    code,
  );
}
