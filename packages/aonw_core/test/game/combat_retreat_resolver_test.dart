import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CombatRetreatResolver.destinationIfAvailable', () {
    test('does not read tiles when the defender cannot counter', () {
      var tileReads = 0;

      final destination = CombatRetreatResolver.destinationIfAvailable(
        canCounter: false,
        attacker: _attacker,
        defender: _defender,
        units: [_attacker, _defender],
        tileAt: (col, row) {
          tileReads += 1;
          return _tile(col, row);
        },
      );

      expect(destination, isNull);
      expect(tileReads, 0);
    });

    test('returns null when no tile lookup is available', () {
      final destination = CombatRetreatResolver.destinationIfAvailable(
        canCounter: true,
        attacker: _attacker,
        defender: _defender,
        units: [_attacker, _defender],
        tileAt: null,
      );

      expect(destination, isNull);
    });
  });
}

final _attacker = GameUnit(
  id: 'attacker_1',
  ownerPlayerId: 'player_1',
  type: GameUnitType.warrior,
  name: 'warrior',
  col: 0,
  row: 0,
);

final _defender = GameUnit(
  id: 'defender_2',
  ownerPlayerId: 'player_2',
  type: GameUnitType.warrior,
  name: 'warrior',
  col: 1,
  row: 0,
);

TileData _tile(int col, int row) => TileData(
  col: col,
  row: row,
  terrains: const [TerrainType.grassland],
  resources: const [],
  height: 0,
);
