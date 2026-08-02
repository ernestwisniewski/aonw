import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/game_match_row_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('gameMatchRowForState', () {
    test('copies canonical wire state and starts a running match', () {
      final createdAt = DateTime.utc(2026, 7, 1);
      final startedAt = DateTime.utc(2026, 7, 2);
      final endedAt = DateTime.utc(2026, 7, 3);
      final autoStartAt = DateTime.utc(2026, 7, 1, 12);
      final row = _row(createdAt: createdAt);
      final match = _match(
        createdAt: createdAt,
        state: 'running',
        endedAt: endedAt,
        autoStartAt: autoStartAt,
      );

      final updated = gameMatchRowForState(row, match, startedAt);

      expect(updated.ownerUserIdentifier, 'new-owner');
      expect(updated.name, 'New name');
      expect(updated.mapName, 'new-map');
      expect(updated.state, 'running');
      expect(updated.turn, 7);
      expect(updated.maxPlayers, 6);
      expect(updated.minPlayers, 3);
      expect(updated.private, isTrue);
      expect(updated.quickplay, isTrue);
      expect(updated.endedAt, endedAt);
      expect(updated.outcomeCondition, 'conquest');
      expect(updated.winnerPlayerId, 'winner');
      expect(updated.autoStartAt, autoStartAt);
      expect(updated.inviteCode, 'SECRET');
      expect(updated.startedAt, startedAt);
    });

    test('preserves the existing start timestamp outside running state', () {
      final createdAt = DateTime.utc(2026, 7, 1);
      final existingStartedAt = DateTime.utc(2026, 7, 1, 8);
      final row = _row(createdAt: createdAt, startedAt: existingStartedAt);

      final updated = gameMatchRowForState(
        row,
        _match(createdAt: createdAt, state: 'completed'),
        DateTime.utc(2026, 7, 2),
      );

      expect(updated.startedAt, existingStartedAt);
    });
  });

  group('wire match mapping', () {
    test('maps a stored match and its ordered roster to the wire model', () {
      final createdAt = DateTime.utc(2026, 7, 1);
      final endedAt = DateTime.utc(2026, 7, 4);
      final autoStartAt = DateTime.utc(2026, 7, 1, 12);
      final row = _row(createdAt: createdAt).copyWith(
        ownerUserIdentifier: 'owner',
        name: 'Stored name',
        mapName: 'verdantia',
        state: 'completed',
        turn: 9,
        maxPlayers: 6,
        minPlayers: 3,
        quickplay: true,
        endedAt: endedAt,
        outcomeCondition: 'science',
        winnerPlayerId: 'player-1',
        autoStartAt: autoStartAt,
        inviteCode: 'PRIVATE',
      );

      final match = wireMatchFromRow(row, [_playerRow()]);

      expect(match.id, 'match');
      expect(match.ownerUserId, 'owner');
      expect(match.name, 'Stored name');
      expect(match.mapName, 'verdantia');
      expect(match.players, hasLength(1));
      expect(match.maxPlayers, 6);
      expect(match.minPlayers, 3);
      expect(match.quickplay, isTrue);
      expect(match.turn, 9);
      expect(match.state, 'completed');
      expect(match.createdAt, createdAt);
      expect(match.endedAt, endedAt);
      expect(match.outcomeCondition, 'science');
      expect(match.winnerPlayerId, 'player-1');
      expect(match.autoStartAt, autoStartAt);
      expect(match.inviteCode, 'PRIVATE');
    });

    test('maps every persisted player presentation field', () {
      final player = wirePlayerFromRow(_playerRow());

      expect(player.id, 'player-1');
      expect(player.userId, 'user-1');
      expect(player.name, 'Player one');
      expect(player.colorValue, 0xFF123456);
      expect(player.country.name, 'netherlands');
      expect(player.kind, WirePlayerKind.human);
      expect(player.connectionState, WirePlayerConnectionState.reconnecting);
      expect(player.ready, isTrue);
    });
  });

  test('gamePlayerRow preserves wire identity and seat order', () {
    const player = WirePlayer(
      id: 'player-2',
      userId: 'user-2',
      name: 'Player two',
      colorValue: 0xFF654321,
      country: PlayerCountry.japan,
      kind: WirePlayerKind.human,
      connectionState: WirePlayerConnectionState.offline,
      ready: true,
    );

    final row = gamePlayerRow(42, player, 3);

    expect(row.matchId, 42);
    expect(row.publicPlayerId, 'player-2');
    expect(row.userIdentifier, 'user-2');
    expect(row.displayName, 'Player two');
    expect(row.colorValue, 0xFF654321);
    expect(row.countryId, 'japan');
    expect(row.kind, 'human');
    expect(row.connectionState, 'offline');
    expect(row.ready, isTrue);
    expect(row.seatOrder, 3);
  });
}

GameMatch _row({required DateTime createdAt, DateTime? startedAt}) {
  return GameMatch(
    publicId: 'match',
    ownerUserIdentifier: 'old-owner',
    name: 'Old name',
    mapName: 'old-map',
    state: 'lobby',
    turn: 1,
    maxPlayers: 2,
    minPlayers: 2,
    private: false,
    quickplay: false,
    createdAt: createdAt,
    startedAt: startedAt,
  );
}

WireMatch _match({
  required DateTime createdAt,
  required String state,
  DateTime? endedAt,
  DateTime? autoStartAt,
}) {
  return WireMatch(
    id: 'match',
    ownerUserId: 'new-owner',
    name: 'New name',
    mapName: 'new-map',
    players: const [],
    maxPlayers: 6,
    minPlayers: 3,
    quickplay: true,
    turn: 7,
    state: state,
    createdAt: createdAt,
    endedAt: endedAt,
    outcomeCondition: 'conquest',
    winnerPlayerId: 'winner',
    autoStartAt: autoStartAt,
    inviteCode: 'SECRET',
  );
}

GamePlayer _playerRow() => GamePlayer(
  id: 11,
  matchId: 7,
  publicPlayerId: 'player-1',
  userIdentifier: 'user-1',
  displayName: 'Player one',
  colorValue: 0xFF123456,
  countryId: 'netherlands',
  kind: 'human',
  connectionState: 'reconnecting',
  ready: true,
  seatOrder: 0,
);
