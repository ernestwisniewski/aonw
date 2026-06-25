import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkSession', () {
    test('copyWith can clear nullable match and player fields', () {
      final session = NetworkSession(
        userId: 'user_1',
        playerId: 'player_1',
        token: AuthToken('jwt-token'),
        refreshToken: 'refresh-token',
        matchId: 'match_1',
      );

      final cleared = session.copyWith(
        playerId: null,
        refreshToken: null,
        matchId: null,
      );

      expect(cleared.userId, 'user_1');
      expect(cleared.token.value, 'jwt-token');
      expect(cleared.playerId, isNull);
      expect(cleared.refreshToken, isNull);
      expect(cleared.matchId, isNull);
    });

    test('copyWith keeps nullable fields when they are omitted', () {
      final session = NetworkSession(
        userId: 'user_1',
        playerId: 'player_1',
        token: AuthToken('jwt-token'),
        refreshToken: 'refresh-token',
        matchId: 'match_1',
      );

      final copied = session.copyWith();

      expect(copied.playerId, 'player_1');
      expect(copied.refreshToken, 'refresh-token');
      expect(copied.matchId, 'match_1');
    });
  });
}
