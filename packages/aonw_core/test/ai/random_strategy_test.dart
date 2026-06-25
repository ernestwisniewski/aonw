import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RandomStrategy', () {
    test('plans deterministic legal movement commands from visible tiles', () {
      final mapData = MapData(
        cols: 2,
        rows: 1,
        tiles: const [
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.plains],
            resources: [],
            height: 0,
          ),
          TileData(
            col: 1,
            row: 0,
            terrains: [TerrainType.plains],
            resources: [],
            height: 0,
          ),
        ],
      );
      final state = PersistentGameState(
        units: [
          GameUnit.startingCommander(ownerPlayerId: 'player_1', col: 0, row: 0),
        ],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: {
                const HexCoordinate(col: 0, row: 0),
                const HexCoordinate(col: 1, row: 0),
              },
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 1,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 1,
        rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 77),
      );

      final plan = const RandomStrategy().plan(view, context);

      expect(plan.commands, [
        const MoveUnitCommand('commander_player_1', 1, 0),
      ]);
      expect(plan.debug?.strategyId, 'random');
    });

    test('does not move into a reserved target hex', () {
      final mapData = MapData(
        cols: 2,
        rows: 1,
        tiles: const [
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.plains],
            resources: [],
            height: 0,
          ),
          TileData(
            col: 1,
            row: 0,
            terrains: [TerrainType.plains],
            resources: [],
            height: 0,
          ),
        ],
      );
      final state = PersistentGameState(
        units: [
          GameUnit.startingCommander(ownerPlayerId: 'player_1', col: 0, row: 0),
        ],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: {
                const HexCoordinate(col: 0, row: 0),
                const HexCoordinate(col: 1, row: 0),
              },
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 1,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 1,
        rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 77),
      );

      final plan = RandomStrategy(
        reservedHexes: {const HexCoordinate(col: 1, row: 0)},
      ).plan(view, context);

      expect(plan.commands, isEmpty);
    });
  });
}
