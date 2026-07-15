import 'package:aonw_core/ai/simulation/economy_simulation_command_staleness.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:test/test.dart';

void main() {
  group('Economy simulation command staleness', () {
    test('accepts a valid attack using WorldMap tiles', () {
      expect(_isStale(worldMap: _worldMap()), isFalse);
    });

    test(
      'rejects an attack when its attacker tile is absent from WorldMap',
      () {
        expect(_isStale(worldMap: _worldMap(includeAttacker: false)), isTrue);
      },
    );
  });
}

bool _isStale({required WorldMap worldMap}) {
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
    worldMap: worldMap,
  );
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
