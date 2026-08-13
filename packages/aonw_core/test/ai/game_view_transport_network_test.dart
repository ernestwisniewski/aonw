import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('projects only owned and known foreign roads into a game view', () {
    final state = DomainState.snapshot(
      transportNetwork: TransportNetworkState(
        segments: const [
          TransportSegment(
            hex: HexCoord(col: 0, row: 0),
            builtByPlayerId: 'player_1',
          ),
          TransportSegment(
            hex: HexCoord(col: 2, row: 0),
            builtByPlayerId: 'player_2',
          ),
          TransportSegment(
            hex: HexCoord(col: 2, row: 1),
            builtByPlayerId: 'player_2',
          ),
        ],
      ),
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            discoveredHexes: {const HexCoordinate(col: 2, row: 0)},
            visibleHexes: {const HexCoordinate(col: 0, row: 0)},
          ),
        },
      ),
    );

    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 4,
      mapData: _mapData(),
      ruleset: GameRuleset.defaults,
    );

    expect(view.transportNetwork.hasOperationalRoadAt(0, 0), isTrue);
    expect(view.transportNetwork.hasOperationalRoadAt(2, 0), isTrue);
    expect(view.transportNetwork.hasOperationalRoadAt(2, 1), isFalse);
  });
}

WorldMap _mapData() => WorldMap(
  cols: 3,
  rows: 2,
  tiles: [
    for (var col = 0; col < 3; col++)
      for (var row = 0; row < 2; row++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);
