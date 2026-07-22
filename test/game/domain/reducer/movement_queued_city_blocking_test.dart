import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/movement/movement_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MovementReducer queued city blocking', () {
    test('queued path never enters a foreign city center', () {
      final lineMap = _map(3, 1);
      final commander = _commander(
        movementPoints: 0,
      ).copyWithQueuedPath(_queuedLinePath(targetCol: 2));
      const city = GameCity(
        id: 'foreign_city',
        ownerPlayerId: 'player_2',
        name: 'Foreign city',
        center: CityHex(col: 1, row: 0),
      );
      final state = GameState(
        units: [commander],
        cities: const [city],
        activePlayerId: 'player_1',
      );

      final result = MovementReducer.resetUnitMovementForNewTurn(
        state,
        lineMap,
        playerId: 'player_1',
      );
      final stopped = result.state.units.single;

      expect((stopped.col, stopped.row), (0, 0));
      expect(stopped.queuedPath, isNull);
      expect(result.uiEffects.whereType<AnimateUnitMoveEffect>(), isEmpty);
    });

    test('queued path stops before a hidden foreign city', () {
      final lineMap = _map(3, 1);
      final commander = _commander(
        movementPoints: 0,
      ).copyWithQueuedPath(_queuedLinePath(targetCol: 2));
      const city = GameCity(
        id: 'hidden_foreign_city',
        ownerPlayerId: 'player_2',
        name: 'Hidden foreign city',
        center: CityHex(col: 1, row: 0),
      );
      final state = GameState(
        units: [commander],
        cities: const [city],
        activePlayerId: 'player_1',
        fogOfWar: _fog(visible: {const HexCoordinate(col: 0, row: 0)}),
      );

      final result = MovementReducer.resetUnitMovementForNewTurn(
        state,
        lineMap,
        playerId: 'player_1',
      );
      final stopped = result.state.units.single;

      expect((stopped.col, stopped.row), (0, 0));
      expect(stopped.queuedPath?.targetCol, 2);
      expect(result.uiEffects.whereType<AnimateUnitMoveEffect>(), isEmpty);
    });
  });
}

MapData _map(int cols, int rows) => MapData(
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

GameUnit _commander({int? movementPoints}) => GameUnit.startingCommander(
  ownerPlayerId: 'player_1',
).copyWith(movementPoints: movementPoints);

QueuedMovePath _queuedLinePath({required int targetCol}) {
  return QueuedMovePath(
    targetCol: targetCol,
    targetRow: 0,
    steps: [
      for (var col = 0; col <= targetCol; col++)
        UnitMovementStep(
          col: col,
          row: 0,
          enterCost: col == 0 ? 0 : 1,
          cumulativeCost: col,
        ),
    ],
  );
}

FogOfWarState _fog({Set<HexCoordinate> visible = const {}}) {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(playerId: 'player_1', visibleHexes: visible),
    },
  );
}
