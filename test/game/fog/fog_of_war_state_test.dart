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
