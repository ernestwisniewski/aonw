import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_context.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_orchestrator.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_state.dart';
import 'package:test/test.dart';

void main() {
  test('movement-point reset does not rebuild unchanged fog', () {
    final counters = FogOfWarRecomputeCounters();
    final unit = GameUnit.startingWarrior(
      ownerPlayerId: 'player_1',
    ).copyWith(movementPoints: 0);
    const origin = HexCoordinate(col: 0, row: 0);
    final fog = FogOfWarState(
      players: {
        'player_1': PlayerFogOfWar(
          playerId: 'player_1',
          discoveredHexes: {origin},
          visibleHexes: {origin},
        ),
      },
    );

    final result = TurnMovementOrchestrator.resetForPlayers(
      state: TurnMovementState(
        units: [unit],
        cities: const [],
        diplomacy: DiplomacyState.empty,
        fogOfWar: fog,
        interaction: DomainActionState.empty,
      ),
      context: TurnMovementContext(
        playerIds: const {'player_1'},
        phaseKnownPlayerIds: const {'player_1'},
        mapData: _lineMap(),
        fogOfWarService: FogOfWarService(counters: counters),
        fogRecomputedBeforePhase: true,
      ),
    );

    expect(result.changed, isTrue);
    expect(result.executions, isEmpty);
    expect(result.state.fogOfWar, same(fog));
    expect(counters.fullRecomputeCount, 0);
  });
}

WorldMap _lineMap() {
  return WorldMap(
    cols: 3,
    rows: 1,
    tiles: [
      for (var col = 0; col < 3; col++)
        WorldTile.at(
          coordinate: HexCoord(col: col, row: 0),
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
