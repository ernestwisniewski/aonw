import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MerchantTradeRouteReducer', () {
    late MapData mapData;
    late GameStateReducer reducer;

    setUp(() {
      mapData = _map(4, 1);
      reducer = GameStateReducer(mapData: mapData);
    });

    test('starts merchant move-to-city selection from outside a city', () {
      final merchant = _merchant(col: 1);
      final city = _city(id: 'city_1', col: 3);
      final state = GameState(
        units: [merchant],
        cities: [city],
        activePlayerId: 'player_1',
        selection: GameSelection.unit(merchant),
      );

      final result = reducer.reduce(
        state,
        StartMerchantMoveToCitySelectionCommand(merchant.id),
      );

      expect(
        result.state.pendingAction,
        PendingMerchantMoveToCitySelection(
          ownerPlayerId: merchant.ownerPlayerId,
          unitId: merchant.id,
        ),
      );
    });

    test('queues merchant travel into occupied owned city center', () {
      final merchant = _merchant(col: 1);
      final guard = _warrior(id: 'guard_1', col: 3);
      final city = _city(id: 'city_1', col: 3);
      final state = GameState(
        units: [merchant, guard],
        cities: [city],
        activePlayerId: 'player_1',
        selection: GameSelection.unit(merchant),
        pendingAction: PendingMerchantMoveToCitySelection(
          ownerPlayerId: merchant.ownerPlayerId,
          unitId: merchant.id,
        ),
      );

      final result = reducer.reduce(
        state,
        MoveMerchantToCityCommand(merchant.id, city.id),
      );
      final updated = result.state.units.firstWhere((u) => u.id == merchant.id);

      expect(result.state.pendingAction, isNull);
      expect(updated.merchantTradeRoute, isNull);
      expect(updated.queuedPath?.targetCol, city.center.col);
      expect(updated.queuedPath?.targetRow, city.center.row);
      expect(updated.queuedPath?.steps.last.col, city.center.col);
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

GameUnit _merchant({required int col}) {
  return GameUnit(
    id: 'merchant_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.merchant,
    name: GameUnitType.merchant.defaultNameToken,
    col: col,
    row: 0,
  );
}

GameUnit _warrior({required String id, required int col}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    name: GameUnitType.warrior.defaultNameToken,
    col: col,
    row: 0,
  );
}

GameCity _city({required String id, required int col}) {
  return GameCity(
    id: id,
    ownerPlayerId: 'player_1',
    name: id,
    center: CityHex(col: col, row: 0),
    controlledHexes: [CityHex(col: col, row: 0)],
  );
}
