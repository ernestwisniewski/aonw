import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FogOfWarState', () {
    test('round-trips through JSON', () {
      final state = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            discoveredHexes: {const HexCoordinate(col: 1, row: 2)},
          ),
        },
      );

      expect(FogOfWarState.fromJson(state.toJson()), state);
    });

    test('takes an immutable snapshot of the source map', () {
      final playerOne = PlayerFogOfWar(playerId: 'player_1');
      final source = <String, PlayerFogOfWar>{'player_1': playerOne};
      final state = FogOfWarState(players: source);
      final originalHashCode = state.hashCode;
      final originalJson = state.toJson();

      source
        ..clear()
        ..['player_2'] = PlayerFogOfWar(playerId: 'player_2');

      expect(state.players, {'player_1': playerOne});
      expect(state.hashCode, originalHashCode);
      expect(state.toJson(), originalJson);
    });

    test('does not expose a mutable players map', () {
      final state = FogOfWarState(
        players: {'player_1': PlayerFogOfWar(playerId: 'player_1')},
      );

      expect(
        () => state.players['player_2'] = PlayerFogOfWar(playerId: 'player_2'),
        throwsUnsupportedError,
      );
      expect(state.players.clear, throwsUnsupportedError);
    });

    test('fromJson requires player id', () {
      expect(
        () => FogOfWarState.fromJson([
          {'discoveredHexes': <dynamic>[]},
        ]),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
