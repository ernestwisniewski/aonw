import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/run_save_ai_benchmark.dart' as benchmark;

void main() {
  test('benchmark combat maps ignoreFogOfWar to engine visibility', () {
    final attacker = GameUnit.produced(
      id: 'attacker',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      col: 0,
      row: 0,
    );
    final defender = GameUnit.produced(
      id: 'defender',
      ownerPlayerId: 'player_2',
      type: GameUnitType.settler,
      col: 1,
      row: 0,
    );
    final state = GameState(
      units: [attacker, defender],
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {const HexCoordinate(col: 0, row: 0)},
          ),
        },
      ),
    );
    final snapshot = SaveSnapshot.fromGameState(save: _save(), state: state);

    final authoritative =
        benchmark.BenchmarkCommandDispatcher(
          snapshot: snapshot.canonical,
          mapView: _map,
          ruleset: GameRuleset.standard(),
        ).apply(
          state: state,
          command: const AttackHexCommand('attacker', 1, 0),
          context: const GameCommandContext(
            actorPlayerId: 'player_1',
            ignoreFogOfWar: false,
          ),
        );
    final unrestricted =
        benchmark.BenchmarkCommandDispatcher(
          snapshot: snapshot.canonical,
          mapView: _map,
          ruleset: GameRuleset.standard(),
        ).apply(
          state: state,
          command: const AttackHexCommand('attacker', 1, 0),
          context: const GameCommandContext(
            actorPlayerId: 'player_1',
            ignoreFogOfWar: true,
          ),
        );

    expect(authoritative.accepted, isFalse);
    expect(authoritative.rejectionReasons, ['attack_target_not_visible']);
    expect(unrestricted.accepted, isTrue);
    expect(unrestricted.events.whereType<CombatResolvedEvent>(), hasLength(1));
  });
}

GameSave _save() => GameSave(
  id: 'save_1',
  name: 'Benchmark combat fog',
  mapName: 'benchmark',
  turn: 7,
  playerStates: const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.active,
  },
  savedAt: DateTime.utc(2026, 7, 29),
  camera: CameraState.zero,
  players: const [
    Player(id: 'player_1', name: 'One', colorValue: 1),
    Player(id: 'player_2', name: 'Two', colorValue: 2),
  ],
);

final _map = MapData(
  cols: 3,
  rows: 1,
  tiles: [
    for (var col = 0; col < 3; col++)
      TileData(
        col: col,
        row: 0,
        terrains: const [TerrainType.plains],
        resources: const [],
        height: 0,
      ),
  ],
);
