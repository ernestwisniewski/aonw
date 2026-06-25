import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_rng.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_artifact_defense_planner.dart';
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
  group('BasicStrategyArtifactDefensePlanner', () {
    test('waits until the empire has four stored artifact cities', () {
      final guard = GameUnit.produced(
        id: 'guard_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 2,
        row: 2,
      );
      final view = _view(
        units: [guard],
        cities: const [_city1, _city2, _city3],
        artifacts: const [_storedArtifact1, _storedArtifact2, _storedArtifact3],
      );

      final commands = const BasicStrategyArtifactDefensePlanner().plan(
        view,
        _context(view),
        <String>{},
        <HexCoordinate>{},
      );

      expect(commands, isEmpty);
    });

    test(
      'moves available defender toward the first unguarded artifact city',
      () {
        final guard = GameUnit.produced(
          id: 'guard_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 2,
          row: 2,
        );
        final usedUnitIds = <String>{};
        final reservedHexes = <HexCoordinate>{};
        final view = _view(
          units: [guard],
          cities: const [_city1, _city2, _city3, _city4],
          artifacts: const [
            _storedArtifact1,
            _storedArtifact2,
            _storedArtifact3,
            _storedArtifact4,
          ],
        );

        final commands = const BasicStrategyArtifactDefensePlanner().plan(
          view,
          _context(view),
          usedUnitIds,
          reservedHexes,
        );

        expect(commands, hasLength(1));
        final move = commands.single as MoveUnitCommand;
        expect(move.unitId, 'guard_1');
        expect(
          HexDistance.between(
            HexCoordinate(col: move.targetCol, row: move.targetRow),
            _city1.center.toCoordinate(),
          ),
          lessThan(
            HexDistance.between(
              const HexCoordinate(col: 2, row: 2),
              _city1.center.toCoordinate(),
            ),
          ),
        );
        expect(usedUnitIds, {'guard_1'});
        expect(
          reservedHexes,
          contains(HexCoordinate(col: move.targetCol, row: move.targetRow)),
        );
      },
    );

    test('plans at most three artifact defense moves per turn', () {
      final guards = [
        GameUnit.produced(
          id: 'guard_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 2,
          row: 2,
        ),
        GameUnit.produced(
          id: 'guard_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.archer,
          col: 3,
          row: 2,
        ),
        GameUnit.produced(
          id: 'guard_3',
          ownerPlayerId: 'player_1',
          type: GameUnitType.spearman,
          col: 2,
          row: 3,
        ),
        GameUnit.produced(
          id: 'guard_4',
          ownerPlayerId: 'player_1',
          type: GameUnitType.cavalry,
          col: 3,
          row: 3,
        ),
      ];
      final usedUnitIds = <String>{};
      final view = _view(
        units: guards,
        cities: const [_city1, _city2, _city3, _city4],
        artifacts: const [
          _storedArtifact1,
          _storedArtifact2,
          _storedArtifact3,
          _storedArtifact4,
        ],
      );

      final commands = const BasicStrategyArtifactDefensePlanner().plan(
        view,
        _context(view),
        usedUnitIds,
        <HexCoordinate>{},
      );

      expect(commands, hasLength(3));
      expect(commands.whereType<MoveUnitCommand>(), hasLength(3));
      expect(usedUnitIds, hasLength(3));
    });
  });
}

GameView _view({
  required List<GameUnit> units,
  required List<GameCity> cities,
  required List<WorldArtifact> artifacts,
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
    mapData: _mapData,
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
      baseSeed: 13,
    ),
  );
}

const _city1 = GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'Northwest',
  center: CityHex(col: 0, row: 0),
);

const _city2 = GameCity(
  id: 'city_2',
  ownerPlayerId: 'player_1',
  name: 'Northeast',
  center: CityHex(col: 4, row: 0),
);

const _city3 = GameCity(
  id: 'city_3',
  ownerPlayerId: 'player_1',
  name: 'Southwest',
  center: CityHex(col: 0, row: 4),
);

const _city4 = GameCity(
  id: 'city_4',
  ownerPlayerId: 'player_1',
  name: 'Southeast',
  center: CityHex(col: 4, row: 4),
);

const _storedArtifact1 = WorldArtifact(
  id: 'artifact_1',
  type: WorldArtifactType.heroSword,
  location: WorldArtifactLocation.stored(cityId: 'city_1'),
);

const _storedArtifact2 = WorldArtifact(
  id: 'artifact_2',
  type: WorldArtifactType.queensMirror,
  location: WorldArtifactLocation.stored(cityId: 'city_2'),
);

const _storedArtifact3 = WorldArtifact(
  id: 'artifact_3',
  type: WorldArtifactType.astronomersTablets,
  location: WorldArtifactLocation.stored(cityId: 'city_3'),
);

const _storedArtifact4 = WorldArtifact(
  id: 'artifact_4',
  type: WorldArtifactType.templeReliquary,
  location: WorldArtifactLocation.stored(cityId: 'city_4'),
);

final _mapData = MapData(
  cols: 5,
  rows: 5,
  tiles: [
    for (var row = 0; row < 5; row++)
      for (var col = 0; col < 5; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

const _ruleset = GameRuleset.defaults;
