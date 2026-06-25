import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_rng.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_artifact_logistics_planner.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyArtifactLogisticsPlanner', () {
    test('stores carrier standing in empty city storage', () {
      final carrier = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      ).copyWithCarriedArtifact('artifact_1');
      final usedUnitIds = <String>{};
      final reservedHexes = <HexCoordinate>{};
      final view = _view(
        units: [carrier],
        cities: const [_capital],
        artifacts: const [
          WorldArtifact(
            id: 'artifact_1',
            type: WorldArtifactType.heroSword,
            location: WorldArtifactLocation.carried(unitId: 'warrior_1'),
          ),
        ],
      );

      final commands = const BasicStrategyArtifactLogisticsPlanner().plan(
        view,
        _context(view),
        usedUnitIds,
        reservedHexes,
      );

      expect(commands, const [
        StoreArtifactInCityCommand('warrior_1', cityId: 'city_1'),
      ]);
      expect(usedUnitIds, {'warrior_1'});
      expect(reservedHexes, isEmpty);
    });

    test('starts excavation when a collector stands on a visible artifact', () {
      final scout = GameUnit.produced(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        col: 1,
        row: 0,
      );
      final usedUnitIds = <String>{};
      final reservedHexes = <HexCoordinate>{};
      final view = _view(
        units: [scout],
        cities: const [],
        artifacts: [
          WorldArtifact.placed(
            type: WorldArtifactType.astronomersTablets,
            col: 1,
            row: 0,
          ),
        ],
      );

      final commands = const BasicStrategyArtifactLogisticsPlanner().plan(
        view,
        _context(view),
        usedUnitIds,
        reservedHexes,
      );

      expect(commands, const [StartArtifactExcavationCommand('scout_1')]);
      expect(usedUnitIds, {'scout_1'});
      expect(reservedHexes, isEmpty);
    });

    test('moves carrier home and scout toward visible artifact', () {
      final carrier = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 1,
        row: 0,
      ).copyWithCarriedArtifact('artifact_1');
      final scout = GameUnit.produced(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        col: 3,
        row: 0,
      );
      final usedUnitIds = <String>{};
      final reservedHexes = <HexCoordinate>{};
      final view = _view(
        units: [carrier, scout],
        cities: const [_capital, _satellite],
        artifacts: [
          const WorldArtifact(
            id: 'artifact_1',
            type: WorldArtifactType.heroSword,
            location: WorldArtifactLocation.carried(unitId: 'warrior_1'),
          ),
          WorldArtifact.placed(
            type: WorldArtifactType.queensMirror,
            col: 4,
            row: 0,
          ),
        ],
      );

      final commands = const BasicStrategyArtifactLogisticsPlanner().plan(
        view,
        _context(view),
        usedUnitIds,
        reservedHexes,
      );

      expect(commands, contains(const MoveUnitCommand('warrior_1', 0, 0)));
      expect(commands, contains(const MoveUnitCommand('scout_1', 4, 0)));
      expect(usedUnitIds, {'scout_1', 'warrior_1'});
      expect(
        reservedHexes,
        containsAll(const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 4, row: 0),
        ]),
      );
    });

    test('moves carrier into rough city even beyond artifact movement cap', () {
      final carrier = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      ).copyWith(movementPoints: 2).copyWithCarriedArtifact('artifact_1');
      final mapData = _map(
        cols: 2,
        rows: 1,
        terrainOverrides: {
          (col: 1, row: 0): const [
            TerrainType.grassland,
            TerrainType.forest,
            TerrainType.hills,
          ],
        },
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 1, row: 0),
      );
      final usedUnitIds = <String>{};
      final reservedHexes = <HexCoordinate>{};
      final view = _view(
        units: [carrier],
        cities: const [city],
        artifacts: const [
          WorldArtifact(
            id: 'artifact_1',
            type: WorldArtifactType.heroSword,
            location: WorldArtifactLocation.carried(unitId: 'warrior_1'),
          ),
        ],
        mapData: mapData,
      );

      final commands = const BasicStrategyArtifactLogisticsPlanner().plan(
        view,
        _context(view),
        usedUnitIds,
        reservedHexes,
      );

      expect(commands, const [MoveUnitCommand('warrior_1', 1, 0)]);
      expect(usedUnitIds, {'warrior_1'});
      expect(reservedHexes, {const HexCoordinate(col: 1, row: 0)});
    });

    test('skips artifact collectors that cannot enter target terrain', () {
      final warrior = GameUnit.produced(
        id: 'a_warrior',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final cavalry = GameUnit.produced(
        id: 'b_cavalry',
        ownerPlayerId: 'player_1',
        type: GameUnitType.cavalry,
        col: 2,
        row: 0,
      );
      final mapData = _map(
        cols: 3,
        rows: 1,
        terrainOverrides: {
          (col: 1, row: 0): const [
            TerrainType.snow,
            TerrainType.forest,
            TerrainType.hills,
          ],
        },
      );
      final usedUnitIds = <String>{};
      final reservedHexes = <HexCoordinate>{};
      final view = _view(
        units: [warrior, cavalry],
        cities: const [],
        artifacts: [
          WorldArtifact.placed(
            type: WorldArtifactType.queensMirror,
            col: 1,
            row: 0,
          ),
        ],
        mapData: mapData,
      );

      final commands = const BasicStrategyArtifactLogisticsPlanner().plan(
        view,
        _context(view),
        usedUnitIds,
        reservedHexes,
      );

      expect(commands, const [MoveUnitCommand('b_cavalry', 1, 0)]);
      expect(usedUnitIds, {'b_cavalry'});
      expect(reservedHexes, {const HexCoordinate(col: 1, row: 0)});
    });
  });
}

GameView _view({
  required List<GameUnit> units,
  required List<GameCity> cities,
  required List<WorldArtifact> artifacts,
  MapData? mapData,
}) {
  return GameView(
    forPlayerId: 'player_1',
    turn: 1,
    ownUnits: units,
    ownCities: cities,
    artifacts: artifacts,
    ownResearch: PlayerResearchState.empty,
    ownImprovements: const [],
    visibleEnemyUnits: const [],
    rememberedEnemyCities: const [],
    visibility: const FogVisibilityQuery(
      playerId: '',
      state: FogOfWarState.empty,
    ),
    mapData: mapData ?? _mapData,
    ruleset: _ruleset,
  );
}

AiContext _context(GameView view) {
  return AiContext(
    ruleset: view.ruleset,
    mapData: view.mapData,
    turn: view.turn,
    rng: AiRng.fromTurn(
      turn: view.turn,
      playerId: view.forPlayerId,
      baseSeed: 11,
    ),
  );
}

const _capital = GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'Capital',
  center: CityHex(col: 0, row: 0),
);

const _satellite = GameCity(
  id: 'city_2',
  ownerPlayerId: 'player_1',
  name: 'Harbor',
  center: CityHex(col: 2, row: 0),
);

final _mapData = MapData(
  cols: 5,
  rows: 1,
  tiles: [
    for (var col = 0; col < 5; col++)
      TileData(
        col: col,
        row: 0,
        terrains: const [TerrainType.plains],
        resources: const [],
        height: 0,
      ),
  ],
);

MapData _map({
  required int cols,
  required int rows,
  Map<({int col, int row}), List<TerrainType>> terrainOverrides = const {},
}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
            col: col,
            row: row,
            terrains:
                terrainOverrides[(col: col, row: row)] ??
                const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

const _ruleset = GameRuleset.defaults;
