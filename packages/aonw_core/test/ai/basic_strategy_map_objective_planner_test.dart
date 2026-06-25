import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyMapObjectivePlanner', () {
    test('moves available military toward a valuable visible objective', () {
      final warrior = _unit('warrior_1');
      final view = _view(units: [warrior]);
      final usedUnitIds = <String>{};
      final reservedHexes = <HexCoordinate>{};

      final commands = const BasicStrategyMapObjectivePlanner().plan(
        view,
        _context(view),
        usedUnitIds,
        reservedHexes,
      );

      expect(commands, hasLength(1));
      final move = commands.single as MoveUnitCommand;
      expect(move.unitId, 'warrior_1');
      expect(
        HexDistance.between(
          HexCoordinate(col: move.targetCol, row: move.targetRow),
          const HexCoordinate(col: 3, row: 1),
        ),
        lessThan(
          HexDistance.between(
            const HexCoordinate(col: 0, row: 1),
            const HexCoordinate(col: 3, row: 1),
          ),
        ),
      );
      expect(usedUnitIds, {'warrior_1'});
      expect(
        reservedHexes,
        contains(HexCoordinate(col: move.targetCol, row: move.targetRow)),
      );
    });

    test('ignores completed objectives and civil units', () {
      final settler = _unit('settler_1', type: GameUnitType.settler);
      final warrior = _unit('warrior_1', col: 1);
      final view = _view(
        units: [settler, warrior],
        runtimeState: const GameRuntimeState(
          mapObjectiveHoldStatesByObjectiveId: {
            'pass_1': MapObjectiveHoldState(
              objectiveId: 'pass_1',
              playerId: 'player_1',
              holdTurns: 2,
            ),
          },
        ),
      );

      final commands = const BasicStrategyMapObjectivePlanner().plan(
        view,
        _context(view),
        <String>{},
        <HexCoordinate>{},
      );

      expect(commands, isEmpty);
    });

    test('does not divert an artifact carrier to a map objective', () {
      final carrier = _unit('warrior_1').copyWithCarriedArtifact('artifact_1');
      final view = _view(units: [carrier]);

      final commands = const BasicStrategyMapObjectivePlanner().plan(
        view,
        _context(view),
        <String>{},
        <HexCoordinate>{},
      );

      expect(commands, isEmpty);
    });

    test('is wired into BasicStrategy planning', () {
      final warrior = _unit('warrior_1');
      final view = _view(units: [warrior]);

      final plan = const BasicStrategy().plan(view, _context(view));

      expect(
        plan.commands.whereType<MoveUnitCommand>(),
        contains(
          isA<MoveUnitCommand>().having(
            (command) => command.unitId,
            'unitId',
            'warrior_1',
          ),
        ),
      );
    });
  });
}

AiContext _context(GameView view) {
  return AiContext(
    ruleset: view.ruleset,
    mapData: view.mapData,
    turn: view.turn,
    rng: AiRng.fromTurn(
      turn: view.turn,
      playerId: view.forPlayerId,
      baseSeed: 23,
    ),
  );
}

GameView _view({
  List<GameUnit> units = const [],
  GameRuntimeState runtimeState = GameRuntimeState.empty,
}) {
  return GameView.fromPersistentState(
    PersistentGameState(units: units, runtimeState: runtimeState),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: _mapData,
    ruleset: GameRuleset.defaults,
    ignoreFogOfWar: true,
    ignoreDynamicFogOfWar: true,
  );
}

GameUnit _unit(
  String id, {
  GameUnitType type = GameUnitType.warrior,
  int col = 0,
  int row = 1,
}) {
  return GameUnit.produced(
    id: id,
    ownerPlayerId: 'player_1',
    type: type,
    col: col,
    row: row,
  );
}

final _mapData = MapData(
  cols: 5,
  rows: 3,
  objectives: const [
    MapObjectiveDefinition(
      id: 'pass_1',
      type: MapObjectiveType.strategicPass,
      hex: CityHex(col: 3, row: 1),
      requiredHoldTurns: 2,
      victoryPoints: 3,
      goldPerTurn: 2,
    ),
  ],
  tiles: [
    for (var row = 0; row < 3; row++)
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
