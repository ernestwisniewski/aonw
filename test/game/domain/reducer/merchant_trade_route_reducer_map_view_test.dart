import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/diplomacy/merchant_trade_route_reducer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts and assigns a trade route through a canonical map view', () {
    final merchant = _merchant(col: 0);
    final origin = _city('origin', 0);
    final destination = _city('destination', 3);
    final state = GameState(
      activePlayerId: 'player_1',
      units: [merchant],
      cities: [origin, destination],
      interaction: GameInteractionState(
        selection: GameSelection.unit(merchant),
      ),
    );
    final MapTraversalView mapView = WorldMapReadView(_worldMap());

    final started = MerchantTradeRouteReducer.startSelection(
      state,
      const StartMerchantTradeRouteSelectionCommand('merchant_1'),
      mapView,
    );
    final assigned = MerchantTradeRouteReducer.assignRoute(
      started.state,
      const AssignMerchantTradeRouteCommand('merchant_1', 'destination'),
      mapView,
    );

    expect(
      started.state.pendingAction,
      const PendingMerchantTradeRouteSelection(
        ownerPlayerId: 'player_1',
        unitId: 'merchant_1',
      ),
    );
    expect(started.state.selection?.tile?.resources, [ResourceType.wheat]);
    final updated = assigned.state.unitById('merchant_1')!;
    final route = updated.merchantTradeRoute!;
    expect(assigned.state.pendingAction, isNull);
    expect(updated.queuedPath, isNull);
    expect(route.originCityId, 'origin');
    expect(route.destinationCityId, 'destination');
    expect(route.steps.map((step) => (step.col, step.row)), [
      (0, 0),
      (1, 0),
      (2, 0),
      (3, 0),
    ]);
    expect(assigned.state.selection?.unit, same(updated));
    expect(assigned.state.selection?.tile?.resources, [ResourceType.wheat]);
    expect(mapView.tileAt(0, 0)?.resources, [
      ResourceType.oil,
      ResourceType.wheat,
    ]);
  });

  test('starts and queues travel into an occupied city through a map view', () {
    final merchant = _merchant(col: 1);
    final destination = _city('destination', 3);
    final guard = GameUnit.produced(
      id: 'guard_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      col: 3,
      row: 0,
    );
    final state = GameState(
      activePlayerId: 'player_1',
      units: [merchant, guard],
      cities: [destination],
      interaction: GameInteractionState(
        selection: GameSelection.unit(merchant),
      ),
    );
    final MapTraversalView mapView = WorldMapReadView(_worldMap());

    final started = MerchantTradeRouteReducer.startMoveToCitySelection(
      state,
      const StartMerchantMoveToCitySelectionCommand('merchant_1'),
      mapView,
    );
    final moved = MerchantTradeRouteReducer.moveToCity(
      started.state,
      const MoveMerchantToCityCommand('merchant_1', 'destination'),
      mapView,
    );

    expect(
      started.state.pendingAction,
      const PendingMerchantMoveToCitySelection(
        ownerPlayerId: 'player_1',
        unitId: 'merchant_1',
      ),
    );
    expect(started.state.selection?.tile?.resources, [ResourceType.wheat]);
    final updated = moved.state.unitById('merchant_1')!;
    expect(moved.state.pendingAction, isNull);
    expect(updated.merchantTradeRoute, isNull);
    expect(updated.queuedPath?.targetCol, 3);
    expect(updated.queuedPath?.targetRow, 0);
    expect(updated.queuedPath?.steps.map((step) => (step.col, step.row)), [
      (1, 0),
      (2, 0),
      (3, 0),
    ]);
    expect(moved.state.selection?.unit, same(updated));
    expect(moved.state.selection?.tile?.resources, [ResourceType.wheat]);
    expect(mapView.tileAt(1, 0)?.resources, [
      ResourceType.oil,
      ResourceType.wheat,
    ]);
  });
}

GameUnit _merchant({required int col}) {
  return GameUnit.produced(
    id: 'merchant_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.merchant,
    col: col,
    row: 0,
  );
}

GameCity _city(String id, int col) {
  return GameCity(
    id: id,
    ownerPlayerId: 'player_1',
    name: id,
    center: CityHex(col: col, row: 0),
    controlledHexes: [CityHex(col: col, row: 0)],
  );
}

WorldMap _worldMap() {
  return WorldMap(
    cols: 4,
    rows: 1,
    tiles: [
      for (var col = 0; col < 4; col += 1)
        WorldTile(
          coordinate: HexCoord(col: col, row: 0),
          terrains: const [TerrainType.plains],
          resources: col <= 1
              ? const [ResourceType.oil, ResourceType.wheat]
              : const [],
          height: 0,
        ),
    ],
  );
}
