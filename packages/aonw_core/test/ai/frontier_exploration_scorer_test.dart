import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('AiFrontierExplorationScorer', () {
    test(
      'pulls scouts toward hidden legal city centers beyond reveal range',
      () {
        final mapData = _openMap(cols: 9, rows: 9);
        final state = PersistentGameState(
          units: const [],
          cities: const [
            GameCity(
              id: 'own_capital',
              ownerPlayerId: 'player_1',
              name: 'Capital',
              center: CityHex(col: 6, row: 1),
            ),
            GameCity(
              id: 'own_second',
              ownerPlayerId: 'player_1',
              name: 'Second',
              center: CityHex(col: 8, row: 3),
            ),
            GameCity(
              id: 'enemy_north',
              ownerPlayerId: 'player_2',
              name: 'Enemy North',
              center: CityHex(col: 3, row: 0),
            ),
            GameCity(
              id: 'enemy_west',
              ownerPlayerId: 'player_2',
              name: 'Enemy West',
              center: CityHex(col: 2, row: 3),
            ),
            GameCity(
              id: 'enemy_south',
              ownerPlayerId: 'player_3',
              name: 'Enemy South',
              center: CityHex(col: 6, row: 5),
            ),
          ],
          fogOfWar: _fogForHexes(
            visibleHexes: {
              const HexCoordinate(col: 6, row: 1),
              const HexCoordinate(col: 8, row: 3),
            },
            discoveredHexes: {
              const HexCoordinate(col: 3, row: 0),
              const HexCoordinate(col: 2, row: 3),
              const HexCoordinate(col: 6, row: 5),
            },
          ),
        );
        final view = _view(state, mapData);
        const scorer = AiFrontierExplorationScorer();

        final farScore = scorer.citySiteDiscoveryScore(
          view: view,
          origin: const HexCoordinate(col: 4, row: 0),
        );
        final closerScore = scorer.citySiteDiscoveryScore(
          view: view,
          origin: const HexCoordinate(col: 1, row: 1),
        );

        expect(closerScore, greaterThan(farScore));
      },
    );

    test('scores hidden second-city centers around a one-city empire', () {
      final mapData = _openMap(cols: 9, rows: 9);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 6,
            row: 0,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 6, row: 1),
          ),
          GameCity(
            id: 'enemy_west',
            ownerPlayerId: 'player_2',
            name: 'Enemy West',
            center: CityHex(col: 2, row: 3),
          ),
        ],
        fogOfWar: _fogForHexes(
          visibleHexes: {const HexCoordinate(col: 6, row: 1)},
          discoveredHexes: {const HexCoordinate(col: 2, row: 3)},
        ),
      );
      final view = _view(state, mapData);
      const scorer = AiFrontierExplorationScorer();

      expect(
        AiFrontierExplorationScorer.needsCitySiteDiscovery(
          view: view,
          plan: const StrategicPlan(
            computedAtTurn: 1,
            mode: StrategicMode.recover,
            expectations: EconomyExpectations(
              expectedCityCount: 2,
              expectedWorkerCount: 1,
              expectedMilitaryCount: 1,
              goldReserveTarget: 8,
              minimumSciencePerTurn: 2,
            ),
          ),
        ),
        isTrue,
      );
      expect(
        scorer.citySiteDiscoveryScore(
          view: view,
          origin: const HexCoordinate(col: 4, row: 0),
        ),
        greaterThan(0),
      );
    });
  });
}

GameView _view(PersistentGameState state, MapData mapData) {
  return GameView.fromPersistentState(
    state,
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

FogOfWarState _fogForHexes({
  required Set<HexCoordinate> visibleHexes,
  required Set<HexCoordinate> discoveredHexes,
}) {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        visibleHexes: visibleHexes,
        discoveredHexes: discoveredHexes,
      ),
    },
  );
}

MapData _openMap({required int cols, required int rows}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
