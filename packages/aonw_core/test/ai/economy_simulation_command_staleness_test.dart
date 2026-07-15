import 'package:aonw_core/ai/simulation/economy_simulation_command_staleness.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:test/test.dart';

void main() {
  group('Economy simulation command staleness', () {
    test('accepts a valid attack using WorldMap tiles', () {
      final mapTiles = _CountingMapTiles(WorldMapReadView(_worldMap()));

      expect(_isStale(mapTiles: mapTiles), isFalse);
      expect(mapTiles.reads, {(col: 0, row: 0): 1, (col: 1, row: 0): 1});
    });

    test(
      'rejects an attack when its attacker tile is absent from WorldMap',
      () {
        final mapTiles = WorldMapReadView(_worldMap(includeAttacker: false));

        expect(_isStale(mapTiles: mapTiles), isTrue);
      },
    );
  });
}

bool _isStale({required MapTileLookup mapTiles}) {
  return isStaleEconomySimulationCommand(
    command: const AttackHexCommand('attacker', 1, 0),
    state: PersistentGameState(
      units: [
        _unit('attacker', 'player_1', 0, 0),
        _unit('defender', 'player_2', 1, 0),
      ],
    ),
    actorPlayerId: 'player_1',
    ruleset: GameRuleset.defaults,
    mapTiles: mapTiles,
  );
}

final class _CountingMapTiles implements MapTileLookup {
  _CountingMapTiles(this._delegate);

  final MapTileLookup _delegate;
  final Map<({int col, int row}), int> reads = {};

  @override
  MapTileView? tileAt(int col, int row) {
    final coordinate = (col: col, row: row);
    reads.update(coordinate, (count) => count + 1, ifAbsent: () => 1);
    return _delegate.tileAt(col, row);
  }
}

GameUnit _unit(String id, String ownerPlayerId, int col, int row) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.warrior,
    name: id,
    col: col,
    row: row,
  );
}

WorldMap _worldMap({bool includeAttacker = true}) {
  return WorldMap(
    cols: 2,
    rows: 1,
    tiles: [if (includeAttacker) _tile(0), _tile(1)],
  );
}

WorldTile _tile(int col) {
  return WorldTile(
    coordinate: HexCoord(col: col, row: 0),
    terrains: const [TerrainType.plains],
    resources: const [],
    height: 0,
  );
}
