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
