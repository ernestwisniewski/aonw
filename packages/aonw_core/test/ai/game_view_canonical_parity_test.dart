import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('canonical and persistence GameView projections stay equivalent', () {
    final units = [
      GameUnit.startingCommander(ownerPlayerId: 'player_1', col: 0, row: 0),
      GameUnit.startingCommander(ownerPlayerId: 'player_2', col: 1, row: 0),
    ];
    const cities = [
      GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
      ),
    ];
    final fog = FogOfWarState(
      players: {
        'player_1': PlayerFogOfWar(
          playerId: 'player_1',
          visibleHexes: {const HexCoordinate(col: 1, row: 0)},
        ),
      },
    );
    final diplomacy = DiplomacyState.empty.setStatus(
      'player_1',
      'player_2',
      DiplomaticRelationStatus.hostile,
    );
    final persistent = PersistentGameState(
      units: units,
      cities: cities,
      playerGold: const {'player_1': 42},
      fogOfWar: fog,
      runtimeState: GameRuntimeState(diplomacy: diplomacy),
    );
    final canonical = DomainState.snapshot(
      turn: 4,
      matchRules: MatchRules.standard,
      participants: const [
        Player(id: 'player_1', name: 'One', colorValue: 0xFF000001),
        Player(id: 'player_2', name: 'Two', colorValue: 0xFF000002),
      ],
      units: units,
      cities: cities,
      playerGold: const {'player_1': 42},
      fogOfWar: fog,
      diplomacy: diplomacy,
    );
    final legacyView = _legacyView(persistent);
    final canonicalView = _canonicalView(canonical);

    expect(canonicalView.ownUnits, legacyView.ownUnits);
    expect(canonicalView.ownCities, legacyView.ownCities);
    expect(canonicalView.visibleEnemyUnits, legacyView.visibleEnemyUnits);
    expect(
      canonicalView.movementBlockingUnits,
      legacyView.movementBlockingUnits,
    );
    expect(canonicalView.ownGold, legacyView.ownGold);
    expect(canonicalView.diplomacy, legacyView.diplomacy);
  });
}

GameView _legacyView(PersistentGameState state) => GameView.fromPersistentState(
  state,
  forPlayerId: 'player_1',
  turn: 4,
  mapData: _mapData,
  ruleset: GameRuleset.defaults,
);

GameView _canonicalView(DomainState state) => GameView.fromDomainState(
  state,
  forPlayerId: 'player_1',
  turn: 4,
  mapData: _mapData,
  ruleset: GameRuleset.defaults,
);

final _mapData = MapData(
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
